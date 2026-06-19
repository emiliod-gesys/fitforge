import '../../models/body_metric.dart';
import '../../models/profile.dart';
import '../../models/workout.dart';
import 'workout_calorie_estimator.dart';
import 'workout_day_utils.dart';

class DailyVolume {
  final DateTime date;
  final double volumeKg;

  const DailyVolume({required this.date, required this.volumeKg});
}

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
      workouts7d: WorkoutDayUtils.uniqueDayCountFromWorkouts(last7d),
      volume7dKg: _sumVolume(last7d),
      calories7d: _sumCalories(last7d, profile: profile, bodyMetrics: bodyMetrics),
      workoutsTotal: WorkoutDayUtils.uniqueDayCountFromWorkouts(completed),
      volumeTotalKg: _sumVolume(completed),
      caloriesTotal: _sumCalories(completed, profile: profile, bodyMetrics: bodyMetrics),
    );
  }

  static double _sumVolume(Iterable<Workout> workouts) {
    return workouts.fold<double>(0, (sum, w) => sum + w.totalVolume);
  }

  /// Suma el volumen por día dentro de una ventana fija de [dayCount] días (incluye hoy).
  static List<DailyVolume> volumeByDayLastDays(
    Iterable<Workout> workouts, {
    required int dayCount,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: dayCount - 1));

    final byDay = <DateTime, double>{
      for (var i = 0; i < dayCount; i++) start.add(Duration(days: i)): 0,
    };

    for (final workout in workouts) {
      final completed = workout.completedAt;
      if (completed == null) continue;
      final local = completed.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day.isBefore(start) || day.isAfter(today)) continue;
      byDay[day] = (byDay[day] ?? 0) + workout.totalVolume;
    }

    return byDay.entries
        .map((e) => DailyVolume(date: e.key, volumeKg: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
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
