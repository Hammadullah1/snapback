import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';
import '../models/task_model.dart';
import '../models/session_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const _uuid = Uuid();

  late Box<TaskModel> _tasks;
  late Box<SessionModel> _sessions;
  late Box _prefs;

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SessionModelAdapter());

    _tasks = await Hive.openBox<TaskModel>(AppConstants.tasksBox);
    _sessions = await Hive.openBox<SessionModel>(AppConstants.sessionsBox);
    _prefs = await Hive.openBox(AppConstants.prefsBox);
    _ready = true;
  }

  // ---------- date helpers ----------
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _today() => dateOnly(DateTime.now());

  // ---------- tasks ----------
  Future<TaskModel> saveTask({
    required String title,
    String? deadlineText,
    String priority = 'medium',
    String category = 'Personal',
    DateTime? forDate,
    bool isDemo = false,
  }) async {
    final t = TaskModel(
      id: _uuid.v4(),
      title: title.trim(),
      deadlineText: deadlineText,
      priority: priority,
      category: category,
      completed: false,
      createdAt: DateTime.now(),
      forDate: dateOnly(forDate ?? DateTime.now()),
      isDemo: isDemo,
    );
    await _tasks.put(t.id, t);
    return t;
  }

  Future<void> saveTaskObject(TaskModel t) => _tasks.put(t.id, t);

  List<TaskModel> allTasks() => _tasks.values.toList();

  List<TaskModel> getTasksForDate(DateTime date) {
    final d = dateOnly(date);
    return _tasks.values.where((t) => t.forDate == d).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<TaskModel> getPendingTasksToday() =>
      getTasksForDate(_today()).where((t) => !t.completed).toList();

  int getCompletedCountToday() =>
      getTasksForDate(_today()).where((t) => t.completed).length;

  int getPlannedCountToday() => getTasksForDate(_today()).length;

  Future<void> markComplete(String taskId, {bool complete = true}) async {
    final t = _tasks.get(taskId);
    if (t == null) return;
    t.completed = complete;
    t.completedAt = complete ? DateTime.now() : null;
    await t.save();
  }

  Future<void> deleteTask(String taskId) => _tasks.delete(taskId);

  Future<void> editTask(String taskId, {String? title, String? category, String? priority}) async {
    final t = _tasks.get(taskId);
    if (t == null) return;
    if (title != null) t.title = title;
    if (category != null) t.category = category;
    if (priority != null) t.priority = priority;
    await t.save();
  }

  Future<void> moveTaskToTomorrow(String taskId) async {
    final t = _tasks.get(taskId);
    if (t == null) return;
    t.forDate = dateOnly(DateTime.now().add(const Duration(days: 1)));
    await t.save();
  }

  // ---------- sessions ----------
  Future<SessionModel> saveSession(SessionModel s) async {
    // Merge with a session ending in the same app within the merge window.
    final mergeCutoff = s.startedAt
        .subtract(Duration(seconds: AppConstants.sessionMergeWindowSeconds));
    final candidate = _sessions.values
        .where((x) => x.packageName == s.packageName && x.endedAt.isAfter(mergeCutoff) && x.endedAt.isBefore(s.startedAt))
        .toList()
      ..sort((a, b) => b.endedAt.compareTo(a.endedAt));

    if (candidate.isNotEmpty) {
      final merged = candidate.first;
      merged.endedAt = s.endedAt;
      merged.durationSeconds += s.durationSeconds;
      merged.intervened = merged.intervened || s.intervened;
      merged.snoozeCount += s.snoozeCount;
      await merged.save();
      return merged;
    }

    await _sessions.put(s.id, s);
    return s;
  }

  List<SessionModel> getSessionsForDate(DateTime date) {
    final start = dateOnly(date);
    final end = start.add(const Duration(days: 1));
    return _sessions.values
        .where((s) => s.startedAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
            s.startedAt.isBefore(end))
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  }

  int getTotalScrollMinutesToday() {
    final today = _today();
    final secs = getSessionsForDate(today)
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);
    return (secs / 60).round();
  }

  // ---------- prefs ----------
  T getPref<T>(String key, T defaultValue) {
    final v = _prefs.get(key);
    if (v is T) return v;
    return defaultValue;
  }

  Future<void> setPref(String key, dynamic value) => _prefs.put(key, value);

  int get scrollLimit =>
      getPref<int>(AppConstants.prefScrollLimit, AppConstants.defaultScrollLimitMinutes);

  int get reflectionHour =>
      getPref<int>(AppConstants.prefReflectionHour, AppConstants.defaultReflectionHour);

  bool get onboardingComplete =>
      getPref<bool>(AppConstants.prefOnboardingComplete, false);

  int get streak => getPref<int>(AppConstants.prefStreak, 0);

  DateTime? get streakLastUpdated {
    final v = _prefs.get(AppConstants.prefStreakLastUpdated);
    return v is DateTime ? v : null;
  }

  Future<void> setStreak(int value, DateTime when) async {
    await _prefs.put(AppConstants.prefStreak, value);
    await _prefs.put(AppConstants.prefStreakLastUpdated, dateOnly(when));
  }

  List<String> get monitoredApps {
    final raw = _prefs.get(AppConstants.prefMonitoredApps);
    if (raw is List) return raw.cast<String>();
    return AppConstants.monitoredPackages.toList();
  }

  Future<void> setMonitoredApps(List<String> packages) =>
      _prefs.put(AppConstants.prefMonitoredApps, packages);

  // ---------- streak computation ----------
  /// Runs the streak algorithm as specified in the plan.
  /// Returns the new streak value.
  Future<int> computeAndUpdateStreak() async {
    final today = _today();
    final planned = getPlannedCountToday();
    final completed = getCompletedCountToday();
    final scrollMin = getTotalScrollMinutesToday();
    final limit = scrollLimit;

    if (planned == 0) {
      // Empty day — don't punish.
      return streak;
    }

    final completionRate = completed / planned;
    final scrollOk = scrollMin <= (limit * 2);
    final last = streakLastUpdated;

    int next;
    if (completionRate >= 0.5 && scrollOk) {
      if (last == null) {
        next = 1;
      } else if (last == today.subtract(const Duration(days: 1))) {
        next = streak + 1;
      } else if (last == today) {
        next = streak;
      } else {
        next = 1;
      }
    } else {
      next = 0;
    }

    await setStreak(next, today);
    return next;
  }

  // ---------- demo data ----------
  Future<void> seedDemoData() async {
    final today = _today();
    final demos = [
      TaskModel(
          id: _uuid.v4(),
          title: 'Finish physics homework (Ch. 4)',
          priority: 'high',
          category: 'Study',
          createdAt: DateTime.now(),
          forDate: today,
          isDemo: true,
          completed: true,
          completedAt: DateTime.now()),
      TaskModel(
          id: _uuid.v4(),
          title: 'Go to gym — leg day',
          priority: 'medium',
          category: 'Health',
          createdAt: DateTime.now(),
          forDate: today,
          isDemo: true),
      TaskModel(
          id: _uuid.v4(),
          title: 'Call grandma',
          priority: 'medium',
          category: 'Family',
          createdAt: DateTime.now(),
          forDate: today,
          isDemo: true),
      TaskModel(
          id: _uuid.v4(),
          title: 'Read 20 pages',
          priority: 'low',
          category: 'Personal',
          createdAt: DateTime.now(),
          forDate: today,
          isDemo: true),
      TaskModel(
          id: _uuid.v4(),
          title: 'Pray Asr on time',
          priority: 'high',
          category: 'Personal',
          createdAt: DateTime.now(),
          forDate: today,
          isDemo: true,
          completed: true,
          completedAt: DateTime.now()),
    ];
    for (final t in demos) {
      await _tasks.put(t.id, t);
    }

    final now = DateTime.now();
    final sessions = [
      SessionModel(
        id: _uuid.v4(),
        packageName: 'com.instagram.android',
        appDisplayName: 'Instagram',
        startedAt: now.subtract(const Duration(hours: 4)),
        endedAt: now.subtract(const Duration(hours: 4, minutes: -22)),
        durationSeconds: 22 * 60,
        intervened: true,
        snoozeCount: 1,
        isDemo: true,
      ),
      SessionModel(
        id: _uuid.v4(),
        packageName: 'com.zhiliaoapp.musically',
        appDisplayName: 'TikTok',
        startedAt: now.subtract(const Duration(hours: 2)),
        endedAt: now.subtract(const Duration(hours: 1, minutes: 47)),
        durationSeconds: 13 * 60,
        isDemo: true,
      ),
      SessionModel(
        id: _uuid.v4(),
        packageName: 'com.google.android.youtube',
        appDisplayName: 'YouTube',
        startedAt: now.subtract(const Duration(minutes: 50)),
        endedAt: now.subtract(const Duration(minutes: 32)),
        durationSeconds: 18 * 60,
        intervened: true,
        isDemo: true,
      ),
    ];
    for (final s in sessions) {
      await _sessions.put(s.id, s);
    }

    await setPref(AppConstants.prefDemoMode, true);
  }

  Future<void> clearDemoData() async {
    final demoTaskIds = _tasks.values.where((t) => t.isDemo).map((t) => t.id).toList();
    for (final id in demoTaskIds) {
      await _tasks.delete(id);
    }
    final demoSessionIds =
        _sessions.values.where((s) => s.isDemo).map((s) => s.id).toList();
    for (final id in demoSessionIds) {
      await _sessions.delete(id);
    }
    await setPref(AppConstants.prefDemoMode, false);
  }
}
