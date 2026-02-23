import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/spotify_service.dart';
import '../../home/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final svc = SpotifyService();
    await svc.loadSavedTokens();
    if (svc.isAuthenticated && mounted) {
      await Future.delayed(const Duration(milliseconds: 1500));
      _goMain();
    }
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    final svc = SpotifyService();
    final ok = await svc.authenticate();
    if (!mounted) return;
    if (ok) { _goMain(); } else {
      setState(() { _loading = false; _error = 'Authentication failed. Please try again.'; });
    }
  }

  void _goMain() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const MainScreen(),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(children: [
            const Spacer(flex: 2),
            ScaleTransition(
              scale: _scale,
              child: Column(children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4D6D), Color(0xFFFF9F1C)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(color: const Color(0xFFFF4D6D).withOpacity(0.4), blurRadius: 40, spreadRadius: 5)],
                  ),
                  child: const Icon(Icons.music_note_rounded, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text('Mazj', style: GoogleFonts.syne(fontSize: 52, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
                const SizedBox(height: 8),
                Text('Music that matches your moment', style: GoogleFonts.dmSans(fontSize: 16, color: Colors.white.withOpacity(0.5))),
              ]),
            ),
            const Spacer(flex: 2),
            _pill(Icons.sensors, 'Detects your activity automatically'),
            const SizedBox(height: 12),
            _pill(Icons.psychology_outlined, 'AI picks the best song for you'),
            const SizedBox(height: 12),
            _pill(Icons.library_music_outlined, 'From your full Spotify library'),
            const Spacer(),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Color(0xFFFF4D6D), fontSize: 13)),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.music_note, color: Colors.white),
                        const SizedBox(width: 10),
                        Text('Continue with Spotify', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ]),
              ),
            ),
            const SizedBox(height: 14),
            Text('We only read your library. We never post anything.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withOpacity(0.3))),
            const SizedBox(height: 48),
          ]),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFFF4D6D).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFFFF4D6D), size: 20),
      ),
      const SizedBox(width: 16),
      Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14))),
    ]),
  );
}
