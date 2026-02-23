import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/models/track_model.dart';
import 'core/models/listening_history_model.dart';
import 'core/services/spotify_service.dart';
import 'core/services/sensor_service.dart';
import 'core/services/ai_recommendation_service.dart';
import 'core/services/audio_player_service.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/home/bloc/home_bloc.dart';
import 'features/mood/bloc/mood_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await Hive.initFlutter();
  Hive.registerAdapter(TrackModelAdapter());
  Hive.registerAdapter(ListeningHistoryModelAdapter());
  await Hive.openBox<TrackModel>('tracks');
  await Hive.openBox<ListeningHistoryModel>('history');
  await Hive.openBox('preferences');
  runApp(const MazjApp());
}

class MazjApp extends StatelessWidget {
  const MazjApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => SpotifyService()),
        RepositoryProvider(create: (_) => SensorService()),
        RepositoryProvider(create: (_) => AIRecommendationService()),
        RepositoryProvider(create: (_) => AudioPlayerService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (ctx) => HomeBloc(
            spotifyService: ctx.read<SpotifyService>(),
            sensorService: ctx.read<SensorService>(),
            aiService: ctx.read<AIRecommendationService>(),
            audioPlayer: ctx.read<AudioPlayerService>(),
          )),
          BlocProvider(create: (ctx) => MoodBloc(
            sensorService: ctx.read<SensorService>(),
            aiService: ctx.read<AIRecommendationService>(),
          )),
        ],
        child: MaterialApp(
          title: 'Mazj',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0A0A0F),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF4D6D),
              secondary: Color(0xFF4CC9F0),
              surface: Color(0xFF13131F),
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
