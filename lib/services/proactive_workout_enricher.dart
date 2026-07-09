import '../core/subscription/subscription_features.dart';
import '../core/utils/workout_suggestion_context.dart';
import '../models/exercise.dart';
import '../models/exercise_history.dart';
import '../models/profile.dart';
import '../models/workout.dart';
import 'ai_coach_service.dart';
import 'workout_service.dart';

/// Enriquece ejercicios con sugerencias de IA proactiva al iniciar un entrenamiento.
class ProactiveWorkoutEnricher {
  ProactiveWorkoutEnricher({
    required WorkoutService workoutService,
    required AiCoachService aiCoach,
  })  : _workoutService = workoutService,
        _aiCoach = aiCoach;

  final WorkoutService _workoutService;
  final AiCoachService _aiCoach;

  /// Devuelve ejercicios enriquecidos. Si la IA falla, devuelve los originales.
  Future<({List<WorkoutExercise> exercises, bool aiApplied})> enrich({
    required List<WorkoutExercise> exercises,
    required UserProfile profile,
    required Map<String, double> muscleRecovery,
    required List<Exercise> catalog,
    required String excludeWorkoutId,
  }) async {
    if (exercises.isEmpty) {
      return (exercises: exercises, aiApplied: false);
    }
    if (!profile.subscriptionTier.hasProactiveAi) {
      return (exercises: exercises, aiApplied: false);
    }
    if (!profile.hasAiKey) {
      return (exercises: exercises, aiApplied: false);
    }

    final historyByExerciseId = <String, List<ExerciseSessionHistory>>{};
    for (final ex in exercises) {
      historyByExerciseId[ex.exerciseId] = await _workoutService.getExerciseHistory(
        ex.exerciseId,
        limit: WorkoutSuggestionContextBuilder.historyLimit,
        excludeWorkoutId: excludeWorkoutId,
      );
    }

    final context = WorkoutSuggestionContextBuilder.build(
      exercises: exercises,
      profile: profile,
      muscleRecovery: muscleRecovery,
      catalog: catalog,
      historyByExerciseId: historyByExerciseId,
    );

    final payload = WorkoutSuggestionContextBuilder.payloadJson(
      profile: profile,
      exercises: context,
    );

    final suggestions = await _aiCoach.suggestWorkoutSets(
      profile: profile,
      payloadJson: payload,
    );
    if (suggestions == null) {
      return (exercises: exercises, aiApplied: false);
    }

    final merged = AiWorkoutSuggestionsMerger.apply(
      exercises: exercises,
      suggestions: suggestions,
      unitSystem: profile.unitSystem,
    );

    final changed = _hasChanges(exercises, merged);
    return (exercises: merged, aiApplied: changed);
  }

  bool _hasChanges(List<WorkoutExercise> before, List<WorkoutExercise> after) {
    for (var i = 0; i < before.length; i++) {
      final a = before[i];
      final b = after[i];
      if (a.sets.length != b.sets.length) return true;
      for (var j = 0; j < a.sets.length; j++) {
        final sa = a.sets[j];
        final sb = b.sets[j];
        if (sa.weight != sb.weight ||
            sa.reps != sb.reps ||
            sa.durationSeconds != sb.durationSeconds ||
            sa.distanceMeters != sb.distanceMeters ||
            sa.inclinePercent != sb.inclinePercent ||
            sa.steps != sb.steps) {
          return true;
        }
      }
    }
    return false;
  }
}
