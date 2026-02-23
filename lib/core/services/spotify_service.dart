import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:hive/hive.dart';

import '../models/track_model.dart';

class SpotifyService {
  // ── REPLACE THESE with your Spotify Developer Dashboard credentials ──────────
  static const String _clientId = '017be02931ef4e3e88b20ced83ddc65b';
  static const String _clientSecret = 'b30ffb8ed8dd4fc1baae5e13a66002d0';
  // ─────────────────────────────────────────────────────────────────────────────
  static const String _redirectUri = 'mazika://callback';
  static const String _baseUrl = 'https://api.spotify.com/v1';

  static const List<String> _scopes = [
    'user-library-read',
    'user-top-read',
    'user-read-recently-played',
    'playlist-read-private',
    'playlist-read-collaborative',
    'streaming',
    'user-read-playback-state',
    'user-modify-playback-state',
  ];

  final Logger _logger = Logger();
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  // ── Auth ─────────────────────────────────────────────────────────────────────

  Future<bool> authenticate() async {
    try {
      final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
        'client_id': _clientId,
        'response_type': 'code',
        'redirect_uri': _redirectUri,
        'scope': _scopes.join(' '),
        'show_dialog': 'false',
      });
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'mazika',
      );
      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) return false;
      await _exchangeCode(code);
      return true;
    } catch (e) {
      _logger.e('Spotify auth failed: $e');
      return false;
    }
  }

  Future<void> _exchangeCode(String code) async {
    final resp = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$_clientId:$_clientSecret'))}',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _redirectUri,
      },
    );
    _saveTokens(jsonDecode(resp.body));
  }

  Future<void> _refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString('spotify_refresh_token');
    if (refresh == null) return;
    final resp = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$_clientId:$_clientSecret'))}',
      },
      body: {'grant_type': 'refresh_token', 'refresh_token': refresh},
    );
    _saveTokens(jsonDecode(resp.body));
  }

  void _saveTokens(Map<String, dynamic> data) async {
    _accessToken = data['access_token'];
    _refreshToken = data['refresh_token'] ?? _refreshToken;
    _tokenExpiry =
        DateTime.now().add(Duration(seconds: data['expires_in'] ?? 3600));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spotify_access_token', _accessToken!);
    if (_refreshToken != null)
      await prefs.setString('spotify_refresh_token', _refreshToken!);
    await prefs.setString(
        'spotify_token_expiry', _tokenExpiry!.toIso8601String());
  }

  Future<void> loadSavedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('spotify_access_token');
    _refreshToken = prefs.getString('spotify_refresh_token');
    final e = prefs.getString('spotify_token_expiry');
    if (e != null) _tokenExpiry = DateTime.parse(e);
  }

  bool get isAuthenticated => _accessToken != null;

  Future<Map<String, String>> _authHeaders() async {
    await loadSavedTokens();
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isAfter(_tokenExpiry!)) {
      await _refreshAccessToken();
    }
    return {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
    };
  }

  // ── Full Library Sync ─────────────────────────────────────────────────────

  Future<List<TrackModel>> syncAllTracks() async {
    _logger.i('Starting full Spotify sync...');
    final all = <String, TrackModel>{};

    for (final t in await _fetchSavedTracks()) all[t.id] = t;
    for (final term in ['short_term', 'medium_term', 'long_term']) {
      for (final t in await _fetchTopTracks(term)) all[t.id] = t;
    }
    for (final t in await _fetchRecentlyPlayed()) all[t.id] = t;
    for (final t in await _fetchPlaylistTracks()) all[t.id] = t;

    _logger.i('${all.length} unique tracks — enriching audio features...');
    final enriched = await _enrichWithAudioFeatures(all.values.toList());

    final box = Hive.box<TrackModel>('tracks');
    for (final track in enriched) {
      final existing = box.get(track.id);
      box.put(
        track.id,
        existing != null
            ? track.copyWith(
                playCount: existing.playCount,
                skipCount: existing.skipCount,
                lastPlayed: existing.lastPlayed,
              )
            : track,
      );
    }
    _logger.i('Sync done. ${enriched.length} tracks saved.');
    return enriched;
  }

  Future<List<TrackModel>> _fetchSavedTracks() async {
    final tracks = <TrackModel>[];
    String? next = '$_baseUrl/me/tracks?limit=50';
    while (next != null) {
      final resp =
          await http.get(Uri.parse(next), headers: await _authHeaders());
      if (resp.statusCode != 200) break;
      final data = jsonDecode(resp.body);
      for (final item in (data['items'] as List? ?? [])) {
        if (item['track']?['id'] != null)
          tracks.add(TrackModel.fromSpotifyJson(item));
      }
      next = data['next'];
    }
    return tracks;
  }

  Future<List<TrackModel>> _fetchTopTracks(String timeRange) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/me/top/tracks?limit=50&time_range=$timeRange'),
      headers: await _authHeaders(),
    );
    if (resp.statusCode != 200) return [];
    return ((jsonDecode(resp.body)['items'] as List?) ?? [])
        .where((i) => i['id'] != null)
        .map((i) => TrackModel.fromSpotifyJson(i))
        .toList();
  }

  Future<List<TrackModel>> _fetchRecentlyPlayed() async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/me/player/recently-played?limit=50'),
      headers: await _authHeaders(),
    );
    if (resp.statusCode != 200) return [];
    return ((jsonDecode(resp.body)['items'] as List?) ?? [])
        .where((i) => i['track'] != null)
        .map((i) => TrackModel.fromSpotifyJson(i))
        .toList();
  }

  Future<List<TrackModel>> _fetchPlaylistTracks() async {
    final tracks = <TrackModel>[];
    final plResp = await http.get(
        Uri.parse('$_baseUrl/me/playlists?limit=20'),
        headers: await _authHeaders());
    if (plResp.statusCode != 200) return tracks;
    final playlists =
        (jsonDecode(plResp.body)['items'] as List?) ?? [];
    for (final pl in playlists) {
      String? next =
          '$_baseUrl/playlists/${pl['id']}/tracks?limit=100&fields=next,items(track(id,name,artists,album,uri,preview_url,duration_ms))';
      while (next != null) {
        final resp =
            await http.get(Uri.parse(next), headers: await _authHeaders());
        if (resp.statusCode != 200) break;
        final data = jsonDecode(resp.body);
        for (final item in (data['items'] as List? ?? [])) {
          if (item['track']?['id'] != null)
            tracks.add(TrackModel.fromSpotifyJson(item));
        }
        next = data['next'];
      }
    }
    return tracks;
  }

  Future<List<TrackModel>> _enrichWithAudioFeatures(
      List<TrackModel> tracks) async {
    final enriched = <TrackModel>[];
    for (int i = 0; i < tracks.length; i += 100) {
      final batch = tracks.sublist(i, (i + 100).clamp(0, tracks.length));
      final ids = batch.map((t) => t.id).join(',');
      final resp = await http.get(
        Uri.parse('$_baseUrl/audio-features?ids=$ids'),
        headers: await _authHeaders(),
      );
      if (resp.statusCode == 200) {
        final features =
            (jsonDecode(resp.body)['audio_features'] as List?) ?? [];
        for (int j = 0; j < batch.length; j++) {
          enriched.add(j < features.length && features[j] != null
              ? batch[j].withAudioFeatures(features[j])
              : batch[j]);
        }
      } else {
        enriched.addAll(batch);
      }
      await Future.delayed(const Duration(milliseconds: 120));
    }
    return enriched;
  }

  // ── Playback ─────────────────────────────────────────────────────────────

  Future<void> playTrack(String spotifyUri) async {
    await http.put(
      Uri.parse('$_baseUrl/me/player/play'),
      headers: await _authHeaders(),
      body: jsonEncode({'uris': [spotifyUri]}),
    );
  }

  Future<void> pause() async => http.put(
      Uri.parse('$_baseUrl/me/player/pause'),
      headers: await _authHeaders());

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserProfile() async {
    final resp = await http.get(Uri.parse('$_baseUrl/me'),
        headers: await _authHeaders());
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('spotify_access_token');
    await prefs.remove('spotify_refresh_token');
    await prefs.remove('spotify_token_expiry');
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
  }

  // ── Local Helpers ─────────────────────────────────────────────────────────

  List<TrackModel> getCachedTracks() =>
      Hive.box<TrackModel>('tracks').values.toList();

  void recordPlay(String trackId) {
    final box = Hive.box<TrackModel>('tracks');
    final t = box.get(trackId);
    if (t != null)
      box.put(trackId,
          t.copyWith(playCount: t.playCount + 1, lastPlayed: DateTime.now()));
  }

  void recordSkip(String trackId) {
    final box = Hive.box<TrackModel>('tracks');
    final t = box.get(trackId);
    if (t != null)
      box.put(trackId, t.copyWith(skipCount: t.skipCount + 1));
  }
}
