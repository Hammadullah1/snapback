import 'package:flutter_application_1/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    Hive.init('.test_hive');
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskModelAdapter());
  });

  test('TaskModel round-trips through Hive', () async {
    final box = await Hive.openBox<TaskModel>('test_tasks');
    final now = DateTime.now();
    final t = TaskModel(
      id: 'abc',
      title: 'Test task',
      priority: 'high',
      category: 'Study',
      createdAt: now,
      forDate: DateTime(now.year, now.month, now.day),
    );
    await box.put(t.id, t);
    final back = box.get('abc');
    expect(back, isNotNull);
    expect(back!.title, 'Test task');
    expect(back.priority, 'high');
    expect(back.category, 'Study');
    expect(back.completed, false);
    await box.clear();
    await box.close();
  });
}
