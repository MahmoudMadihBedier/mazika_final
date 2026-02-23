import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../home/bloc/home_bloc.dart';
import '../../../core/models/track_model.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _search = '';
  String _filter = 'All';
  static const _filters = ['All', 'Energetic', 'Happy', 'Focus', 'Chill'];

  Color _color(String mood) {
    switch (mood) {
      case 'Energetic': return const Color(0xFFFF4D6D);
      case 'Happy':     return const Color(0xFFFF9F1C);
      case 'Focus':     return const Color(0xFF80FFDB);
      case 'Chill':     return const Color(0xFF4CC9F0);
      default: return Colors.white;
    }
  }

  String _moodOf(TrackModel t) {
    if (t.energy > 0.7 && t.danceability > 0.6) return 'Energetic';
    if (t.valence > 0.7 && t.energy > 0.5)      return 'Happy';
    if (t.energy < 0.4)                          return 'Chill';
    if (t.instrumentalness > 0.5 || t.valence < 0.5) return 'Focus';
    return 'Chill';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(builder: (ctx, state) {
      final tracks = state is HomeReady ? state.queue : <TrackModel>[];
      var shown = tracks.where((t) {
        final q = _search.toLowerCase();
        return (q.isEmpty || t.title.toLowerCase().contains(q) || t.artist.toLowerCase().contains(q))
            && (_filter == 'All' || _moodOf(t) == _filter);
      }).toList()
        ..sort((a, b) => b.playCount.compareTo(a.playCount));

      return Column(children: [
        SafeArea(bottom: false, child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Library', style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
            Text('${tracks.length} tracks synced from Spotify',
                style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withOpacity(0.4))),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                onChanged: (q) => setState(() => _search = q),
                decoration: InputDecoration(
                  hintText: 'Search songs, artists...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 36, child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final active = f == _filter;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? _color(f).withOpacity(0.2) : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: active ? _color(f).withOpacity(0.5) : Colors.white.withOpacity(0.08)),
                    ),
                    child: Text(f, style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? _color(f) : Colors.white.withOpacity(0.6),
                    )),
                  ),
                );
              },
            )),
            const SizedBox(height: 8),
          ]),
        )),
        Expanded(
          child: tracks.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.library_music_outlined, size: 64, color: Colors.white.withOpacity(0.12)),
                  const SizedBox(height: 14),
                  Text('Syncing your Spotify library...', style: GoogleFonts.dmSans(color: Colors.white38)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  itemCount: shown.length,
                  itemBuilder: (_, i) {
                    final t = shown[i];
                    final mood = _moodOf(t);
                    return _TrackTile(track: t, mood: mood, color: _color(mood),
                        onTap: () => context.read<HomeBloc>().add(HomeTrackSelected(t)));
                  },
                ),
        ),
      ]);
    });
  }
}

class _TrackTile extends StatelessWidget {
  final TrackModel track;
  final String mood;
  final Color color;
  final VoidCallback onTap;
  const _TrackTile({required this.track, required this.mood, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: track.albumImageUrl.isNotEmpty
                ? CachedNetworkImage(imageUrl: track.albumImageUrl, width: 52, height: 52, fit: BoxFit.cover)
                : Container(width: 52, height: 52, color: color.withOpacity(0.2),
                    child: Icon(Icons.music_note, color: color)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.45), fontSize: 12)),
          ])),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(mood, style: GoogleFonts.dmSans(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            if (track.playCount > 0) ...[
              const SizedBox(height: 4),
              Text('${track.playCount} plays',
                  style: GoogleFonts.dmSans(color: Colors.white.withOpacity(0.25), fontSize: 10)),
            ],
          ]),
        ]),
      ),
    );
  }
}
