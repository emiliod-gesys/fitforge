import '../../models/exercise_logging.dart';
import '../../models/workout.dart';

abstract final class WorkoutXpUtils {
  /// Distancia de cardio completada (runner outdoor / cinta).
  static double? completedRunDistanceMeters(Workout workout) {
    for (final ex in workout.exercises) {
      for (final set in ex.sets) {
        if (set.completed &&
            set.loggingType == ExerciseLoggingType.cardio &&
            set.distanceMeters != null &&
            set.distanceMeters! > 0) {
          return set.distanceMeters;
        }
      }
    }
    return null;
  }
}
