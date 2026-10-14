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
            supersetGroupId: ex.supersetGroupId,
            supersetSlot: ex.supersetSlot,
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
          perArmWeight: ExerciseLoad.resolvePerArmWeight(
            exerciseId: ex.exerciseId,
            catalog: catalog,
            exerciseName: ex.exerciseName,
          ),
          targetSetDetails: setDetails,
          targetDistanceMeters: lastSet.distanceMeters,
          restSeconds: AppConstants.defaultRestSeconds,
          supersetGroupId: ex.supersetGroupId,
          supersetSlot: ex.supersetSlot,
        ).withSyncedLegacyFields(),
      );
    }

    return result;
  }

  /// Copia a la rutina solo cambios de estructura: un ejercicio sustituido
  /// por otro en el mismo lugar, o ejercicios nuevos con series hechas.
  /// Pesos, series y reps de los ejercicios que ya estaban no se tocan.
  /// Devuelve null si la rutina no cambia.
  static List<RoutineExercise>? applyStructuralEdits({
    required List<RoutineExercise> routineExercises,
    required Workout workout,
    Iterable<Exercise> catalog = const [],
  }) {
    final routine = [...routineExercises]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final session = [...workout.exercises]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final sessionIds = session.map((e) => e.exerciseId).toSet();
    final routineIds = routine.map((e) => e.exerciseId).toSet();

    final replacements = <int, WorkoutExercise>{};
    final additions = <WorkoutExercise>[];

    for (final performed in session) {
      if (!performed.sets.any((s) => s.completed)) continue;
      if (routineIds.contains(performed.exerciseId)) continue;

      final slot = routine.indexWhere(
        (exercise) =>
            exercise.orderIndex == performed.orderIndex &&
            !sessionIds.contains(exercise.exerciseId) &&
            !replacements.containsKey(routine.indexOf(exercise)),
      );
      if (slot >= 0) {
        replacements[slot] = performed;
      } else {
        additions.add(performed);
      }
    }

    if (replacements.isEmpty && additions.isEmpty) return null;

    final result = <RoutineExercise>[];
    for (var i = 0; i < routine.length; i++) {
      final replacement = replacements[i];
      if (replacement == null) {
        result.add(routine[i]);
      } else {
        result.add(
          _exerciseFromSession(
            replacement,
            slot: routine[i],
            catalog: catalog,
          ),
        );
      }
    }

    for (final added in additions) {
      var insertAt = result.length;
      final at = session.indexOf(added);
      for (var k = at + 1; k < session.length; k++) {
        final idx = result.indexWhere(
          (exercise) => exercise.exerciseId == session[k].exerciseId,
        );
        if (idx >= 0) {
          insertAt = idx;
          break;
        }
      }
      result.insert(
        insertAt,
        _exerciseFromSession(added, catalog: catalog),
      );
    }

    return [
      for (var i = 0; i < result.length; i++)
        result[i].copyWith(orderIndex: i),
    ];
  }

  static RoutineExercise _exerciseFromSession(
    WorkoutExercise session, {
    RoutineExercise? slot,
    required Iterable<Exercise> catalog,
  }) {
    final built = routineExercisesFromWorkout(
      Workout(
        id: '',
        userId: '',
        name: '',
        startedAt: DateTime.now(),
        exercises: [session],
      ),
      catalog: catalog,
    ).first;
    if (slot == null) return built;
    return built.copyWith(
      restSeconds: slot.restSeconds,
      supersetGroupId: slot.supersetGroupId,
      supersetSlot: slot.supersetSlot,
      clearSuperset: slot.supersetGroupId == null,
    );
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
