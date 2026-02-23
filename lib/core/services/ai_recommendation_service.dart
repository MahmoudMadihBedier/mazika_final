import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'dart:math';

import '../models/track_model.dart';
import '../models/context_model.dart';
import '../models/listening_history_model.dart';

/// ═══════════════════════════════════════════════════════════════════
/// Mazj AI Recommendation Engine — Hybrid Scoring
///
/// Score = (contentScore × 0.35)
///       + (behaviorScore × 0.30)
///       + (contextTimeScore × 0.20)
///       + (freshnessScore × 0.10)
///       + (diversityScore × 0.05)
/// ═══════════════════════════════════════════════════════════════════

class AIRecommendationService {
  final Logger _logger = Logger();
  final List<String> _sessionHistory = [];
  static const int _sessionWindow = 10;

  // ── Main API ─────────────────────────────────────────────────────────────

  Future<TrackModel?> recommend(ContextModel context) async {
    final tracks = Hive.box<TrackModel>('tracks').values.toList();
    if (tracks.isEmpty) return null;

    _logger.i('Scoring ${tracks.length} tracks for ${context.activityLabel}/${context.moodLabel}');

    final scored = tracks
        .map((t) => _ScoredTrack(track: t, score: _scoreTrack(t, context)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final chosen = _weightedRandomPick(scored.take(5).toList());
    _sessionHistory.add(chosen.id);
    if (_sessionHistory.length > _sessionWindow) _sessionHistory.removeAt(0);

    _logger.i('→ "${chosen.title}" by ${chosen.artist}');
    return chosen;
  }

  Future<List<TrackModel>> recommendPlaylist(ContextModel context, {int count = 20}) async {
    final tracks = Hive.box<TrackModel>('tracks').values.toList();
    if (tracks.isEmpty) return [];
    return tracks
        .map((t) => _ScoredTrack(track: t, score: _scoreTrack(t, context)))
        .toList()
        .sorted((a, b) => b.score.compareTo(a.score))
        .take(count)
        .map((s) => s.track)
        .toList();
  }

  // ── Full Scoring Pipeline ─────────────────────────────────────────────────

  double _scoreTrack(TrackModel track, ContextModel context) {
    return (
      _contentScore(track, context) * 0.35 +
      _behaviorScore(track)          * 0.30 +
      _contextTimeScore(track, context) * 0.20 +
      _freshnessScore(track)         * 0.10 +
      _diversityScore(track)         * 0.05
    ).clamp(0.0, 1.0);
  }

  // 1. Content: audio features vs context target
  double _contentScore(TrackModel track, ContextModel ctx) {
    final tEnergy   = _targetEnergy(ctx);
    final tValence  = _targetValence(ctx);
    final tTempo    = _targetTempo(ctx) / 200.0;
    final tDance    = _targetDanceability(ctx);
    final tAcoustic = _targetAcousticness(ctx);

    final energyD   = (track.energy - tEnergy).abs();
    final valenceD  = (track.valence - tValence).abs();
    final tempoD    = (track.tempo / 200.0 - tTempo).abs();
    final danceD    = (track.danceability - tDance).abs();
    final acousticD = (track.acousticness - tAcoustic).abs();

    final dist = sqrt(energyD*energyD + valenceD*valenceD +
        tempoD*tempoD + danceD*danceD + acousticD*acousticD) / sqrt(5);
    return 1.0 - dist;
  }

  double _targetEnergy(ContextModel ctx) {
    switch (ctx.inferredMood) {
      case MoodType.energetic: return 0.85;
      case MoodType.happy:     return 0.70;
      case MoodType.focus:     return 0.50;
      case MoodType.chill:     return 0.30;
      case MoodType.melancholic: return 0.25;
    }
  }

  double _targetValence(ContextModel ctx) {
    switch (ctx.inferredMood) {
      case MoodType.energetic: return 0.75;
      case MoodType.happy:     return 0.85;
      case MoodType.focus:     return 0.50;
      case MoodType.chill:     return 0.55;
      case MoodType.melancholic: return 0.20;
    }
  }

  double _targetTempo(ContextModel ctx) {
    switch (ctx.activity) {
      case ActivityType.running:  return 160;
      case ActivityType.walking:  return 110;
      case ActivityType.driving:  return 125;
      case ActivityType.working:  return 100;
      case ActivityType.relaxing: return 80;
      default: return 100;
    }
  }

  double _targetDanceability(ContextModel ctx) {
    switch (ctx.inferredMood) {
      case MoodType.energetic: return 0.80;
      case MoodType.happy:     return 0.75;
      case MoodType.focus:     return 0.35;
      case MoodType.chill:     return 0.50;
      case MoodType.melancholic: return 0.30;
    }
  }

  double _targetAcousticness(ContextModel ctx) {
    if (ctx.isNight) return 0.55;
    if (ctx.activity == ActivityType.relaxing) return 0.60;
    if (ctx.activity == ActivityType.running)  return 0.05;
    return 0.30;
  }

  // 2. Behavior: personal play/skip history
  double _behaviorScore(TrackModel track) {
    if (track.playCount == 0) return 0.5;
    final popularityBoost = min(track.playCount / 20.0, 0.2);
    return (track.enjoymentScore + popularityBoost).clamp(0.0, 1.0);
  }

  // 3. Context-time: past listens in similar context
  double _contextTimeScore(TrackModel track, ContextModel context) {
    final history = Hive.box<ListeningHistoryModel>('history')
        .values
        .where((h) => h.trackId == track.id)
        .toList();
    if (history.isEmpty) return 0.5;
    final similar = history.where((h) =>
        h.activityType == context.activity.name ||
        (h.hourOfDay - context.hourOfDay).abs() <= 3).toList();
    if (similar.isEmpty) return 0.5;
    return similar.where((h) => h.wasEnjoyed).length / similar.length;
  }

  // 4. Freshness
  double _freshnessScore(TrackModel track) {
    if (track.lastPlayed == null) return 0.8;
    final days = DateTime.now().difference(track.lastPlayed!).inDays;
    if (days >= 14) return 0.9;
    if (days >= 7)  return 0.7;
    if (days >= 3)  return 0.5;
    if (days >= 1)  return 0.3;
    return 0.1;
  }

  // 5. Session diversity
  double _diversityScore(TrackModel track) {
    if (!_sessionHistory.contains(track.id)) return 1.0;
    final pos = _sessionHistory.indexOf(track.id);
    return pos / _sessionWindow;
  }

  // ── Weighted Random Pick ─────────────────────────────────────────────────

  TrackModel _weightedRandomPick(List<_ScoredTrack> candidates) {
    if (candidates.length == 1) return candidates.first.track;
    final total = candidates.fold(0.0, (s, c) => s + c.score);
    var rand = Random().nextDouble() * total;
    for (final c in candidates) {
      rand -= c.score;
      if (rand <= 0) return c.track;
    }
    return candidates.first.track;
  }

  // ── Learning ─────────────────────────────────────────────────────────────

  void recordListeningEvent({
    required TrackModel track,
    required ContextModel context,
    required int listenedMs,
    required bool skipped,
  }) {
    final box = Hive.box<ListeningHistoryModel>('history');
    box.add(ListeningHistoryModel(
      trackId: track.id,
      playedAt: DateTime.now(),
      activityType: context.activity.name,
      moodType: context.inferredMood.name,
      listenedMs: listenedMs,
      trackDurationMs: track.durationMs,
      skipped: skipped,
      gpsSpeed: context.gpsSpeed,
      hourOfDay: context.hourOfDay,
      dayOfWeek: context.dayOfWeek,
    ));
  }

  Map<String, dynamic> getInsights() {
    final tracks = Hive.box<TrackModel>('tracks').values.toList();
    final history = Hive.box<ListeningHistoryModel>('history').values.toList();
    final totalPlays = tracks.fold(0, (s, t) => s + t.playCount);
    final avgSkip = tracks.isEmpty
        ? 0.0
        : tracks.fold(0.0, (s, t) => s + t.skipRate) / tracks.length;
    return {
      'total_tracks': tracks.length,
      'total_plays': totalPlays,
      'avg_skip_rate': avgSkip,
      'history_count': history.length,
    };
  }
}

class _ScoredTrack {
  final TrackModel track;
  final double score;
  const _ScoredTrack({required this.track, required this.score});
}

// Extension for sorting
extension _ListExt<T> on List<T> {
  List<T> sorted(int Function(T, T) compare) => [...this]..sort(compare);
}
