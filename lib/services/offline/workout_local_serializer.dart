import '../../models/workout.dart';

/// Serialización completa de entrenamientos para almacenamiento local.
abstract final class WorkoutLocalSerializer {
  static Map<String, dynamic> toJson(Workout workout, {bool pendingSync = false}) {
    return {
      ...workout.toJson(),
      'id': workout.id,
      'user_id': workout.userId,
      if (workout.routineName != null) 'routine_name': workout.routineName,
      'exercises': workout.exercises.map(_exerciseToJson).toList(),
      'pending_sync': pendingSync,
      if (workout.runnerSurface != null) 'runner_surface': workout.runnerSurface!.code,
      'runner_route': workout.runnerRoute.map((p) => p.toJson()).toList(),
      'runner_splits': workout.runnerSplits.map((s) => s.toJson()).toList(),
      if (workout.runnerAvgPaceSecPerKm != null)
        'runner_avg_pace_sec_per_km': workout.runnerAvgPaceSecPerKm,
      if (workout.runnerElevationGainMeters != null)
        'runner_elevation_gain_m': workout.runnerElevationGainMeters,
      if (workout.runnerElevationLossMeters != null)
        'runner_elevation_loss_m': workout.runnerElevationLossMeters,
    };
  }

  static Workout fromJson(Map<String, dynamic> json) {
    final exercisesRaw = json['exercises'] as List? ?? [];
    final exercises = exercisesRaw
        .whereType<Map>()
        .map((e) => _exerciseFromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Workout.fromJson(json, exercises: exercises);
  }

  static Map<String, dynamic> _exerciseToJson(WorkoutExercise exercise) {
    return {
      'id': exercise.id,
      'exercise_id': exercise.exerciseId,
      'exercise_name': exercise.exerciseName,
      'image_url': exercise.imageUrl,
      'order_index': exercise.orderIndex,
      'notes': exercise.notes,
      'workout_sets': exercise.sets.map((set) {
        return {
          'id': set.id,
          ...set.toJson(),
        };
      }).toList(),
    };
  }

  static WorkoutExercise _exerciseFromJson(Map<String, dynamic> json) {
    final setsRaw = json['workout_sets'] as List? ?? [];
    final sets = setsRaw
        .whereType<Map>()
        .map((s) => WorkoutSet.fromJson(Map<String, dynamic>.from(s)))
        .toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

    return WorkoutExercise.fromJson(json, sets: sets);
  }
}
