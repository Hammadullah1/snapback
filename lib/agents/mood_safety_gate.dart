import 'dart:convert';

import '../config/constants.dart';
import '../config/env_config.dart';
import 'openai_client.dart';

class MoodClassification {
  final bool isDistress;
  final String severity; // low | medium | high
  final String response;

  MoodClassification({
    required this.isDistress,
    required this.severity,
    required this.response,
  });

  factory MoodClassification.safe() => MoodClassification(
        isDistress: false,
        severity: 'low',
        response: '',
      );

  Map<String, dynamic> toMap() => {
        'is_distress': isDistress,
        'severity': severity,
        'response': response,
        'helpline': AppConstants.umangHelpline,
      };
}

class MoodSafetyGate {
  static const String _systemPrompt = '''
You classify short text typed by a teenager into an intervention overlay. Look ONLY for clear distress signals: explicit self-harm references, suicidal ideation, severe hopelessness, crisis language. Casual venting ("I'm bored", "this is annoying", "I'm tired") is NOT distress.

Return STRICT JSON:
{
  "is_distress": true | false,
  "severity": "low" | "medium" | "high",
  "response": "string — short, warm, non-judgmental. If is_distress=true, gently acknowledge their feeling and mention they're not alone. Do NOT include phone numbers (the app adds those). Max 2 sentences. Empty string if is_distress=false."
}

Be CONSERVATIVE — only flag clear cases. False positives are harmful too.
Return only the JSON. No prose.
''';

  final Map<String, MoodClassification> _cache = {};

  Future<MoodClassification> classify(String text) async {
    final t = text.trim();
    if (t.isEmpty) return MoodClassification.safe();
    if (_cache.containsKey(t)) return _cache[t]!;

    try {
      final resp = await OpenAIClient().dio.post(
        EnvConfig.chatUrl,
        data: {
          'model': AppConstants.chatModel,
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': t},
          ],
          'temperature': 0.0,
        },
      );

      final content =
          resp.data['choices']?[0]?['message']?['content'] as String?;
      if (content == null) return MoodClassification.safe();

      final decoded = jsonDecode(content) as Map<String, dynamic>;
      final result = MoodClassification(
        isDistress: decoded['is_distress'] as bool? ?? false,
        severity: (decoded['severity'] as String?) ?? 'low',
        response: (decoded['response'] as String?) ?? '',
      );
      _cache[t] = result;
      return result;
    } catch (_) {
      // Default to safe on API failure — never block accidentally.
      return MoodClassification.safe();
    }
  }

  void clearCache() => _cache.clear();
}
