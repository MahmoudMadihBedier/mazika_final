import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'listening_history_model.g.dart';

enum ActivityType { walking, running, driving, relaxing, working, unknown }
enum MoodType { energetic, chill, focus, happy, melancholic }

@HiveType(typeId: 1)
class ListeningHistoryModel extends HiveObject with EquatableMixin {
  @HiveField(0) final String trackId;
  @HiveField(1) final DateTime playedAt;
  @HiveField(2) final String activityType;
  @HiveField(3) final String moodType;
  @HiveField(4) final int listenedMs;
  @HiveField(5) final int trackDurationMs;
  @HiveField(6) final bool skipped;
  @HiveField(7) final double gpsSpeed;
  @HiveField(8) final int hourOfDay;
  @HiveField(9) final int dayOfWeek;

  ListeningHistoryModel({
    required this.trackId,
    required this.playedAt,
    required this.activityType,
    required this.moodType,
    required this.listenedMs,
    required this.trackDurationMs,
    required this.skipped,
    required this.gpsSpeed,
    required this.hourOfDay,
    required this.dayOfWeek,
  });

  double get completionRatio =>
      trackDurationMs > 0 ? listenedMs / trackDurationMs : 0;

  bool get wasEnjoyed => !skipped && completionRatio > 0.7;

  @override
  List<Object?> get props => [trackId, playedAt];
}
