import '../../models/exercise.dart';
import '../../models/workout.dart';
import '../constants/app_constants.dart';
import 'muscle_inference.dart';

List<String> trainedMuscleGroupsForWorkout(Workout workout, List<Exercise> catalog) {
  final groups = <String>{};
  for (final exercise in workout.exercises) {
    if (!exercise.sets.any((set) => set.completed)) continue;
    groups.addAll(
      MuscleInference.resolve(
        exerciseName: exercise.exerciseName,
        exerciseId: exercise.exerciseId,
        catalog: catalog,
      ),
    );
  }

  final order = AppConstants.muscleGroups;
  final sorted = groups.toList()
    ..sort((a, b) {
      final ai = order.indexOf(a);
      final bi = order.indexOf(b);
      return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
    });
  return sorted;
}
