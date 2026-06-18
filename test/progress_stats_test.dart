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
}
