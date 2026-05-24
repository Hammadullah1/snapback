import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../config/constants.dart';
import '../config/env_config.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import 'openai_client.dart';

class TaskExtractorAgent {
  static const _uuid = Uuid();

  static const String _systemPrompt = '''
You extract structured tasks from a teenager's spoken plan. Input may be English, Urdu, or Roman Urdu (e.g. "kal physics ka assignment karna hai").

Return STRICT JSON: an object with a single key "tasks" whose value is an array. Each task has:
  - "task": string — concise imperative phrasing, max 80 chars, no quotes
  - "deadline_text": string or null — only if user explicitly said one (e.g. "by 5pm", "before maghrib", "kal")
  - "priority": "low" | "medium" | "high" — infer from urgency words
  - "category": one of "Study", "Health", "Family", "Personal", "Work", "Other"

Rules:
- Do NOT invent tasks. If input is empty or unclear, return {"tasks": []}.
- Split compound statements into separate tasks (e.g. "gym aur physics" → 2 tasks).
- Convert all task titles to clean English regardless of input language.
- Pray / namaz → category Personal, priority high.
- Gym / exercise / sleep → Health.
- Homework / study / quiz / assignment → Study.
- Family-related (call mom, help dad) → Family.

Return ONLY the JSON object. No prose.
''';

  Future<List<TaskModel>> extract(String transcript) async {
    final cleaned = transcript.trim();
    if (cleaned.isEmpty) return [];

    try {
      final resp = await OpenAIClient().dio.post(
        EnvConfig.chatUrl,
        data: {
          'model': AppConstants.chatModel,
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': cleaned},
          ],
          'temperature': 0.2,
        },
      );

      final content =
          resp.data['choices']?[0]?['message']?['content'] as String?;
      if (content == null) return [];

      final decoded = jsonDecode(content);
      final List rawTasks = (decoded is Map ? decoded['tasks'] : null) as List? ?? [];

      final now = DateTime.now();
      final today = StorageService.dateOnly(now);
      return rawTasks.map<TaskModel>((raw) {
        final m = raw as Map;
        return TaskModel(
          id: _uuid.v4(),
          title: (m['task'] as String? ?? '').trim(),
          deadlineText: m['deadline_text'] as String?,
          priority: _validPriority(m['priority'] as String?),
          category: _validCategory(m['category'] as String?),
          completed: false,
          createdAt: now,
          forDate: today,
        );
      }).where((t) => t.title.isNotEmpty).toList();
    } catch (e) {
      throw OpenAIClient().mapError(e);
    }
  }

  String _validPriority(String? v) {
    const allowed = {'low', 'medium', 'high'};
    return allowed.contains(v) ? v! : 'medium';
  }

  String _validCategory(String? v) {
    const allowed = {'Study', 'Health', 'Family', 'Personal', 'Work', 'Other'};
    return allowed.contains(v) ? v! : 'Personal';
  }
}
