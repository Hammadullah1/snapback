import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? deadlineText;

  @HiveField(3)
  String priority; // low | medium | high

  @HiveField(4)
  String category; // Study | Health | Family | Personal | Work | Other

  @HiveField(5)
  bool completed;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime? completedAt;

  @HiveField(8)
  DateTime forDate; // the day this task belongs to (date-only, midnight local)

  @HiveField(9)
  bool isDemo;

  TaskModel({
    required this.id,
    required this.title,
    this.deadlineText,
    this.priority = 'medium',
    this.category = 'Personal',
    this.completed = false,
    required this.createdAt,
    this.completedAt,
    required this.forDate,
    this.isDemo = false,
  });
}
