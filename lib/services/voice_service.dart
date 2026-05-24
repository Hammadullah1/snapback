import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../agents/openai_client.dart';
import '../config/constants.dart';
import '../config/env_config.dart';

class VoiceServiceException implements Exception {
  final String message;
  VoiceServiceException(this.message);
  @override
  String toString() => 'VoiceServiceException: $message';
}

class VoiceService {
  final AudioRecorder _recorder = AudioRecorder();
  final List<int> _webPcmBytes = [];
  StreamSubscription<Uint8List>? _webStreamSub;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Stream<double> voiceLevels() {
    return _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .map((amp) {
      final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
      return normalized;
    });
  }

  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) {
      throw VoiceServiceException('Microphone permission denied');
    }
    if (kIsWeb) {
      _webPcmBytes.clear();
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );
      _webStreamSub = stream.listen(_webPcmBytes.addAll);
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/snapback_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: path,
    );
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    if (kIsWeb) {
      await _webStreamSub?.cancel();
      _webStreamSub = null;
      return 'web-recording.wav';
    }
    return path;
  }

  Future<bool> get isRecording => _recorder.isRecording();

  Future<void> dispose() async {
    await _webStreamSub?.cancel();
    await _recorder.dispose();
  }

  /// Transcribe a recorded audio file via OpenAI Whisper.
  /// Deletes the temp file afterwards.
  Future<String> transcribe(String path) async {
    if (kIsWeb) {
      if (_webPcmBytes.length < 3200) {
        throw VoiceServiceException('Recording too short');
      }
      final wav = _wavFromPcm16(Uint8List.fromList(_webPcmBytes));
      return _transcribeBytes(wav, 'audio.wav');
    }

    final f = File(path);
    if (!await f.exists()) {
      throw VoiceServiceException('Audio file not found: $path');
    }
    final size = await f.length();
    if (size < 1024) {
      await _safeDelete(f);
      throw VoiceServiceException('Recording too short');
    }

    try {
      final form = FormData.fromMap({
        'model': AppConstants.whisperModel,
        'file': await MultipartFile.fromFile(path, filename: 'audio.m4a'),
        'response_format': 'json',
      });
      final resp = await OpenAIClient().dio.post(
            EnvConfig.whisperUrl,
            data: form,
            options: Options(contentType: 'multipart/form-data'),
          );
      final text = (resp.data is Map ? resp.data['text'] : null) as String?;
      if (text == null || text.trim().isEmpty) {
        throw VoiceServiceException('Empty transcription');
      }
      return text.trim();
    } catch (e) {
      if (e is VoiceServiceException) rethrow;
      throw VoiceServiceException(
          OpenAIClient().mapError(e).toString());
    } finally {
      await _safeDelete(f);
    }
  }

  Future<String> _transcribeBytes(Uint8List bytes, String filename) async {
    try {
      final form = FormData.fromMap({
        'model': AppConstants.whisperModel,
        'file': MultipartFile.fromBytes(bytes, filename: filename),
        'response_format': 'json',
      });
      final resp = await OpenAIClient().dio.post(
            EnvConfig.whisperUrl,
            data: form,
            options: Options(contentType: 'multipart/form-data'),
          );
      final text = (resp.data is Map ? resp.data['text'] : null) as String?;
      if (text == null || text.trim().isEmpty) {
        throw VoiceServiceException('Empty transcription');
      }
      return text.trim();
    } catch (e) {
      if (e is VoiceServiceException) rethrow;
      throw VoiceServiceException(OpenAIClient().mapError(e).toString());
    }
  }

  Uint8List _wavFromPcm16(Uint8List pcm) {
    const sampleRate = 16000;
    const channels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataLength = pcm.length;
    final fileLength = 36 + dataLength;
    final out = BytesBuilder();

    void ascii(String value) => out.add(value.codeUnits);
    void u16(int value) {
      final b = ByteData(2)..setUint16(0, value, Endian.little);
      out.add(b.buffer.asUint8List());
    }

    void u32(int value) {
      final b = ByteData(4)..setUint32(0, value, Endian.little);
      out.add(b.buffer.asUint8List());
    }

    ascii('RIFF');
    u32(fileLength);
    ascii('WAVE');
    ascii('fmt ');
    u32(16);
    u16(1);
    u16(channels);
    u32(sampleRate);
    u32(byteRate);
    u16(blockAlign);
    u16(bitsPerSample);
    ascii('data');
    u32(dataLength);
    out.add(pcm);
    return out.toBytes();
  }

  Future<void> _safeDelete(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
