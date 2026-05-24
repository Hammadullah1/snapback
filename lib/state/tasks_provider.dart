import 'package:flutter/foundation.dart';

import '../models/task_model.dart';
import '../services/storage_service.dart';

class TasksProvider extends ChangeNotifier {
  final StorageService _storage;
  TasksProvider(this._storage);

  List<TaskModel> get today => _storage.getTasksForDate(DateTime.now());
  List<TaskModel> get pendingToday => _storage.getPendingTasksToday();
  int get completedTodayCount => _storage.getCompletedCountToday();
  int get plannedTodayCount => _storage.getPlannedCountToday();

  Future<TaskModel> add({
    required String title,
    String? deadlineText,
    String priority = 'medium',
    String category = 'Personal',
  }) async {
    final t = await _storage.saveTask(
      title: title,
      deadlineText: deadlineText,
      priority: priority,
      category: category,
    );
    notifyListeners();
    return t;
  }

  Future<void> addMany(List<TaskModel> tasks) async {
    for (final t in tasks) {
      await _storage.saveTaskObject(t);
    }
    notifyListeners();
  }

  Future<void> toggleComplete(String id) async {
    final task = _storage.allTasks().firstWhere((t) => t.id == id, orElse: () => _empty());
    if (task.id.isEmpty) return;
    await _storage.markComplete(id, complete: !task.completed);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _storage.deleteTask(id);
    notifyListeners();
  }

  Future<void> edit(String id, {String? title, String? category, String? priority}) async {
    await _storage.editTask(id, title: title, category: category, priority: priority);
    notifyListeners();
  }

  Future<void> moveToTomorrow(String id) async {
    await _storage.moveTaskToTomorrow(id);
    notifyListeners();
  }

  void refresh() => notifyListeners();

  TaskModel _empty() => TaskModel(
        id: '',
        title: '',
        createdAt: DateTime.now(),
        forDate: DateTime.now(),
      );
}
