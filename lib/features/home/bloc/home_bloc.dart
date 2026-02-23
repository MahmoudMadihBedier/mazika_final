import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/track_model.dart';
import '../../../core/models/context_model.dart';
import '../../../core/services/spotify_service.dart';
import '../../../core/services/sensor_service.dart';
import '../../../core/services/ai_recommendation_service.dart';
import '../../../core/services/audio_player_service.dart';
import 'package:just_audio/just_audio.dart';

// ── Events ───────────────────────────────────────────────────────────────────

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {}
class HomePlayPause extends HomeEvent {}
class HomeSkipTrack extends HomeEvent {}
class HomePreviousTrack extends HomeEvent {}
class HomeContextChanged extends HomeEvent {
  final ContextModel context;
  const HomeContextChanged(this.context);
  @override List<Object?> get props => [context];
}
class HomeTrackSelected extends HomeEvent {
  final TrackModel track;
  const HomeTrackSelected(this.track);
  @override List<Object?> get props => [track];
}
class HomeSyncSpotify extends HomeEvent {}
class _PositionTick extends HomeEvent {
  final Duration position;
  final Duration? duration;
  const _PositionTick(this.position, this.duration);
  @override List<Object?> get props => [position];
}

// ── States ───────────────────────────────────────────────────────────────────

abstract class HomeState extends Equatable {
  const HomeState();
  @override List<Object?> get props => [];
}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}
class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override List<Object?> get props => [message];
}

class HomeReady extends HomeState {
  final TrackModel? currentTrack;
  final ContextModel? context;
  final bool isPlaying;
  final List<TrackModel> queue;
  final bool isSyncing;
  final String? syncStatus;
  final Duration position;
  final Duration? duration;

  const HomeReady({
    this.currentTrack,
    this.context,
    this.isPlaying = false,
    this.queue = const [],
    this.isSyncing = false,
    this.syncStatus,
    this.position = Duration.zero,
    this.duration,
  });

  HomeReady copyWith({
    TrackModel? currentTrack,
    ContextModel? context,
    bool? isPlaying,
    List<TrackModel>? queue,
    bool? isSyncing,
    String? syncStatus,
    Duration? position,
    Duration? duration,
  }) => HomeReady(
    currentTrack: currentTrack ?? this.currentTrack,
    context: context ?? this.context,
    isPlaying: isPlaying ?? this.isPlaying,
    queue: queue ?? this.queue,
    isSyncing: isSyncing ?? this.isSyncing,
    syncStatus: syncStatus ?? this.syncStatus,
    position: position ?? this.position,
    duration: duration ?? this.duration,
  );

  @override
  List<Object?> get props => [currentTrack, isPlaying, isSyncing, position];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final SpotifyService spotifyService;
  final SensorService sensorService;
  final AIRecommendationService aiService;
  final AudioPlayerService audioPlayer;

  StreamSubscription? _contextSub;
  StreamSubscription? _playerSub;
  StreamSubscription? _positionSub;

  HomeBloc({
    required this.spotifyService,
    required this.sensorService,
    required this.aiService,
    required this.audioPlayer,
  }) : super(HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<HomePlayPause>(_onPlayPause);
    on<HomeSkipTrack>(_onSkip);
    on<HomePreviousTrack>(_onPrevious);
    on<HomeContextChanged>(_onContextChanged);
    on<HomeTrackSelected>(_onTrackSelected);
    on<HomeSyncSpotify>(_onSyncSpotify);
    on<_PositionTick>(_onPositionTick);
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      await sensorService.start();

      _contextSub = sensorService.contextStream
          .listen((ctx) => add(HomeContextChanged(ctx)));

      _playerSub = audioPlayer.playerStateStream.listen((ps) {
        if (ps.processingState == ProcessingState.completed) {
          add(HomeSkipTrack());
        }
      });

      _positionSub = audioPlayer.positionStream.listen((pos) {
        if (pos != null) add(_PositionTick(pos, audioPlayer.duration));
      });

      final cached = spotifyService.getCachedTracks();
      final ctx = sensorService.currentContext;
      TrackModel? first;
      if (cached.isNotEmpty && ctx != null) {
        first = await aiService.recommend(ctx);
      }

      emit(HomeReady(currentTrack: first, context: ctx, queue: cached));

      if (first != null) {
        await audioPlayer.playPreview(first);
        spotifyService.recordPlay(first.id);
        if (state is HomeReady) emit((state as HomeReady).copyWith(isPlaying: true));
      }
    } catch (e) {
      emit(HomeError('Failed to start: $e'));
    }
  }

  Future<void> _onPlayPause(HomePlayPause event, Emitter<HomeState> emit) async {
    if (state is! HomeReady) return;
    final s = state as HomeReady;
    if (s.isPlaying) {
      await audioPlayer.pause();
      emit(s.copyWith(isPlaying: false));
    } else {
      if (s.currentTrack != null) {
        await audioPlayer.resume();
      } else {
        await _playNext(emit);
        return;
      }
      if (state is HomeReady) emit((state as HomeReady).copyWith(isPlaying: true));
    }
  }

  Future<void> _onSkip(HomeSkipTrack event, Emitter<HomeState> emit) async {
    if (state is! HomeReady) return;
    final s = state as HomeReady;
    if (s.currentTrack != null && s.context != null) {
      aiService.recordListeningEvent(
        track: s.currentTrack!,
        context: s.context!,
        listenedMs: audioPlayer.getListenedMs(),
        skipped: true,
      );
      spotifyService.recordSkip(s.currentTrack!.id);
    }
    await _playNext(emit);
  }

  Future<void> _onPrevious(HomePreviousTrack event, Emitter<HomeState> emit) async {
    await audioPlayer.seek(Duration.zero);
  }

  void _onContextChanged(HomeContextChanged event, Emitter<HomeState> emit) {
    if (state is HomeReady) emit((state as HomeReady).copyWith(context: event.context));
  }

  Future<void> _onTrackSelected(HomeTrackSelected event, Emitter<HomeState> emit) async {
    if (state is! HomeReady) return;
    await audioPlayer.playPreview(event.track);
    spotifyService.recordPlay(event.track.id);
    emit((state as HomeReady).copyWith(currentTrack: event.track, isPlaying: true, position: Duration.zero));
  }

  Future<void> _onSyncSpotify(HomeSyncSpotify event, Emitter<HomeState> emit) async {
    if (state is! HomeReady) return;
    emit((state as HomeReady).copyWith(isSyncing: true, syncStatus: 'Fetching your Spotify library...'));
    try {
      final tracks = await spotifyService.syncAllTracks();
      emit((state as HomeReady).copyWith(isSyncing: false, syncStatus: 'Synced ${tracks.length} tracks ✓', queue: tracks));
    } catch (e) {
      emit((state as HomeReady).copyWith(isSyncing: false, syncStatus: 'Sync failed'));
    }
  }

  void _onPositionTick(_PositionTick event, Emitter<HomeState> emit) {
    if (state is HomeReady) {
      emit((state as HomeReady).copyWith(position: event.position, duration: event.duration));
    }
  }

  Future<void> _playNext(Emitter<HomeState> emit) async {
    if (state is! HomeReady) return;
    final s = state as HomeReady;
    final ctx = s.context;
    if (ctx == null) return;

    if (s.currentTrack != null) {
      aiService.recordListeningEvent(
        track: s.currentTrack!,
        context: ctx,
        listenedMs: audioPlayer.getListenedMs(),
        skipped: false,
      );
    }

    final next = await aiService.recommend(ctx);
    if (next == null) return;
    await audioPlayer.playPreview(next);
    spotifyService.recordPlay(next.id);
    if (state is HomeReady) {
      emit((state as HomeReady).copyWith(currentTrack: next, isPlaying: true, position: Duration.zero));
    }
  }

  @override
  Future<void> close() {
    _contextSub?.cancel();
    _playerSub?.cancel();
    _positionSub?.cancel();
    audioPlayer.dispose();
    sensorService.dispose();
    return super.close();
  }
}
