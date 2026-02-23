import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';

import '../bloc/home_bloc.dart';
import '../../../core/models/listening_history_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(builder: (ctx, state) {
      if (state is HomeLoading) return _Loading();
      if (state is HomeError) return _Err(state.message);
      if (state is HomeReady) return _HomeView(state: state);
      return _Loading();
    });
  }
}

class _Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const CircularProgressIndicator(color: Color(0xFFFF4D6D)),
      const SizedBox(height: 16),
      Text('Starting AI...', style: GoogleFonts.dmSans(color: Colors.white54)),
    ]),
  );
}

class _Err extends StatelessWidget {
  final String msg;
  const _Err(this.msg);
  @override
  Widget build(BuildContext context) =>
      Center(child: Text(msg, style: const TextStyle(color: Colors.redAccent)));
}

class _HomeView extends StatelessWidget {
  final HomeReady state;
  const _HomeView({required this.state});

  Color get _color {
    switch (state.context?.inferredMood) {
      case MoodType.energetic: return const Color(0xFFFF4D6D);
      case MoodType.happy:     return const Color(0xFFFF9F1C);
      case MoodType.focus:     return const Color(0xFF80FFDB);
      case MoodType.chill:     return const Color(0xFF4CC9F0);
      case MoodType.melancholic: return const Color(0xFF7B2D8B);
      default: return const Color(0xFFFF4D6D);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Background glow
      Positioned(
        top: -60, left: 0, right: 0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 1500),
          height: 420,
          decoration: BoxDecoration(
            gradient: RadialGradient(colors: [_color.withOpacity(0.18), Colors.transparent], radius: 0.8),
          ),
        ),
      ),
      SafeArea(child: Column(children: [
        _buildHeader(context),
        if (state.isSyncing) _buildSyncBanner(),
        Expanded(child: _buildPlayer(context)),
        _buildControls(context),
        const SizedBox(height: 20),
      ])),
    ]);
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mazj', style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
          Text('AI is listening', style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withOpacity(0.4))),
        ]),
        if (state.context != null)
          Row(children: [
            _Pill(state.context!.activityLabel, Colors.white.withOpacity(0.1)),
            const SizedBox(width: 8),
            _Pill(state.context!.moodLabel, _color.withOpacity(0.2), textColor: _color),
          ]),
      ]),
    );
  }

  Widget _buildSyncBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(children: [
        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _color)),
        const SizedBox(width: 10),
        Expanded(child: Text(state.syncStatus ?? 'Syncing...', style: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.6), fontSize: 13))),
      ]),
    );
  }

  Widget _buildPlayer(BuildContext context) {
    final track = state.currentTrack;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _VinylDisc(
        imageUrl: track?.albumImageUrl,
        isSpinning: state.isPlaying,
        moodColor: _color,
        onTap: () => context.read<HomeBloc>().add(HomePlayPause()),
      ),
      const SizedBox(height: 30),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(children: [
          Text(track?.title ?? 'Tap play to start', textAlign: TextAlign.center, maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text(track?.artist ?? 'AI will choose for you', textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white.withOpacity(0.5))),
        ]),
      ),
      const SizedBox(height: 24),
      if (track != null) _ProgressBar(state: state, moodColor: _color, context: context),
    ]);
  }

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _CtrlBtn(Icons.skip_previous_rounded,
            () => context.read<HomeBloc>().add(HomePreviousTrack())),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: () => context.read<HomeBloc>().add(HomePlayPause()),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [_color, _color.withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: _color.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
            ),
            child: Icon(state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 36, color: Colors.white),
          ),
        ),
        const SizedBox(width: 20),
        _CtrlBtn(Icons.skip_next_rounded,
            () => context.read<HomeBloc>().add(HomeSkipTrack())),
      ]),
    );
  }
}

// ── Vinyl Disc ────────────────────────────────────────────────────────────────
class _VinylDisc extends StatefulWidget {
  final String? imageUrl;
  final bool isSpinning;
  final Color moodColor;
  final VoidCallback onTap;
  const _VinylDisc({this.imageUrl, required this.isSpinning, required this.moodColor, required this.onTap});

  @override State<_VinylDisc> createState() => _VinylDiscState();
}

class _VinylDiscState extends State<_VinylDisc> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    if (!widget.isSpinning) _ctrl.stop();
  }

  @override
  void didUpdateWidget(_VinylDisc old) {
    super.didUpdateWidget(old);
    if (widget.isSpinning != old.isSpinning) {
      widget.isSpinning ? _ctrl.repeat() : _ctrl.stop();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.rotate(angle: _ctrl.value * 2 * pi, child: child),
        child: Stack(alignment: Alignment.center, children: [
          Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A2E),
              boxShadow: [BoxShadow(color: widget.moodColor.withOpacity(0.3), blurRadius: 40, spreadRadius: 5)],
              border: Border.all(color: widget.moodColor.withOpacity(0.3), width: 2),
            ),
          ),
          for (final r in [100.0, 82.0, 64.0])
            Container(width: r*2, height: r*2,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.04)))),
          ClipOval(
            child: Container(
              width: 90, height: 90,
              color: const Color(0xFF0A0A0F),
              child: widget.imageUrl?.isNotEmpty == true
                  ? CachedNetworkImage(imageUrl: widget.imageUrl!, fit: BoxFit.cover,
                      placeholder: (_, __) => Icon(Icons.music_note, color: widget.moodColor.withOpacity(0.5)),
                      errorWidget: (_, __, ___) => Icon(Icons.music_note, color: widget.moodColor.withOpacity(0.5)))
                  : Icon(Icons.music_note_rounded, size: 36, color: widget.moodColor.withOpacity(0.7)),
            ),
          ),
          Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0A0A0F))),
        ]),
      ),
    );
  }
}

// ── Progress Bar ──────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final HomeReady state;
  final Color moodColor;
  final BuildContext context;
  const _ProgressBar({required this.state, required this.moodColor, required this.context});

  String _fmt(int ms) {
    final s = ms ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext _) {
    final total = state.duration?.inMilliseconds ?? 1;
    final current = state.position.inMilliseconds;
    final ratio = (current / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: moodColor,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
            thumbColor: moodColor,
            overlayColor: moodColor.withOpacity(0.2),
          ),
          child: Slider(value: ratio.toDouble(), onChanged: (_) {}),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_fmt(current), style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white38)),
            Text(_fmt(total),   style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white38)),
          ]),
        ),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  const _Pill(this.label, this.color, {this.textColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: textColor ?? Colors.white70)),
  );
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CtrlBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 52, height: 52,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)),
      child: Icon(icon, color: Colors.white, size: 26),
    ),
  );
}
