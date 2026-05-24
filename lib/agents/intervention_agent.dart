import 'dart:math';

import '../config/constants.dart';
import '../config/env_config.dart';
import '../models/task_model.dart';
import 'openai_client.dart';

class InterventionAgent {
  static const String _systemPrompt = '''
You are a gentle, direct friend who helps Pakistani teenagers step away from doom-scrolling. You speak in plain English with occasional Urdu/Roman Urdu warmth when natural (e.g., "yaar", "bhai/behen"), but never forced.

Write EXACTLY 3 short sentences. Total under 280 characters. No emojis. No exclamation marks.

Sentence 1: Acknowledge what's happening (they've been on \$app for \$mins minutes) without shame.
Sentence 2: Reference ONE specific pending task from their planner by name. Make it feel personal — connect it to their day.
Sentence 3: A small, gentle nudge to close the app.

NEVER moralize. NEVER mention "doom-scroll", "addiction", "wasted time", or anything preachy. Sound like a friend, not a parent.

Return only the message text. No quotes, no labels.
''';

  Future<String> generateMessage({
    required String appName,
    required int minutesScrolled,
    required List<TaskModel> pendingTasks,
    required int completedCount,
    required int totalScrollToday,
    required int hourOfDay,
    required int streak,
    required int snoozeCount,
  }) async {
    final top = pendingTasks.take(3).map((t) => t.title).toList();
    final taskLine = top.isEmpty
        ? 'No specific task — keep it general but warm.'
        : top.join('; ');

    final userContext = '''
App: $appName
Minutes scrolled this session: $minutesScrolled
Pending tasks today (top 3 by priority): $taskLine
Completed today: $completedCount
Total scroll today (min): $totalScrollToday
Hour of day (0-23): $hourOfDay
Streak: $streak day(s)
Previous snoozes this session: $snoozeCount
''';

    try {
      final resp = await OpenAIClient().dio.post(
        EnvConfig.chatUrl,
        data: {
          'model': AppConstants.chatModel,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': userContext},
          ],
          'temperature': 0.7,
          'max_tokens': 200,
        },
      );
      final text =
          (resp.data['choices']?[0]?['message']?['content'] as String?)?.trim();
      if (text == null || text.isEmpty) return _fallback();
      return text;
    } catch (_) {
      return _fallback();
    }
  }

  String _fallback() {
    final pool = AppConstants.fallbackInterventions;
    return pool[Random().nextInt(pool.length)];
  }
}
