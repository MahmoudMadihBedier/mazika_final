# Mazj — AI Music App (mazika Flutter project)

## Quick Start

### 1. Get Spotify API credentials
- Go to https://developer.spotify.com/dashboard
- Create an app → add Redirect URI: `mazika://callback`
- Copy Client ID and Client Secret

### 2. Add your credentials
Open `lib/core/services/spotify_service.dart` and replace:
```dart
static const String _clientId = 'YOUR_SPOTIFY_CLIENT_ID';
static const String _clientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';
```

### 3. Install & run
```bash
flutter pub get
flutter run
```

---

## How the AI Works

Every track in your Spotify library gets scored (0–1) from 5 factors:

| Factor | Weight | What it measures |
|--------|--------|-----------------|
| Content Match | **35%** | Audio features (energy, tempo, valence) vs target for your mood/activity |
| Behavior Score | **30%** | Your personal skip rate and replay count |
| Context-Time | **20%** | Did you enjoy this track in similar situations before? |
| Freshness | **10%** | How long since you last played it |
| Diversity | **5%** | Avoids replaying recent session songs |

### Activity Detection
| Sensor Reading | Classification |
|----------------|----------------|
| GPS > 7 m/s | Driving |
| GPS > 2.5 m/s OR accel > 14 | Running |
| GPS > 0.5 OR accel > 10.5 | Walking |
| Very still | Relaxing |
| Default | Working |

### Data Synced from Spotify
- ✅ All liked/saved songs
- ✅ Top tracks (short, medium, long term)
- ✅ Recently played
- ✅ All playlists
- ✅ Audio features for every track (energy, tempo, valence, danceability, acousticness)

All learning data (play/skip events) is stored locally on-device using Hive.

---

## Project Structure
```
lib/
├── main.dart
├── core/
│   ├── models/          # TrackModel, ListeningHistory, ContextModel
│   └── services/        # SpotifyService, SensorService, AIRecommendationService, AudioPlayerService
└── features/
    ├── auth/            # SplashScreen (Spotify login)
    ├── home/            # HomeBloc + HomeScreen + MainScreen
    ├── library/         # LibraryScreen
    ├── mood/            # MoodBloc + MoodScreen
    └── settings/        # SettingsScreen
```
