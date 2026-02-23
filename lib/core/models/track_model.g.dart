// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'track_model.dart';

class TrackModelAdapter extends TypeAdapter<TrackModel> {
  @override
  final int typeId = 0;

  @override
  TrackModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrackModel(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      albumName: fields[3] as String,
      albumImageUrl: fields[4] as String,
      previewUrl: fields[5] as String,
      spotifyUri: fields[6] as String,
      durationMs: fields[7] as int,
      energy: (fields[8] as num?)?.toDouble() ?? 0.5,
      valence: (fields[9] as num?)?.toDouble() ?? 0.5,
      tempo: (fields[10] as num?)?.toDouble() ?? 120,
      danceability: (fields[11] as num?)?.toDouble() ?? 0.5,
      acousticness: (fields[12] as num?)?.toDouble() ?? 0.5,
      instrumentalness: (fields[13] as num?)?.toDouble() ?? 0.5,
      playCount: fields[14] as int? ?? 0,
      skipCount: fields[15] as int? ?? 0,
      lastPlayed: fields[16] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TrackModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.artist)
      ..writeByte(3)..write(obj.albumName)
      ..writeByte(4)..write(obj.albumImageUrl)
      ..writeByte(5)..write(obj.previewUrl)
      ..writeByte(6)..write(obj.spotifyUri)
      ..writeByte(7)..write(obj.durationMs)
      ..writeByte(8)..write(obj.energy)
      ..writeByte(9)..write(obj.valence)
      ..writeByte(10)..write(obj.tempo)
      ..writeByte(11)..write(obj.danceability)
      ..writeByte(12)..write(obj.acousticness)
      ..writeByte(13)..write(obj.instrumentalness)
      ..writeByte(14)..write(obj.playCount)
      ..writeByte(15)..write(obj.skipCount)
      ..writeByte(16)..write(obj.lastPlayed);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
