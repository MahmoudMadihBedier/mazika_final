import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/spotify_service.dart';
import '../../auth/screens/splash_screen.dart';
import '../../home/bloc/home_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _aiEnabled = true, _autoPlay = true, _privacy = false;
  String? _userName, _userImage;

  @override
  void initState() { super.initState(); _loadAll(); }

  Future<void> _loadAll() async {
    final svc = SpotifyService();
    final profile = await svc.getUserProfile();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName  = profile?['display_name'];
      final imgs = profile?['images'] as List?;
      _userImage = imgs?.isNotEmpty == true ? imgs!.first['url'] : null;
      _aiEnabled = prefs.getBool('ai_enabled') ?? true;
      _autoPlay  = prefs.getBool('auto_play') ?? true;
      _privacy   = prefs.getBool('privacy_mode') ?? false;
    });
  }

  Future<void> _setPref(String k, bool v) async =>
      (await SharedPreferences.getInstance()).setBool(k, v);

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF13131F),
        title: Text('Logout', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Disconnect your Spotify account?', style: GoogleFonts.dmSans(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout', style: TextStyle(color: Color(0xFFFF4D6D)))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await SpotifyService().logout();
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()), (_) => false);
    }
  }

  void _sync() {
    context.read<HomeBloc>().add(HomeSyncSpotify());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Syncing Spotify library...', style: GoogleFonts.dmSans()),
      backgroundColor: const Color(0xFF13131F),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Settings', style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 20),
        // Profile
        _ProfileCard(name: _userName, imageUrl: _userImage),
        const SizedBox(height: 24),
        _sectionLabel('AI Controls'),
        _card([
          _toggle('Enable AI', 'Context-aware automatic song selection', _aiEnabled, (v) { setState(() => _aiEnabled = v); _setPref('ai_enabled', v); }),
          _div(),
          _toggle('Auto-play', 'Start music when app opens', _autoPlay, (v) { setState(() => _autoPlay = v); _setPref('auto_play', v); }),
        ]),
        const SizedBox(height: 20),
        _sectionLabel('Library'),
        _card([
          _action('Sync Spotify Library', 'Re-fetch all tracks + audio features', Icons.sync_rounded, _sync),
          _div(),
          _toggle('Privacy Mode', 'Disable local history logging', _privacy, (v) { setState(() => _privacy = v); _setPref('privacy_mode', v); }),
        ]),
        const SizedBox(height: 20),
        _sectionLabel('How AI Selects Songs'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.07))),
          child: Column(children: [
            _aiFact(Icons.sensors, 'GPS + accelerometer → activity detection'),
            _aiFact(Icons.music_note_rounded, 'Audio features (energy, tempo, valence) matched to context'),
            _aiFact(Icons.history, 'Learns from your skip & replay history'),
            _aiFact(Icons.star_outline, 'Surfaces fresh songs you haven\'t heard lately'),
            _aiFact(Icons.lock_outline, 'All data stays on your device'),
          ]),
        ),
        const SizedBox(height: 20),
        _sectionLabel('About'),
        _card([
          _info('Version', '1.0.0'),
          _div(),
          _info('AI Model', 'Hybrid Content + Behavior Engine'),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF4D6D)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('Disconnect Spotify', style: GoogleFonts.dmSans(color: const Color(0xFFFF4D6D), fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    ));
  }

  Widget _sectionLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Text(t.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 11, letterSpacing: 1.5, color: Colors.white.withOpacity(0.35), fontWeight: FontWeight.w600)));

  Widget _card(List<Widget> ch) => Container(
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.07))),
    child: Column(children: ch),
  );

  Widget _div() => Divider(height: 1, color: Colors.white.withOpacity(0.06), indent: 16, endIndent: 16);

  Widget _toggle(String title, String sub, bool val, ValueChanged<bool> onChanged) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        Text(sub, style: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      ])),
      Switch(value: val, onChanged: onChanged, activeColor: const Color(0xFFFF4D6D)),
    ]),
  );

  Widget _action(String title, String sub, IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [
      Icon(icon, color: const Color(0xFFFF4D6D), size: 22),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        Text(sub, style: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      ])),
      Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
    ])),
  );

  Widget _info(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(k, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14)),
      Text(v, style: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.4), fontSize: 14)),
    ]),
  );

  Widget _aiFact(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: const Color(0xFF4CC9F0), size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.6), fontSize: 13))),
    ]),
  );
}

class _ProfileCard extends StatelessWidget {
  final String? name, imageUrl;
  const _ProfileCard({this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [const Color(0xFF1DB954).withOpacity(0.15), Colors.transparent], begin: Alignment.topLeft),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.3)),
    ),
    child: Row(children: [
      CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFF1DB954).withOpacity(0.2),
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null ? const Icon(Icons.person, color: Color(0xFF1DB954)) : null,
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name ?? 'Spotify User', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        Text('Connected via Spotify', style: GoogleFonts.dmSans(color: const Color(0xFF1DB954), fontSize: 12)),
      ])),
      const Icon(Icons.check_circle_rounded, color: Color(0xFF1DB954)),
    ]),
  );
}
