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
    final source = completed.isNotEmpty ? completed : sets;
    final meaningful =
        source.where((s) => s.weight != null || s.reps > 0 || s.durationSeconds != null).toList();
    meaningful.sort((a, b) => a.setNumber.compareTo(b.setNumber));
    return meaningful;
  }

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
