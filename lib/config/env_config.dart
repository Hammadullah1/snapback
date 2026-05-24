import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String _require(String key) {
    final v = dotenv.maybeGet(key);
    if (v == null || v.isEmpty) {
      throw StateError(
        'Missing $key in .env. Copy .env.example to .env and fill in real values.',
      );
    }
    return v;
  }

  static String get openAiKey => _require('OPENAI_API_KEY');
  static String get whisperUrl => _require('OPENAI_WHISPER_URL');
  static String get chatUrl => _require('OPENAI_CHAT_URL');
}
