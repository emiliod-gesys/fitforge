import 'package:fitforge/core/utils/progress_weekly_volume.dart';
import 'package:fitforge/core/utils/workout_streak.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Workout workout({
    required String id,
    required DateTime completedAt,
    double volume = 1000,
  }) {
    return Workout(
      id: id,
      userId: 'u1',
      name: 'Session',
      startedAt: completedAt.subtract(const Duration(hours: 1)),
      completedAt: completedAt,
      totalVolume: volume,
    );
  }

  test('sums volume for workouts in the current week bucket', () {
    final now = DateTime(2025, 7, 2, 12);
    final weekStart = WorkoutStreakCalculator.startOfWeek(now);
    final workouts = [
      workout(id: 'w1', completedAt: weekStart.add(const Duration(days: 1)), volume: 1500),
      workout(id: 'w2', completedAt: weekStart.subtract(const Duration(days: 1)), volume: 9000),
    ];

    final volume = ProgressWeeklyVolume.currentWeekVolume(workouts, now);
    expect(volume, 1500);
  });

  test('builds eight weekly buckets oldest to newest', () {
    final now = DateTime(2025, 7, 2);
    final buckets = ProgressWeeklyVolume.buckets(const [], weeks: 8, now: now);

    expect(buckets.length, 8);
    expect(
      buckets.first.weekStart.isBefore(buckets.last.weekStart),
      isTrue,
    );
  });
}
