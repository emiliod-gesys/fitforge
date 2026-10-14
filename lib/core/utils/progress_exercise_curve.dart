import '../../models/exercise_history.dart';
import '../../models/workout.dart';
import 'exercise_history_utils.dart';
import 'previous_set_utils.dart';

/// Un punto de la curva: el peso de trabajo de esa sesión, con sus reps y RIR.
class ExerciseCurvePoint {
  final DateTime date;
  final double weightKg;
  final int reps;
  final int? rir;

  const ExerciseCurvePoint({
    required this.date,
    required this.weightKg,
    required this.reps,
    this.rir,
  });
}

/// Ejercicio que el usuario ya registró, del más reciente al más antiguo.
class LoggedExerciseRef {
  final String id;
  final String name;

  const LoggedExerciseRef({required this.id, required this.name});
}

abstract final class ProgressExerciseCurve {
  /// Una sesión, un punto. Usa la última serie al peso de trabajo para el RIR.
  static List<ExerciseCurvePoint> fromSessions(List<ExerciseSessionHistory> sessions) {
    final points = <ExerciseCurvePoint>[];
    for (final session in sessions) {
      final point = _pointFor(session);
      if (point != null) points.add(point);
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  static ExerciseCurvePoint? _pointFor(ExerciseSessionHistory session) {
    final working = ExerciseHistoryUtils.workingSets(session.sets);
    final source = working.isNotEmpty
        ? working
        : PreviousSetUtils.sortedMeaningfulSets(session.sets);
    if (source.isEmpty) return null;

    final ordered = [...source]..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    final heaviest = ordered.fold<double>(0, (best, set) => (set.weight ?? 0) > best ? set.weight! : best);

    WorkoutSet? chosen;
    for (final set in ordered) {
      if (heaviest > 0 && (set.weight ?? 0) < heaviest) continue;
      chosen = set;
    }
    final set = chosen;
    if (set == null) return null;
    if ((set.weight ?? 0) <= 0 && set.reps <= 0) return null;

    return ExerciseCurvePoint(
      date: session.date,
      weightKg: set.weight ?? 0,
      reps: set.reps,
      rir: set.rir,
    );
  }
}
