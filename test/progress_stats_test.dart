import 'package:fitforge/core/utils/progress_stats.dart';
import 'package:fitforge/models/profile.dart';
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

  PersonalRecord pr({
    required String id,
    required DateTime achievedAt,
  }) {
    return PersonalRecord(
      id: id,
      exerciseId: 'ex1',
      exerciseName: 'Bench',
      achievedAt: achievedAt,
    );
  }

  test('counts workouts and volume for the current calendar month', () {
    final now = DateTime(2025, 7, 15);
    final workouts = [
      workout(id: 'w1', completedAt: DateTime(2025, 7, 2), volume: 1200),
      workout(id: 'w2', completedAt: DateTime(2025, 7, 2, 18), volume: 800),
      workout(id: 'w3', completedAt: DateTime(2025, 6, 30), volume: 5000),
    ];

    expect(ProgressStatsCalculator.workoutsThisMonth(workouts, now), 2);
    expect(ProgressStatsCalculator.volumeThisMonth(workouts, now), 2000);
  });

  test('counts PRs achieved in the current calendar month', () {
    final now = DateTime(2025, 7, 15);
    final records = [
      pr(id: 'p1', achievedAt: DateTime(2025, 7, 1)),
      pr(id: 'p2', achievedAt: DateTime(2025, 7, 12)),
      pr(id: 'p3', achievedAt: DateTime(2025, 5, 1)),
    ];

    expect(ProgressStatsCalculator.prsThisMonth(records, now), 2);
  });
}
