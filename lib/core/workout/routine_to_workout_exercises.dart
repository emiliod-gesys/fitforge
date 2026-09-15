import '../../models/routine.dart';
import '../../models/workout.dart';

List<WorkoutExercise> workoutExercisesFromRoutine(Routine routine) {
  return routine.exercises
      .map(
        (e) => WorkoutExercise(
          id: '',
          exerciseId: e.exerciseId,
          exerciseName: e.exerciseName,
          imageUrl: e.imageUrl,
          orderIndex: e.orderIndex,
          supersetGroupId: e.supersetGroupId,
          supersetSlot: e.supersetSlot,
          sets: e.resolvedSetDetails
              .asMap()
              .entries
              .map(
                (entry) => WorkoutSet(
                  id: '',
                  setNumber: entry.key + 1,
                  weight: e.isCardio ? null : entry.value.weight,
                  reps: e.isCardio ? 0 : entry.value.reps,
                  loggingType: e.loggingType,
                  durationSeconds: e.targetDurationSeconds,
                  distanceMeters: e.targetDistanceMeters,
                  inclinePercent: e.targetInclinePercent,
                  steps: e.targetSteps,
                ),
              )
              .toList(),
        ),
      )
      .toList();
}
