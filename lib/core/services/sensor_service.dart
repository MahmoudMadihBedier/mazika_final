import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxdart/rxdart.dart';
import 'package:logger/logger.dart';

import '../models/context_model.dart';
import '../models/listening_history_model.dart' as history;

class SensorService {
  final Logger _logger = Logger();
  StreamSubscription? _accelSub;
  StreamSubscription? _locationSub;
  final _contextController = BehaviorSubject<ContextModel>();
  Stream<ContextModel> get contextStream => _contextController.stream;

  double _accelMagnitude = 9.8; // ~gravity
  double _gpsSpeed = 0;
  history.MoodType? _manualMoodOverride;

  Future<void> start() async {
    await _requestPermissions();
    _startAccelerometer();
    _startLocationUpdates();
    _emitContext();
    Timer.periodic(const Duration(seconds: 30), (_) => _emitContext());
  }

  Future<void> _requestPermissions() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _logger.w('Location not enabled');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  void _startAccelerometer() {
    final samples = <double>[];
    _accelSub =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.normalInterval,
        ).listen((e) {
          final mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
          samples.add(mag);
          if (samples.length > 20) samples.removeAt(0);
          _accelMagnitude = samples.reduce((a, b) => a + b) / samples.length;
        });
  }

  void _startLocationUpdates() {
    _locationSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: 10,
          ),
        ).listen((pos) {
          _gpsSpeed = pos.speed.clamp(0, 50);
          _emitContext();
        }, onError: (e) => _logger.w('GPS: $e'));
  }

  void _emitContext() {
    final now = DateTime.now();
    final activity = _classifyActivity();
    final mood = _manualMoodOverride ?? _inferMood(activity, now.hour);
    _contextController.add(
      ContextModel(
        activity: activity,
        gpsSpeed: _gpsSpeed,
        accelerometerMag: _accelMagnitude,
        hourOfDay: now.hour,
        dayOfWeek: now.weekday,
        isConnectedToWifi: true,
        inferredMood: mood,
      ),
    );
  }

  history.ActivityType _classifyActivity() {
    if (_gpsSpeed > 7) return history.ActivityType.driving;
    if (_gpsSpeed > 2.5 || _accelMagnitude > 14)
      return history.ActivityType.running;
    if (_gpsSpeed > 0.5 || _accelMagnitude > 10.5)
      return history.ActivityType.walking;
    if (_accelMagnitude < 9.9) return history.ActivityType.relaxing;
    return history.ActivityType.working;
  }

  history.MoodType _inferMood(history.ActivityType activity, int hour) {
    final isNight = hour >= 21 || hour < 6;
    final isMorning = hour >= 6 && hour < 10;
    switch (activity) {
      case history.ActivityType.running:
        return history.MoodType.energetic;
      case history.ActivityType.walking:
        return isMorning ? history.MoodType.energetic : history.MoodType.happy;
      case history.ActivityType.driving:
        return history.MoodType.focus;
      case history.ActivityType.working:
        return history.MoodType.focus;
      case history.ActivityType.relaxing:
        return isNight ? history.MoodType.melancholic : history.MoodType.chill;
      default:
        return history.MoodType.chill;
    }
  }

  void overrideMood(history.MoodType mood) {
    _manualMoodOverride = mood;
    _emitContext();
  }

  void clearMoodOverride() {
    _manualMoodOverride = null;
    _emitContext();
  }

  ContextModel? get currentContext => _contextController.valueOrNull;

  void dispose() {
    _accelSub?.cancel();
    _locationSub?.cancel();
    _contextController.close();
  }
}
