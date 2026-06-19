import '../../models/workout.dart';
import 'workout_day_utils.dart';

/// Meta semanal y cálculo de racha (lunes–domingo, mínimo 4 días con entreno).
abstract final class WorkoutStreakCalculator {
  static const weeklyGoal = 4;

  static DateTime startOfWeek(DateTime date) {
    final local = date.toLocal();
    final midnight = DateTime(local.year, local.month, local.day);
    return midnight.subtract(Duration(days: local.weekday - DateTime.monday));
  }

  static int countInWeek(Iterable<DateTime> completedAt, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return WorkoutDayUtils.uniqueDayCount(
      completedAt.where((t) {
        final local = t.toLocal();
        return !local.isBefore(weekStart) && local.isBefore(weekEnd);
      }),
    );
  }

  static int currentWeekCount(Iterable<DateTime> completedAt, [DateTime? now]) {
    return countInWeek(completedAt, startOfWeek(now ?? DateTime.now()));
  }

  /// Semanas consecutivas (hacia atrás) con al menos [weeklyGoal] entrenos.
  /// La semana en curso solo suma si ya alcanzó la meta; si no, no rompe la racha.
  static int weeklyStreak(Iterable<DateTime> completedAt, [DateTime? now]) {
    final dates = completedAt.toList();
    if (dates.isEmpty) return 0;

    final reference = now ?? DateTime.now();
    var weekStart = startOfWeek(reference);
    var streak = 0;

    final currentCount = countInWeek(dates, weekStart);
    if (currentCount >= weeklyGoal) {
      streak++;
      weekStart = weekStart.subtract(const Duration(days: 7));
    } else {
      weekStart = weekStart.subtract(const Duration(days: 7));
    }

    while (true) {
      if (countInWeek(dates, weekStart) >= weeklyGoal) {
        streak++;
        weekStart = weekStart.subtract(const Duration(days: 7));
      } else {
        break;
      }
    }

    return streak;
  }

  static WorkoutWeeklyStats fromWorkouts(List<Workout> workouts, [DateTime? now]) {
    final dates = workouts
        .where((w) => w.completedAt != null)
        .map((w) => w.completedAt!)
        .toList();
    return fromCompletedDates(dates, now);
  }

  static WorkoutWeeklyStats fromCompletedDates(Iterable<DateTime> completedAt, [DateTime? now]) {
    final count = currentWeekCount(completedAt, now);
    final streak = weeklyStreak(completedAt, now);
    return WorkoutWeeklyStats(
      currentWeekCount: count,
      weeklyGoal: weeklyGoal,
      streakWeeks: streak,
    );
  }
}

class WorkoutWeeklyStats {
  final int currentWeekCount;
  final int weeklyGoal;
  final int streakWeeks;

  const WorkoutWeeklyStats({
    required this.currentWeekCount,
    required this.weeklyGoal,
    required this.streakWeeks,
  });

  String get streakLabel {
    if (streakWeeks == 0) return '0 semanas';
    if (streakWeeks == 1) return '1 semana';
    return '$streakWeeks semanas';
  }

  String get weekProgressLabel => '$currentWeekCount/$weeklyGoal';

  bool get metGoalThisWeek => currentWeekCount >= weeklyGoal;
}
