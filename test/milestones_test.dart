import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge/core/utils/milestones.dart';
import 'package:fitforge/models/exercise_logging.dart';
import 'package:fitforge/models/workout.dart';

void main() {
  test('computeTotals suma reps, volumen, distancia y entrenos', () {
    final workout = Workout(
      id: '1',
      userId: 'u',
      name: 'Mix',
      startedAt: DateTime(2026, 1, 1),
      completedAt: DateTime(2026, 1, 1),
      durationMinutes: 60,
      totalVolume: 4000,
      exercises: [
        WorkoutExercise(
          id: 'e1',
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          orderIndex: 0,
          sets: [
            const WorkoutSet(id: 's1', setNumber: 1, weight: 100, reps: 10, completed: true),
            const WorkoutSet(id: 's2', setNumber: 2, weight: 100, reps: 8, completed: true),
          ],
        ),
        WorkoutExercise(
          id: 'e2',
          exerciseId: 'run',
          exerciseName: 'Treadmill',
          orderIndex: 1,
          sets: [
            WorkoutSet(
              id: 's3',
              setNumber: 1,
              completed: true,
              loggingType: ExerciseLoggingType.cardio,
              distanceMeters: 3000,
              durationSeconds: 1200,
            ),
          ],
        ),
      ],
    );

    final totals = MilestonesCalculator.computeTotals([workout]);

    expect(totals.totalReps, 18);
    expect(totals.totalVolumeKg, 4000);
    expect(totals.totalDistanceMeters, 3000);
    expect(totals.totalWorkouts, 1);
    expect(totals.totalCalories, greaterThan(0));
  });

  test('entriesFor desbloquea hitos alcanzados', () {
    const totals = MilestoneTotals(
      totalReps: 0,
      totalVolumeKg: 0,
      totalDistanceMeters: 0,
      totalCalories: 0,
      totalWorkouts: 12,
    );

    final entries = MilestonesCalculator.entriesFor(MilestoneCategory.workouts, totals);

    expect(entries[0].unlocked, isTrue);
    expect(entries[1].unlocked, isTrue);
    expect(entries[2].unlocked, isTrue);
    expect(entries[3].unlocked, isFalse);
    expect(MilestonesCalculator.nextDefinition(MilestoneCategory.workouts, totals)?.threshold, 25);
    expect(MilestonesCalculator.currentTier(MilestoneCategory.workouts, totals), 3);
    expect(MilestonesCalculator.remainingToNext(MilestoneCategory.workouts, totals), 13);
  });

  test('fromFriendData parsea totales del RPC', () {
    final totals = MilestonesCalculator.fromFriendData({
      'workouts': [
        {
          'duration_minutes': 45,
          'total_volume': 3000,
          'completed_at': '2026-01-01T10:00:00Z',
        },
        {
          'duration_minutes': 30,
          'total_volume': 2000,
          'completed_at': '2026-01-02T10:00:00Z',
        },
      ],
      'total_reps': 500,
      'total_distance_meters': 1500,
    });

    expect(totals.totalWorkouts, 2);
    expect(totals.totalVolumeKg, 5000);
    expect(totals.totalReps, 500);
    expect(totals.totalDistanceMeters, 1500);
    expect(totals.totalCalories, greaterThan(0));
  });

  test('newlyUnlocked detecta medallas nuevas', () {
    const before = MilestoneTotals(
      totalReps: 90,
      totalVolumeKg: 0,
      totalDistanceMeters: 0,
      totalCalories: 0,
      totalWorkouts: 0,
    );
    const after = MilestoneTotals(
      totalReps: 150,
      totalVolumeKg: 0,
      totalDistanceMeters: 0,
      totalCalories: 0,
      totalWorkouts: 1,
    );

    final unlocks = MilestonesCalculator.newlyUnlocked(before, after);

    expect(unlocks.any((u) => u.category == MilestoneCategory.reps && u.tier == 1), isTrue);
    expect(unlocks.any((u) => u.category == MilestoneCategory.workouts && u.tier == 1), isTrue);
  });
}
