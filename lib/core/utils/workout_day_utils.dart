import '../../models/workout.dart';

/// Agrupa entrenos completados por día calendario local (medianoche a medianoche).
abstract final class WorkoutDayUtils {
  static DateTime localDay(DateTime dateTime) {
    final local = dateTime.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static Set<DateTime> uniqueLocalDays(Iterable<DateTime> timestamps) {
    return timestamps.map(localDay).toSet();
  }

  static int uniqueDayCount(Iterable<DateTime> timestamps) {
    return uniqueLocalDays(timestamps).length;
  }

  static int uniqueDayCountFromWorkouts(Iterable<Workout> workouts) {
    return uniqueDayCount(
      workouts.where((w) => w.completedAt != null).map((w) => w.completedAt!),
    );
  }
}
