import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import '../../mood/bloc/mood_bloc.dart';
import '../../home/bloc/home_bloc.dart';
import '../../../core/models/listening_history_model.dart';
import '../../../core/models/context_model.dart';

class MoodScreen extends StatelessWidget {
  const MoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (ctx, state) {
        final ctx2 = state is HomeReady ? state.context : null;
        return _MoodBody(context: ctx2);
      },
    );
  }
}

class _MoodBody extends StatelessWidget {
  final ContextModel? context;
  const _MoodBody({this.context});

  Color get _color {
    switch (context?.inferredMood) {
      case MoodType.energetic:
        return const Color(0xFFFF4D6D);
      case MoodType.happy:
        return const Color(0xFFFF9F1C);
      case MoodType.focus:
        return const Color(0xFF80FFDB);
      case MoodType.chill:
        return const Color(0xFF4CC9F0);
      case MoodType.melancholic:
        return const Color(0xFF7B2D8B);
      default:
        return const Color(0xFF4CC9F0);
    }
  }

  String _timeReason() {
    final h = context?.hourOfDay ?? DateTime.now().hour;
    if (h >= 21 || h < 6) return 'It\'s late night — calm vibes';
    if (h >= 6 && h < 10) return 'Good morning — fresh energy';
    if (h >= 10 && h < 17) return 'Daytime — steady focus';
    return 'Evening — winding down';
  }

  @override
  Widget build(BuildContext ctx) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood',
              style: GoogleFonts.syne(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'What the AI is sensing',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: _MoodOrb(
                color: _color,
                label: context?.moodLabel ?? 'Unknown',
              ),
            ),
            const SizedBox(height: 28),
            _label('Why this mood'),
            const SizedBox(height: 10),
            _reason(
              Icons.place_outlined,
              'You\'re ${context?.activityLabel.toLowerCase() ?? 'relaxing'}',
            ),
            const SizedBox(height: 8),
            _reason(Icons.access_time_rounded, _timeReason()),
            const SizedBox(height: 8),
            _reason(
              Icons.speed_rounded,
              'Speed: ${context?.gpsSpeed.toStringAsFixed(1) ?? '0.0'} m/s',
            ),
            const SizedBox(height: 24),
            _label('Override mood'),
            const SizedBox(height: 12),
            _MoodChips(moodColor: _color),
            const SizedBox(height: 24),
            _label('AI Scoring Weights'),
            const SizedBox(height: 12),
            _ScoreBreakdown(moodColor: _color),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
    t.toUpperCase(),
    style: GoogleFonts.dmSans(
      fontSize: 11,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w600,
      color: Colors.white.withOpacity(0.35),
    ),
  );

  Widget _reason(IconData icon, String text) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.6), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.dmSans(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MoodOrb extends StatefulWidget {
  final Color color;
  final String label;
  const _MoodOrb({required this.color, required this.label});
  @override
  State<_MoodOrb> createState() => _MoodOrbState();
}

class _MoodOrbState extends State<_MoodOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _anim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(0, -sin(_anim.value * pi) * 8),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [widget.color, widget.color.withOpacity(0.5)],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.4 + _anim.value * 0.2),
                  blurRadius: 40 + _anim.value * 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MoodChips extends StatelessWidget {
  final Color moodColor;
  const _MoodChips({required this.moodColor});

  static const _moods = [
    ('Energetic', MoodType.energetic, Color(0xFFFF4D6D)),
    ('Chill', MoodType.chill, Color(0xFF4CC9F0)),
    ('Focus', MoodType.focus, Color(0xFF80FFDB)),
    ('Happy', MoodType.happy, Color(0xFFFF9F1C)),
    ('Melancholic', MoodType.melancholic, Color(0xFF7B2D8B)),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _moods
          .map((moodTuple) {
            final label = moodTuple.$1;
            final mood = moodTuple.$2;
            final color = moodTuple.$3;
            return GestureDetector(
              onTap: () =>
                  context.read<MoodBloc>().add(MoodOverrideRequested(mood)),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          })
          .toList()
          .cast<Widget>(),
    );
  }
}

class _ScoreBreakdown extends StatelessWidget {
  final Color moodColor;
  const _ScoreBreakdown({required this.moodColor});

  @override
  Widget build(BuildContext context) {
    final factors = [
      ('Content Match', 0.35, 'Audio features vs your context'),
      ('Behavior Score', 0.30, 'Skip & replay history'),
      ('Context-Time', 0.20, 'Past plays in similar situation'),
      ('Freshness', 0.10, 'Time since last played'),
      ('Diversity', 0.05, 'Avoids recent repeats in session'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: factors.map((f) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      f.$1,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(f.$2 * 100).toInt()}%',
                      style: GoogleFonts.dmSans(
                        color: moodColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: f.$2,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation(moodColor),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 2),
                Text(
                  f.$3,
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
