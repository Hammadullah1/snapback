import 'package:flutter_application_1/config/constants.dart';
import 'package:flutter_application_1/models/session_model.dart';
import 'package:flutter_application_1/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Lightweight reimplementation of StorageService streak math, run against
/// the same Hive data shape, but without pulling in the Flutter binding.
/// Mirrors `StorageService.computeAndUpdateStreak()`.
Future<int> computeStreak({
  required Box<TaskModel> tasks,
  required Box<SessionModel> sessions,
  required Box prefs,
  required int scrollLimit,
  required DateTime now,
}) async {
  final today = _dateOnly(now);
  final todayTasks =
      tasks.values.where((t) => t.forDate == today).toList();
  final planned = todayTasks.length;
  final completed = todayTasks.where((t) => t.completed).length;

  final scrollSec = sessions.values
      .where((s) =>
          !s.startedAt.isBefore(today) &&
          s.startedAt.isBefore(today.add(const Duration(days: 1))))
      .fold<int>(0, (sum, s) => sum + s.durationSeconds);
  final scrollMin = (scrollSec / 60).round();

  final lastRaw = prefs.get(AppConstants.prefStreakLastUpdated);
  final last = lastRaw is DateTime ? lastRaw : null;
  final current = (prefs.get(AppConstants.prefStreak) as int?) ?? 0;

  if (planned == 0) return current;

  final completionRate = completed / planned;
  final scrollOk = scrollMin <= (scrollLimit * 2);

  int next;
  if (completionRate >= 0.5 && scrollOk) {
    if (last == null) {
      next = 1;
    } else if (last == today.subtract(const Duration(days: 1))) {
      next = current + 1;
    } else if (last == today) {
      next = current;
    } else {
      next = 1;
    }
  } else {
    next = 0;
  }

  await prefs.put(AppConstants.prefStreak, next);
  await prefs.put(AppConstants.prefStreakLastUpdated, today);
  return next;
}

void main() {
  late Box<TaskModel> tasks;
  late Box<SessionModel> sessions;
  late Box prefs;

  setUpAll(() async {
    Hive.init('.test_hive_streak');
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskModelAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SessionModelAdapter());
    }
  });

  setUp(() async {
    tasks = await Hive.openBox<TaskModel>('streak_tasks_${DateTime.now().microsecondsSinceEpoch}');
    sessions = await Hive.openBox<SessionModel>(
        'streak_sessions_${DateTime.now().microsecondsSinceEpoch}');
    prefs = await Hive.openBox('streak_prefs_${DateTime.now().microsecondsSinceEpoch}');
  });

  tearDown(() async {
    await tasks.clear();
    await sessions.clear();
    await prefs.clear();
    await tasks.close();
    await sessions.close();
    await prefs.close();
  });

  TaskModel makeTask({required bool done, required DateTime forDate}) {
    return TaskModel(
      id: 't${DateTime.now().microsecondsSinceEpoch}',
      title: 'Task',
      createdAt: forDate,
      forDate: forDate,
      completed: done,
      completedAt: done ? forDate : null,
    );
  }

  test('empty day preserves existing streak', () async {
    await prefs.put(AppConstants.prefStreak, 7);
    final result = await computeStreak(
      tasks: tasks,
      sessions: sessions,
      prefs: prefs,
      scrollLimit: 15,
      now: DateTime(2026, 5, 14),
    );
    expect(result, 7);
  });

  test('3/4 completed and scroll within limit increments from 0 to 1', () async {
    final today = DateTime(2026, 5, 14);
    final day = _dateOnly(today);
    for (var i = 0; i < 4; i++) {
      final t = makeTask(done: i < 3, forDate: day);
      await tasks.put('${i}_${t.id}', t);
    }
    await sessions.put('s1', SessionModel(
      id: 's1',
      packageName: 'com.instagram.android',
      appDisplayName: 'Instagram',
      startedAt: day.add(const Duration(hours: 10)),
      endedAt: day.add(const Duration(hours: 10, minutes: 20)),
      durationSeconds: 20 * 60,
    ));
    final result = await computeStreak(
      tasks: tasks, sessions: sessions, prefs: prefs,
      scrollLimit: 15, now: today,
    );
    expect(result, 1);
  });

  test('continues from yesterday when conditions met', () async {
    final today = DateTime(2026, 5, 14);
    final day = _dateOnly(today);
    await prefs.put(AppConstants.prefStreak, 5);
    await prefs.put(AppConstants.prefStreakLastUpdated,
        day.subtract(const Duration(days: 1)));
    for (var i = 0; i < 2; i++) {
      final t = makeTask(done: true, forDate: day);
      await tasks.put('${i}_${t.id}', t);
    }
    final result = await computeStreak(
      tasks: tasks, sessions: sessions, prefs: prefs,
      scrollLimit: 15, now: today,
    );
    expect(result, 6);
  });

  test('low completion rate resets streak', () async {
    final today = DateTime(2026, 5, 14);
    final day = _dateOnly(today);
    await prefs.put(AppConstants.prefStreak, 10);
    for (var i = 0; i < 4; i++) {
      final t = makeTask(done: i < 1, forDate: day);
      await tasks.put('${i}_${t.id}', t);
    }
    final result = await computeStreak(
      tasks: tasks, sessions: sessions, prefs: prefs,
      scrollLimit: 15, now: today,
    );
    expect(result, 0);
  });

  test('excessive scroll (>2x limit) resets streak', () async {
    final today = DateTime(2026, 5, 14);
    final day = _dateOnly(today);
    await prefs.put(AppConstants.prefStreak, 4);
    for (var i = 0; i < 4; i++) {
      final t = makeTask(done: i < 3, forDate: day);
      await tasks.put('${i}_${t.id}', t);
    }
    await sessions.put('s1', SessionModel(
      id: 's1',
      packageName: 'com.instagram.android',
      appDisplayName: 'Instagram',
      startedAt: day.add(const Duration(hours: 10)),
      endedAt: day.add(const Duration(hours: 11, minutes: 30)),
      durationSeconds: 90 * 60, // 90min > 2 × 15min limit
    ));
    final result = await computeStreak(
      tasks: tasks, sessions: sessions, prefs: prefs,
      scrollLimit: 15, now: today,
    );
    expect(result, 0);
  });

  test('idempotent when called twice same day', () async {
    final today = DateTime(2026, 5, 14);
    final day = _dateOnly(today);
    for (var i = 0; i < 2; i++) {
      final t = makeTask(done: true, forDate: day);
      await tasks.put('${i}_${t.id}', t);
    }
    final first = await computeStreak(
      tasks: tasks, sessions: sessions, prefs: prefs,
      scrollLimit: 15, now: today,
    );
    final second = await computeStreak(
      tasks: tasks, sessions: sessions, prefs: prefs,
      scrollLimit: 15, now: today,
    );
    expect(first, 1);
    expect(second, 1);
  });
}
