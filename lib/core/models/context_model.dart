import 'package:equatable/equatable.dart';
import 'listening_history_model.dart';

class ContextModel extends Equatable {
  final ActivityType activity;
  final double gpsSpeed;
  final double accelerometerMag;
  final int hourOfDay;
  final int dayOfWeek;
  final bool isConnectedToWifi;
  final MoodType inferredMood;

  const ContextModel({
    required this.activity,
    required this.gpsSpeed,
    required this.accelerometerMag,
    required this.hourOfDay,
    required this.dayOfWeek,
    required this.isConnectedToWifi,
    required this.inferredMood,
  });

  bool get isNight => hourOfDay >= 21 || hourOfDay < 6;
  bool get isMorning => hourOfDay >= 6 && hourOfDay < 12;
  bool get isWeekend => dayOfWeek >= 6;

  List<double> toFeatureVector() => [
    _activityToDouble(),
    (gpsSpeed / 30.0).clamp(0, 1),
    (accelerometerMag / 20.0).clamp(0, 1),
    hourOfDay / 23.0,
    dayOfWeek / 7.0,
    isNight ? 1.0 : 0.0,
    isWeekend ? 1.0 : 0.0,
    _moodToDouble(),
  ];

  double _activityToDouble() {
    switch (activity) {
      case ActivityType.relaxing: return 0.0;
      case ActivityType.working: return 0.2;
      case ActivityType.walking: return 0.5;
      case ActivityType.driving: return 0.6;
      case ActivityType.running: return 1.0;
      default: return 0.3;
    }
  }

  double _moodToDouble() {
    switch (inferredMood) {
      case MoodType.melancholic: return 0.0;
      case MoodType.chill: return 0.25;
      case MoodType.focus: return 0.5;
      case MoodType.happy: return 0.75;
      case MoodType.energetic: return 1.0;
    }
  }

  String get activityLabel {
    switch (activity) {
      case ActivityType.walking: return 'Walking';
      case ActivityType.running: return 'Running';
      case ActivityType.driving: return 'Driving';
      case ActivityType.relaxing: return 'Relaxing';
      case ActivityType.working: return 'Working';
      default: return 'Chilling';
    }
  }

  String get moodLabel {
    switch (inferredMood) {
      case MoodType.energetic: return 'Energetic';
      case MoodType.chill: return 'Chill';
      case MoodType.focus: return 'Focus';
      case MoodType.happy: return 'Happy';
      case MoodType.melancholic: return 'Melancholic';
    }
  }

  ContextModel copyWith({MoodType? inferredMood}) => ContextModel(
    activity: activity,
    gpsSpeed: gpsSpeed,
    accelerometerMag: accelerometerMag,
    hourOfDay: hourOfDay,
    dayOfWeek: dayOfWeek,
    isConnectedToWifi: isConnectedToWifi,
    inferredMood: inferredMood ?? this.inferredMood,
  );

  @override
  List<Object?> get props => [activity, hourOfDay, inferredMood];
}
