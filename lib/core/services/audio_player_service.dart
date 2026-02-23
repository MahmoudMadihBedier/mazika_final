import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';

import '../models/track_model.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final Logger _logger = Logger();
  TrackModel? _currentTrack;
  DateTime? _playStartTime;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  TrackModel? get currentTrack => _currentTrack;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  Future<void> playPreview(TrackModel track) async {
    if (track.previewUrl.isEmpty) {
      _logger.w('No preview URL for "${track.title}"');
      return;
    }
    try {
      _currentTrack = track;
      _playStartTime = DateTime.now();
      await _player.setUrl(track.previewUrl);
      await _player.play();
      _logger.i('Playing: "${track.title}"');
    } catch (e) {
      _logger.e('Playback error: $e');
    }
  }

  Future<void> pause() async => _player.pause();
  Future<void> resume() async => _player.play();
  Future<void> stop() async => _player.stop();
  Future<void> seek(Duration position) async => _player.seek(position);
  Future<void> setVolume(double v) async => _player.setVolume(v.clamp(0, 1));

  int getListenedMs() =>
      _playStartTime != null
          ? DateTime.now().difference(_playStartTime!).inMilliseconds
          : 0;

  void dispose() => _player.dispose();
}
