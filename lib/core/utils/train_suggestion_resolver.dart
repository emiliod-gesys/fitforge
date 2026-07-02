import '../../models/exercise.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import 'muscle_inference.dart';

enum TrainSuggestionReason { lastRoutine, recovery, defaultPick }

class TrainSuggestion {
  final Routine routine;
  final TrainSuggestionReason reason;

  const TrainSuggestion({
    required this.routine,
    required this.reason,
  });
}

/// Elige la rutina más adecuada para el bloque "Siguiente entreno sugerido".
abstract final class TrainSuggestionResolver {
  static const _recoveryThreshold = 70.0;

  static TrainSuggestion? resolve({
    required List<Routine> routines,
    required List<Workout> recentWorkouts,
    required Map<String, double> recovery,
    List<Exercise> catalog = const [],
  }) {
    if (routines.isEmpty) return null;

    for (final workout in recentWorkouts) {
      final routineId = workout.routineId;
      if (routineId == null) continue;
      final match = _findRoutine(routines, routineId);
      if (match != null) {
        return TrainSuggestion(routine: match, reason: TrainSuggestionReason.lastRoutine);
      }
    }

    Routine? bestRoutine;
    var bestScore = -1.0;
    for (final routine in routines) {
      final score = _averageRecoveryForRoutine(routine, recovery, catalog);
      if (score > bestScore) {
        bestScore = score;
        bestRoutine = routine;
      }
    }

    if (bestRoutine != null && bestScore >= _recoveryThreshold) {
      return TrainSuggestion(routine: bestRoutine, reason: TrainSuggestionReason.recovery);
    }

    return TrainSuggestion(
      routine: routines.first,
      reason: TrainSuggestionReason.defaultPick,
    );
  }

  static Routine? _findRoutine(List<Routine> routines, String id) {
    for (final routine in routines) {
      if (routine.id == id) return routine;
    }
    return null;
  }

  static double _averageRecoveryForRoutine(
    Routine routine,
    Map<String, double> recovery,
    List<Exercise> catalog,
  ) {
    final muscles = _routineMuscleGroups(routine, catalog);
    if (muscles.isEmpty) return 0;

    var total = 0.0;
    for (final muscle in muscles) {
      total += recovery[muscle] ?? 100;
    }
    return total / muscles.length;
  }

  static Set<String> _routineMuscleGroups(Routine routine, List<Exercise> catalog) {
    final muscles = <String>{...routine.targetMuscles};
    for (final exercise in routine.exercises) {
      muscles.addAll(
        MuscleInference.resolve(
          exerciseName: exercise.exerciseName,
          exerciseId: exercise.exerciseId,
          catalog: catalog,
        ),
      );
    }
    return muscles;
  }
}
