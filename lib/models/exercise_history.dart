import 'workout.dart';

/// Una sesión pasada de un ejercicio concreto dentro de un entrenamiento.
class ExerciseSessionHistory {
  final String workoutId;
  final String workoutName;
  final DateTime date;
  final List<WorkoutSet> sets;
  /// Nombre con el que se guardó el ejercicio en esa sesión (puede diferir del actual).
  final String? loggedExerciseName;

  const ExerciseSessionHistory({
    required this.workoutId,
    required this.workoutName,
    required this.date,
    required this.sets,
    this.loggedExerciseName,
  });
}

/// Clave para consultar historial sin incluir el entrenamiento activo.
class ExerciseHistoryQuery {
  final String exerciseId;
  final String? excludeWorkoutId;

  const ExerciseHistoryQuery({
    required this.exerciseId,
    this.excludeWorkoutId,
  });

  @override
  bool operator ==(Object other) =>
      other is ExerciseHistoryQuery &&
      exerciseId == other.exerciseId &&
      excludeWorkoutId == other.excludeWorkoutId;

  @override
  int get hashCode => Object.hash(exerciseId, excludeWorkoutId);
}
