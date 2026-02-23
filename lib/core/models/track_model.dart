import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'track_model.g.dart';

@HiveType(typeId: 0)
class TrackModel extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String artist;
  @HiveField(3)
  final String albumName;
  @HiveField(4)
  final String albumImageUrl;
  @HiveField(5)
  final String previewUrl;
  @HiveField(6)
  final String spotifyUri;
  @HiveField(7)
  final int durationMs;
  @HiveField(8)
  final double energy;
  @HiveField(9)
  final double valence;
  @HiveField(10)
  final double tempo;
  @HiveField(11)
  final double danceability;
  @HiveField(12)
  final double acousticness;
  @HiveField(13)
  final double instrumentalness;
  @HiveField(14)
  final int playCount;
  @HiveField(15)
  final int skipCount;
  @HiveField(16)
  final DateTime? lastPlayed;

  TrackModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumName,
    required this.albumImageUrl,
    required this.previewUrl,
    required this.spotifyUri,
    required this.durationMs,
    this.energy = 0.5,
    this.valence = 0.5,
    this.tempo = 120,
    this.danceability = 0.5,
    this.acousticness = 0.5,
    this.instrumentalness = 0.5,
    this.playCount = 0,
    this.skipCount = 0,
    this.lastPlayed,
  });

  double get skipRate => playCount == 0 ? 0 : skipCount / playCount;

  double get enjoymentScore {
    if (playCount == 0) return 0.5;
    return (1.0 - skipRate) * (1.0 - (1.0 / (playCount + 1)));
  }

  TrackModel copyWith({int? playCount, int? skipCount, DateTime? lastPlayed}) {
    return TrackModel(
      id: id,
      title: title,
      artist: artist,
      albumName: albumName,
      albumImageUrl: albumImageUrl,
      previewUrl: previewUrl,
      spotifyUri: spotifyUri,
      durationMs: durationMs,
      energy: energy,
      valence: valence,
      tempo: tempo,
      danceability: danceability,
      acousticness: acousticness,
      instrumentalness: instrumentalness,
      playCount: playCount ?? this.playCount,
      skipCount: skipCount ?? this.skipCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }

  factory TrackModel.fromSpotifyJson(Map<String, dynamic> json) {
    final track = json['track'] ?? json;
    final album = track['album'] ?? {};
    final artists =
        (track['artists'] as List?)?.map((a) => a['name']).join(', ') ?? '';
    final images = album['images'] as List?;
    final imageUrl = images?.isNotEmpty == true ? images!.first['url'] : '';
    return TrackModel(
      id: track['id'] ?? '',
      title: track['name'] ?? '',
      artist: artists,
      albumName: album['name'] ?? '',
      albumImageUrl: imageUrl,
      previewUrl: track['preview_url'] ?? '',
      spotifyUri: track['uri'] ?? '',
      durationMs: track['duration_ms'] ?? 0,
    );
  }

  TrackModel withAudioFeatures(Map<String, dynamic> features) {
    return TrackModel(
      id: id,
      title: title,
      artist: artist,
      albumName: albumName,
      albumImageUrl: albumImageUrl,
      previewUrl: previewUrl,
      spotifyUri: spotifyUri,
      durationMs: durationMs,
      energy: (features['energy'] ?? energy).toDouble(),
      valence: (features['valence'] ?? valence).toDouble(),
      tempo: (features['tempo'] ?? tempo).toDouble(),
      danceability: (features['danceability'] ?? danceability).toDouble(),
      acousticness: (features['acousticness'] ?? acousticness).toDouble(),
      instrumentalness: (features['instrumentalness'] ?? instrumentalness)
          .toDouble(),
      playCount: playCount,
      skipCount: skipCount,
      lastPlayed: lastPlayed,
    );
  }

  @override
  List<Object?> get props => [id];
}
