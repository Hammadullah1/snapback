// GENERATED CODE - hand-written to avoid build_runner step.

part of 'session_model.dart';

class SessionModelAdapter extends TypeAdapter<SessionModel> {
  @override
  final int typeId = 1;

  @override
  SessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionModel(
      id: fields[0] as String,
      packageName: fields[1] as String,
      appDisplayName: fields[2] as String,
      startedAt: fields[3] as DateTime,
      endedAt: fields[4] as DateTime,
      durationSeconds: fields[5] as int,
      intervened: fields[6] as bool? ?? false,
      snoozeCount: fields[7] as int? ?? 0,
      isDemo: fields[8] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, SessionModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.packageName)
      ..writeByte(2)
      ..write(obj.appDisplayName)
      ..writeByte(3)
      ..write(obj.startedAt)
      ..writeByte(4)
      ..write(obj.endedAt)
      ..writeByte(5)
      ..write(obj.durationSeconds)
      ..writeByte(6)
      ..write(obj.intervened)
      ..writeByte(7)
      ..write(obj.snoozeCount)
      ..writeByte(8)
      ..write(obj.isDemo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
