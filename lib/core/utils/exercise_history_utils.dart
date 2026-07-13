import '../../models/exercise_history.dart';
import '../../models/workout.dart';
import 'previous_set_utils.dart';

typedef WorkoutExerciseEntry = ({String weId, Map<String, dynamic> workout});

/// Utilidades para filtrar sesiones fantasma, deduplicar y analizar pesos.
abstract final class ExerciseHistoryUtils {
  /// Entrenos auto-cerrados al iniciar otro (duration=0, sin volumen).
  static bool isStaleGhostWorkout(Map<String, dynamic> workout) {
    final duration = workout['duration_minutes'] as int? ?? 0;
    final volume = (workout['total_volume'] as num?)?.toDouble() ?? 0;
    return duration == 0 && volume <= 0;
  }

  static double sessionHeaviestWeightKg(List<WorkoutSet> sets) {
    return sets
        .where((s) => (s.weight ?? 0) > 0)
        .fold<double>(0, (best, s) => s.weight! > best ? s.weight! : best);
  }

  static double sessionQualityScore(List<WorkoutSet> sets) {
    final meaningful = PreviousSetUtils.sortedMeaningfulSets(sets);
    var score = 0.0;
    for (final s in meaningful) {
      final w = s.weight ?? 0;
      if (w <= 0) continue;
      score += w * (s.reps > 0 ? s.reps : 1);
    }
    return score;
  }

  /// Series de trabajo (≥85% del peso máximo de la sesión).
  static List<WorkoutSet> workingSets(List<WorkoutSet> sets, {double threshold = 0.85}) {
    final heaviest = sessionHeaviestWeightKg(sets);
    if (heaviest <= 0) return const [];
    final min = heaviest * threshold;
    return sets.where((s) => (s.weight ?? 0) >= min).toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
  }

  static String weightPattern(List<WorkoutSet> sets) {
    final weighted = sets.where((s) => (s.weight ?? 0) > 0).toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    if (weighted.length < 2) return 'constant';

    final weights = weighted.map((s) => s.weight!).toList();
    final min = weights.reduce((a, b) => a < b ? a : b);
    final max = weights.reduce((a, b) => a > b ? a : b);
    if (max <= 0) return 'unknown';

    if (min < max * 0.75) {
      var ascending = true;
      for (var i = 1; i < weighted.length; i++) {
        if ((weighted[i].weight ?? 0) < (weighted[i - 1].weight ?? 0) * 0.95) {
          ascending = false;
          break;
        }
      }
      if (ascending && min < max * 0.7) return 'warmup_then_work';
      if (weights.toSet().length > 2) return 'varied';
      return 'pyramid';
    }
    return 'constant';
  }

  static List<WorkoutExerciseEntry> dedupeEntriesByWorkout(
    List<WorkoutExerciseEntry> entries,
    Map<String, List<WorkoutSet>> setsByWeId,
  ) {
    final byWorkout = <String, List<WorkoutExerciseEntry>>{};
    for (final e in entries) {
      final wId = e.workout['id'] as String;
      byWorkout.putIfAbsent(wId, () => []).add(e);
    }

    final result = <WorkoutExerciseEntry>[];
    for (final group in byWorkout.values) {
      if (group.length == 1) {
        result.add(group.first);
        continue;
      }
      WorkoutExerciseEntry? best;
      var bestScore = -1.0;
      for (final e in group) {
        final sets = setsByWeId[e.weId] ?? const [];
        final score = sessionQualityScore(sets);
        if (score > bestScore) {
          bestScore = score;
          best = e;
        }
      }
      if (best != null) result.add(best);
    }
    return result;
  }

  /// Sesión representativa para anclar pesos (evita fantasmas con peso bajo).
  static ExerciseSessionHistory? anchoringSession(List<ExerciseSessionHistory> history) {
    if (history.isEmpty) return null;
    if (history.length == 1) return history.first;

    final recent = history.first;
    final recentHeaviest = sessionHeaviestWeightKg(recent.sets);
    final window = history.take(5).toList();

    ExerciseSessionHistory? best;
    var bestHeaviest = 0.0;
    for (final session in window) {
      final h = sessionHeaviestWeightKg(session.sets);
      if (h > bestHeaviest) {
        bestHeaviest = h;
        best = session;
      }
    }

    if (bestHeaviest > 0 && recentHeaviest < bestHeaviest * 0.75 && best != null) {
      return best;
    }
    return recent;
  }

  /// Sets a usar al pre-rellenar el siguiente entreno (omite aproximaciones obvias).
  static List<WorkoutSet> setsForNextWorkoutSuggestion(List<WorkoutSet> sets) {
    final meaningful = PreviousSetUtils.sortedMeaningfulSets(sets);
    if (meaningful.isEmpty) return meaningful;

    final pattern = weightPattern(meaningful);
    if (pattern == 'warmup_then_work' || pattern == 'varied' || pattern == 'pyramid') {
      final work = workingSets(meaningful);
      if (work.isNotEmpty) return work;
    }
    return meaningful;
  }
}
