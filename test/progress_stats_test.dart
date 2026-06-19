import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge/core/utils/progress_stats.dart';
import 'package:fitforge/models/workout.dart';

void main() {
  test('agrupa entrenos de 7 días e histórico', () {
    final now = DateTime.now();
    final workouts = [
      Workout(
        id: '1',
        userId: 'u',
        name: 'A',
        startedAt: now.subtract(const Duration(days: 2)),
        completedAt: now.subtract(const Duration(days: 2)),
        durationMinutes: 45,
        totalVolume: 3000,
      ),
      Workout(
        id: '2',
        userId: 'u',
        name: 'B',
        startedAt: now.subtract(const Duration(days: 20)),
        completedAt: now.subtract(const Duration(days: 20)),
        durationMinutes: 50,
        totalVolume: 5000,
      ),
    ];

    final stats = ProgressStatsCalculator.compute(workouts);

    expect(stats.workouts7d, 1);
    expect(stats.volume7dKg, 3000);
    expect(stats.calories7d, greaterThan(0));
    expect(stats.workoutsTotal, 2);
    expect(stats.volumeTotalKg, 8000);
    expect(stats.caloriesTotal, greaterThan(stats.calories7d));
  });

  test('volumeByDayLastDays suma entrenamientos del mismo día y rellena la ventana', () {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final workouts = [
      Workout(
        id: '1',
        userId: 'u',
        name: 'A',
        startedAt: dayStart,
        completedAt: dayStart,
        durationMinutes: 45,
        totalVolume: 3000,
      ),
      Workout(
        id: '2',
        userId: 'u',
        name: 'B',
        startedAt: dayStart.add(const Duration(hours: 2)),
        completedAt: dayStart.add(const Duration(hours: 2)),
        durationMinutes: 30,
        totalVolume: 2000,
      ),
    ];

    final daily = ProgressStatsCalculator.volumeByDayLastDays(
      workouts,
      dayCount: 3,
    );

    expect(daily.length, 3);
    expect(daily.last.volumeKg, 5000);
    expect(daily.where((d) => d.volumeKg == 0).length, 2);
  });
}
