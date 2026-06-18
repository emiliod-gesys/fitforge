import '../../models/body_metric.dart';
import '../../models/profile.dart';
import '../../models/workout.dart';
import 'workout_calorie_estimator.dart';

class ProgressStats {
  final int workouts7d;
  final double volume7dKg;
  final int calories7d;
  final int workoutsTotal;
  final double volumeTotalKg;
  final int caloriesTotal;

  const ProgressStats({
    required this.workouts7d,
    required this.volume7dKg,
    required this.calories7d,
    required this.workoutsTotal,
    required this.volumeTotalKg,
    required this.caloriesTotal,
  });

  static const empty = ProgressStats(
    workouts7d: 0,
    volume7dKg: 0,
    calories7d: 0,
    workoutsTotal: 0,
    volumeTotalKg: 0,
    caloriesTotal: 0,
  );
}

abstract final class ProgressStatsCalculator {
  static ProgressStats compute(
    List<Workout> workouts, {
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
  }) {
    final completed = workouts.where((w) => w.completedAt != null).toList();
    if (completed.isEmpty) return ProgressStats.empty;

    final cutoff7d = DateTime.now().subtract(const Duration(days: 7));
    final last7d = completed.where((w) => w.completedAt!.isAfter(cutoff7d));

    return ProgressStats(
      workouts7d: last7d.length,
      volume7dKg: _sumVolume(last7d),
      calories7d: _sumCalories(last7d, profile: profile, bodyMetrics: bodyMetrics),
      workoutsTotal: completed.length,
      volumeTotalKg: _sumVolume(completed),
      caloriesTotal: _sumCalories(completed, profile: profile, bodyMetrics: bodyMetrics),
    );
  }

  static double _sumVolume(Iterable<Workout> workouts) {
    return workouts.fold<double>(0, (sum, w) => sum + w.totalVolume);
  }

  static int _sumCalories(
    Iterable<Workout> workouts, {
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
  }) {
    return workouts.fold<int>(0, (sum, w) {
      final estimate = WorkoutCalorieEstimator.estimateFromSummary(
        durationMinutes: w.durationMinutes,
        totalVolumeKg: w.totalVolume,
        profile: profile,
        bodyMetrics: bodyMetrics,
      );
      return sum + (estimate.caloriesKcal ?? 0);
    });
  }
}
