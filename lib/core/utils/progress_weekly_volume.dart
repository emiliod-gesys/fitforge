import '../../models/workout.dart';
import 'workout_streak.dart';

class WeeklyVolumeBucket {
  final DateTime weekStart;
  final double volumeKg;
  final int workoutCount;

  const WeeklyVolumeBucket({
    required this.weekStart,
    required this.volumeKg,
    required this.workoutCount,
  });
}

abstract final class ProgressWeeklyVolume {
  static List<WeeklyVolumeBucket> buckets(
    List<Workout> workouts, {
    int weeks = 8,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final currentWeekStart = WorkoutStreakCalculator.startOfWeek(reference);
    final buckets = <WeeklyVolumeBucket>[];

    for (var i = weeks - 1; i >= 0; i--) {
      final weekStart = currentWeekStart.subtract(Duration(days: 7 * i));
      final weekEnd = weekStart.add(const Duration(days: 7));
      var volume = 0.0;
      var count = 0;

      for (final workout in workouts) {
        final completedAt = workout.completedAt;
        if (completedAt == null) continue;
        final local = completedAt.toLocal();
        if (!local.isBefore(weekStart) && local.isBefore(weekEnd)) {
          volume += workout.totalVolume;
          count++;
        }
      }

      buckets.add(
        WeeklyVolumeBucket(
          weekStart: weekStart,
          volumeKg: volume,
          workoutCount: count,
        ),
      );
    }

    return buckets;
  }

  static double currentWeekVolume(List<Workout> workouts, [DateTime? now]) {
    final bucket = buckets(workouts, weeks: 1, now: now).firstOrNull;
    return bucket?.volumeKg ?? 0;
  }
}
