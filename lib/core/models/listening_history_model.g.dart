// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'listening_history_model.dart';

class ListeningHistoryModelAdapter extends TypeAdapter<ListeningHistoryModel> {
  @override
  final int typeId = 1;

  @override
  ListeningHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ListeningHistoryModel(
      trackId: fields[0] as String,
      playedAt: fields[1] as DateTime,
      activityType: fields[2] as String,
      moodType: fields[3] as String,
      listenedMs: fields[4] as int,
      trackDurationMs: fields[5] as int,
      skipped: fields[6] as bool,
      gpsSpeed: (fields[7] as num).toDouble(),
      hourOfDay: fields[8] as int,
      dayOfWeek: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ListeningHistoryModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)..write(obj.trackId)
      ..writeByte(1)..write(obj.playedAt)
      ..writeByte(2)..write(obj.activityType)
      ..writeByte(3)..write(obj.moodType)
      ..writeByte(4)..write(obj.listenedMs)
      ..writeByte(5)..write(obj.trackDurationMs)
      ..writeByte(6)..write(obj.skipped)
      ..writeByte(7)..write(obj.gpsSpeed)
      ..writeByte(8)..write(obj.hourOfDay)
      ..writeByte(9)..write(obj.dayOfWeek);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListeningHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
