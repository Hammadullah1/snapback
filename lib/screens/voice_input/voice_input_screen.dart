import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../agents/task_extractor_agent.dart';
import '../../config/theme.dart';
import '../../models/task_model.dart';
import '../../services/storage_service.dart';
import '../../services/voice_service.dart';
import '../../shared/widgets/outlined_button.dart';
import '../../shared/widgets/primary_button.dart';
import '../../state/tasks_provider.dart';
import 'widgets/manual_add_sheet.dart';
import 'widgets/mic_button.dart';
import 'widgets/quick_chips.dart';
import 'widgets/task_preview_card.dart';

class VoiceInputScreen extends StatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen> {
  final VoiceService _voice = VoiceService();
  final TaskExtractorAgent _extractor = TaskExtractorAgent();
  static const _uuid = Uuid();

  MicState _state = MicState.idle;
  String? _transcript;
  String? _error;
  List<TaskModel> _previews = [];
  String? _recordingPath;
  double _voiceLevel = 0;
  StreamSubscription<double>? _voiceLevelSub;

  @override
  void dispose() {
    _voiceLevelSub?.cancel();
    _voice.dispose();
    super.dispose();
  }

  Future<void> _onMicTap() async {
    if (_state == MicState.idle) {
      await _startRecording();
    } else if (_state == MicState.recording) {
      await _stopAndTranscribe();
    }
  }

  Future<void> _startRecording() async {
    setState(() {
      _error = null;
      _transcript = null;
      _previews = [];
    });
    try {
      await _voice.startRecording();
      await _voiceLevelSub?.cancel();
      _voiceLevelSub = _voice.voiceLevels().listen((level) {
        if (mounted) setState(() => _voiceLevel = level);
      });
      setState(() => _state = MicState.recording);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _stopAndTranscribe() async {
    setState(() => _state = MicState.transcribing);
    await _voiceLevelSub?.cancel();
    _voiceLevelSub = null;
    setState(() => _voiceLevel = 0);
    try {
      _recordingPath = await _voice.stopRecording();
      if (_recordingPath == null) {
        throw VoiceServiceException('No recording produced');
      }
      final text = await _voice.transcribe(_recordingPath!);
      setState(() => _transcript = text);
      final tasks = await _extractor.extract(text);
      setState(() {
        _previews = tasks;
        _state = MicState.idle;
      });
      if (tasks.isEmpty) {
        setState(() => _error =
            "Couldn't pull any tasks out of that. Try again or add manually.");
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _state = MicState.idle;
      });
    }
  }

  Future<void> _saveAll() async {
    if (_previews.isEmpty) return;
    await context.read<TasksProvider>().addMany(_previews);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${_previews.length} task${_previews.length == 1 ? '' : 's'}')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _openManualAdd() async {
    final r = await showModalBottomSheet<ManualAddResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ManualAddSheet(),
    );
    if (r == null) return;
    final t = TaskModel(
      id: _uuid.v4(),
      title: r.title,
      category: r.category,
      priority: r.priority,
      createdAt: DateTime.now(),
      forDate: StorageService.dateOnly(DateTime.now()),
    );
    setState(() => _previews = [..._previews, t]);
  }

  void _addQuickChip(String label) {
    final t = TaskModel(
      id: _uuid.v4(),
      title: label,
      category: _chipCategory(label),
      priority: 'medium',
      createdAt: DateTime.now(),
      forDate: StorageService.dateOnly(DateTime.now()),
    );
    setState(() => _previews = [..._previews, t]);
  }

  String _chipCategory(String label) {
    final l = label.toLowerCase();
    if (l.contains('pray')) return 'Personal';
    if (l.contains('study') || l.contains('homework') || l.contains('quiz')) return 'Study';
    if (l.contains('gym') || l.contains('sleep')) return 'Health';
    if (l.contains('family')) return 'Family';
    return 'Personal';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan your day')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Center(child: MicButton(state: _state, onTap: _onMicTap)),
              const SizedBox(height: AppSpacing.md),
              if (_state == MicState.recording) ...[
                Center(child: _VoiceLevelMeter(level: _voiceLevel)),
                const SizedBox(height: AppSpacing.sm),
              ],
              Center(
                child: Text(
                  _state == MicState.recording
                      ? 'Listening… speak your plan, then tap to stop'
                      : _state == MicState.transcribing
                          ? 'Transcribing…'
                          : kIsWeb
                              ? 'Tap the mic and allow Chrome microphone access'
                              : 'Tap the mic and talk',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_transcript != null) ...[
                Text('What you said',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Text(_transcript!),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(_error!,
                            style:
                                Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_previews.isNotEmpty) ...[
                Text('Tasks to add',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                ..._previews.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: TaskPreviewCard(
                        task: t,
                        onRemove: () => setState(() => _previews =
                            _previews.where((x) => x.id != t.id).toList()),
                      ),
                    )),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(label: 'Save all', onPressed: _saveAll),
                const SizedBox(height: AppSpacing.md),
              ],
              Text('Quick add', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              QuickChips(onTap: _addQuickChip),
              const SizedBox(height: AppSpacing.lg),
              AppOutlinedButton(
                label: 'Type a task instead',
                icon: Icons.edit_outlined,
                onPressed: _openManualAdd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceLevelMeter extends StatelessWidget {
  final double level;
  const _VoiceLevelMeter({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(18, (i) {
        final active = level > (i / 18);
        final height = 8.0 + ((i % 5) * 5);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 5,
          height: active ? height + 10 : height,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : AppColors.divider,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
