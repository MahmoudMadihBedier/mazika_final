import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../home/bloc/home_bloc.dart';
import '../../../core/models/listening_history_model.dart';
import 'home_screen.dart';
import '../../library/screens/library_screen.dart';
import '../../mood/screens/mood_screen.dart';
import '../../settings/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeStarted());
    Future.delayed(const Duration(seconds: 3),
        () { if (mounted) context.read<HomeBloc>().add(HomeSyncSpotify()); });
  }

  static const _screens = [HomeScreen(), LibraryScreen(), MoodScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: _NavBar(current: _idx, onTap: (i) => setState(() => _idx = i)),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _NavBar({required this.current, required this.onTap});

  static const _tabs = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.library_music_outlined, Icons.library_music_rounded, 'Library'),
    (Icons.auto_awesome_outlined, Icons.auto_awesome, 'Mood'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  Color _moodColor(HomeState state) {
    if (state is HomeReady && state.context != null) {
      switch (state.context!.inferredMood) {
        case MoodType.energetic: return const Color(0xFFFF4D6D);
        case MoodType.happy:     return const Color(0xFFFF9F1C);
        case MoodType.focus:     return const Color(0xFF80FFDB);
        case MoodType.chill:     return const Color(0xFF4CC9F0);
        case MoodType.melancholic: return const Color(0xFF7B2D8B);
      }
    }
    return const Color(0xFFFF4D6D);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (ctx, state) {
        final color = _moodColor(state);
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D15),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_tabs.length, (i) {
                  final active = i == current;
                  final tab = _tabs[i];
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? color.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(active ? tab.$2 : tab.$1,
                            color: active ? color : Colors.white.withOpacity(0.35), size: 24),
                        const SizedBox(height: 4),
                        Text(tab.$3, style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                          color: active ? color : Colors.white.withOpacity(0.35),
                        )),
                        if (active) ...[
                          const SizedBox(height: 3),
                          Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                        ],
                      ]),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
