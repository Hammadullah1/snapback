import 'package:hive/hive.dart';

part 'session_model.g.dart';

@HiveType(typeId: 1)
class SessionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String packageName;

  @HiveField(2)
  String appDisplayName;

  @HiveField(3)
  DateTime startedAt;

  @HiveField(4)
  DateTime endedAt;

  @HiveField(5)
  int durationSeconds;

  @HiveField(6)
  bool intervened;

  @HiveField(7)
  int snoozeCount;

  @HiveField(8)
  bool isDemo;

  SessionModel({
    required this.id,
    required this.packageName,
    required this.appDisplayName,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    this.intervened = false,
    this.snoozeCount = 0,
    this.isDemo = false,
  });

  int get durationMinutes => (durationSeconds / 60).round();
}
