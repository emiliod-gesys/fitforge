import '../../models/workout.dart';

abstract final class PreviousSetUtils {
  static List<WorkoutSet> sortedBySetNumber(List<WorkoutSet> sets) {
    final sorted = [...sets]..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    return sorted;
  }

  static int resolveSetCount({
    required int templateCount,
    List<WorkoutSet>? previous,
  }) {
    if (previous == null || previous.isEmpty) return templateCount;
    return sortedBySetNumber(previous).length;
  }

  static List<WorkoutSet> sortedMeaningfulSets(List<WorkoutSet> sets) {
    final completed = sets.where((s) => s.completed).toList();
    // Sin series completadas, solo cuentan las que tienen datos reales
    // (las series pre-rellenadas de plantilla llevan reps pero nada más).
    final source = completed.isNotEmpty ? completed : sets.where(hasLoggedData).toList();
    final meaningful =
        source.where((s) => s.weight != null || s.reps > 0 || s.durationSeconds != null).toList();
    meaningful.sort((a, b) => a.setNumber.compareTo(b.setNumber));
    return meaningful;
  }

  static bool hasLoggedData(WorkoutSet s) =>
      (s.weight ?? 0) > 0 ||
      (s.durationSeconds ?? 0) > 0 ||
      (s.distanceMeters ?? 0) > 0 ||
      (s.steps ?? 0) > 0;

  static WorkoutSet? forSetNumber(List<WorkoutSet> previous, int setNumber) {
    if (previous.isEmpty || setNumber < 1) return null;

    for (final set in previous) {
      if (set.setNumber == setNumber) return set;
    }

    final sorted = [...previous]..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    if (setNumber <= sorted.length) return sorted[setNumber - 1];
    return sorted.last;
  }
}
