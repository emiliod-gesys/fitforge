import '../../models/exercise.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../constants/app_constants.dart';
import 'exercise_load.dart';

/// Convierte un entrenamiento completado en ejercicios de plantilla de rutina.
abstract final class RoutineWorkoutSync {
  static bool hasSavableExercises(Workout workout) {
    return workout.exercises.any((ex) => ex.sets.any((s) => s.completed));
  }

  static List<RoutineExercise> routineExercisesFromWorkout(
    Workout workout, {
    Iterable<Exercise> catalog = const [],
  }) {
    final result = <RoutineExercise>[];
    var order = 0;

    final sorted = [...workout.exercises]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    for (final ex in sorted) {
      final completedSets = ex.sets.where((s) => s.completed).toList();
      if (completedSets.isEmpty) continue;

      final isCardio = completedSets.every((s) => s.isCardio);
      final lastSet = completedSets.last;

      if (isCardio) {
        result.add(
          RoutineExercise(
            id: '',
            exerciseId: ex.exerciseId,
            exerciseName: ex.exerciseName,
            orderIndex: order++,
            imageUrl: ex.imageUrl,
            loggingType: lastSet.loggingType,
            targetDurationSeconds: lastSet.durationSeconds,
            targetDistanceMeters: lastSet.distanceMeters,
            targetInclinePercent: lastSet.inclinePercent,
            targetSteps: lastSet.steps,
            targetSetDetails: List.generate(
              completedSets.length,
              (_) => const RoutineSetTarget(reps: 0),
            ),
            restSeconds: AppConstants.defaultRestSeconds,
          ).withSyncedLegacyFields(),
        );
        continue;
      }

      final setDetails = completedSets
          .map(
            (s) => RoutineSetTarget(
              reps: s.reps > 0 ? s.reps : AppConstants.defaultReps,
              weight: s.weight,
            ),
          )
          .toList();

      result.add(
        RoutineExercise(
          id: '',
          exerciseId: ex.exerciseId,
          exerciseName: ex.exerciseName,
          orderIndex: order++,
          imageUrl: ex.imageUrl,
          loggingType: lastSet.loggingType,
          perArmWeight: ExerciseLoad.perArmWeightForExerciseId(ex.exerciseId, catalog),
          targetSetDetails: setDetails,
          targetDistanceMeters: lastSet.distanceMeters,
          restSeconds: AppConstants.defaultRestSeconds,
        ).withSyncedLegacyFields(),
      );
    }

    return result;
  }

  static Routine routineFromWorkout(
    Workout workout, {
    Iterable<Exercise> catalog = const [],
    String? name,
    List<String>? targetMuscles,
  }) {
    return Routine(
      id: '',
      userId: '',
      name: name ?? workout.name,
      targetMuscles: targetMuscles ?? const [],
      exercises: routineExercisesFromWorkout(workout, catalog: catalog),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
