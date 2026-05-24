import 'dart:convert';

import '../config/constants.dart';
import '../config/env_config.dart';
import '../models/session_model.dart';
import '../models/task_model.dart';
import 'openai_client.dart';

class ReflectionResult {
  final String moodEmoji;
  final List<String> reflection;
  final String tomorrowChallenge;
  final String streakMessage;

  ReflectionResult({
    required this.moodEmoji,
    required this.reflection,
    required this.tomorrowChallenge,
    required this.streakMessage,
  });

  factory ReflectionResult.fallback(int completed, int planned, int streak) {
    final rate = planned == 0 ? 0 : completed / planned;
    final emoji = rate >= 0.8
        ? '🌱'
        : rate >= 0.5
            ? '🌤️'
            : '🌧️';
    final reflection = [
      'You planned $planned things and finished $completed today.',
      'Some days are wins, some are rest. Both count.',
      'Tomorrow is a fresh page — what matters most?',
    ];
    final streakMsg = streak > 0
        ? '$streak day${streak == 1 ? '' : 's'} of showing up. Keep going.'
        : 'Tomorrow starts a new streak.';
    return ReflectionResult(
      moodEmoji: emoji,
      reflection: reflection,
      tomorrowChallenge: 'Pick one small thing — and do it before noon.',
      streakMessage: streakMsg,
    );
  }
}

class ReflectionAgent {
  static const String _systemPrompt = '''
You write a brief, honest daily reflection for a teenager using a planner+focus app. Tone: warm, plain, no fake positivity. No emojis except the single mood emoji you pick.

Given the day's data (tasks planned, tasks completed, scroll sessions), return STRICT JSON:
{
  "mood_emoji": "one emoji that captures the day",
  "reflection": ["sentence 1", "sentence 2", "sentence 3"],
  "tomorrow_challenge": "one specific, small, doable thing for tomorrow",
  "streak_message": "one sentence about their streak status"
}

Rules:
- Reflection sentences are short (under 90 chars each).
- If completion rate < 50%, be kind but honest — name what happened without shaming.
- If scroll time > 2x limit, gently note it. Never lecture.
- Tomorrow challenge should reference one unfinished task if any.
Return only the JSON.
''';

  Future<ReflectionResult> generate({
    required List<TaskModel> todayTasks,
    required List<SessionModel> todaySessions,
    required int scrollLimit,
    required int streak,
  }) async {
    final completed = todayTasks.where((t) => t.completed).toList();
    final pending = todayTasks.where((t) => !t.completed).toList();
    final totalScrollMin =
        todaySessions.fold<int>(0, (s, x) => s + x.durationSeconds) ~/ 60;

    final context = '''
Tasks planned: ${todayTasks.length}
Tasks completed: ${completed.length}
Completed titles: ${completed.map((t) => t.title).take(5).join(' | ')}
Pending titles: ${pending.map((t) => t.title).take(5).join(' | ')}
Total scroll today (min): $totalScrollMin
Scroll limit (min): $scrollLimit
Current streak (days): $streak
''';

    try {
      final resp = await OpenAIClient().dio.post(
        EnvConfig.chatUrl,
        data: {
          'model': AppConstants.chatModel,
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': context},
          ],
          'temperature': 0.6,
        },
      );
      final content =
          resp.data['choices']?[0]?['message']?['content'] as String?;
      if (content == null) {
        return ReflectionResult.fallback(completed.length, todayTasks.length, streak);
      }
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      final reflectionList = (decoded['reflection'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];
      return ReflectionResult(
        moodEmoji: (decoded['mood_emoji'] as String?) ?? '🌤️',
        reflection: reflectionList.isEmpty
            ? ReflectionResult.fallback(
                    completed.length, todayTasks.length, streak)
                .reflection
            : reflectionList,
        tomorrowChallenge: (decoded['tomorrow_challenge'] as String?) ??
            'Pick one small thing and do it first thing.',
        streakMessage: (decoded['streak_message'] as String?) ??
            (streak > 0
                ? '$streak day streak — nice.'
                : 'Tomorrow can start a new streak.'),
      );
    } catch (_) {
      return ReflectionResult.fallback(completed.length, todayTasks.length, streak);
    }
  }
}
