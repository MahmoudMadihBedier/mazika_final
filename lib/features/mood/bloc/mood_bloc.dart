import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/listening_history_model.dart';
import '../../../core/services/sensor_service.dart';
import '../../../core/services/ai_recommendation_service.dart';

abstract class MoodEvent extends Equatable {
  const MoodEvent();
  @override List<Object?> get props => [];
}

class MoodOverrideRequested extends MoodEvent {
  final MoodType mood;
  const MoodOverrideRequested(this.mood);
  @override List<Object?> get props => [mood];
}

class MoodOverrideCleared extends MoodEvent {}

class MoodState extends Equatable {
  final bool isOverridden;
  final Map<String, dynamic> insights;
  const MoodState({this.isOverridden = false, this.insights = const {}});
  MoodState copyWith({bool? isOverridden, Map<String, dynamic>? insights}) =>
      MoodState(isOverridden: isOverridden ?? this.isOverridden, insights: insights ?? this.insights);
  @override List<Object?> get props => [isOverridden];
}

class MoodBloc extends Bloc<MoodEvent, MoodState> {
  final SensorService sensorService;
  final AIRecommendationService aiService;

  MoodBloc({required this.sensorService, required this.aiService}) : super(const MoodState()) {
    on<MoodOverrideRequested>((e, emit) {
      sensorService.overrideMood(e.mood);
      emit(state.copyWith(isOverridden: true, insights: aiService.getInsights()));
    });
    on<MoodOverrideCleared>((e, emit) {
      sensorService.clearMoodOverride();
      emit(state.copyWith(isOverridden: false));
    });
  }
}
