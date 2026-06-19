import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge/core/utils/milestones.dart';
import 'package:fitforge/core/utils/progress_stats.dart';
import 'package:fitforge/core/utils/workout_day_utils.dart';
import 'package:fitforge/core/utils/workout_streak.dart';
import 'package:fitforge/models/workout.dart';

void main() {
  group('WorkoutDayUtils', () {
    test('agrupa varios entrenos del mismo dia calendario local', () {
      final day = DateTime(2026, 3, 10, 8);
      final timestamps = [
        day,
        day.add(const Duration(hours: 3)),
        day.add(const Duration(hours: 10)),
      ];

      expect(WorkoutDayUtils.uniqueDayCount(timestamps), 1);
    });
  });

  group('WorkoutStreakCalculator', () {
    test('cuenta dias unicos en la semana', () {
      final weekStart = DateTime(2026, 3, 9); // lunes
      final timestamps = [
        DateTime(2026, 3, 9, 10),
        DateTime(2026, 3, 9, 18),
        DateTime(2026, 3, 11, 9),
      ];

      expect(WorkoutStreakCalculator.countInWeek(timestamps, weekStart), 2);
    });
  });

  group('MilestonesCalculator', () {
    test('computeTotals cuenta un entreno por dia calendario', () {
      final day = DateTime(2026, 3, 10);
      final workouts = [
        Workout(
          id: '1',
          userId: 'u',
          name: 'A',
          startedAt: day,
          completedAt: day,
          durationMinutes: 45,
          totalVolume: 3000,
        ),
        Workout(
          id: '2',
          userId: 'u',
          name: 'B',
          startedAt: day.add(const Duration(hours: 4)),
          completedAt: day.add(const Duration(hours: 4)),
          durationMinutes: 30,
          totalVolume: 2000,
        ),
      ];

      final totals = MilestonesCalculator.computeTotals(workouts);

      expect(totals.totalWorkouts, 1);
      expect(totals.totalVolumeKg, 5000);
    });

    test('fromFriendData deduplica por completed_at', () {
      final totals = MilestonesCalculator.fromFriendData({
        'workouts': [
          {
            'duration_minutes': 45,
            'total_volume': 3000,
            'completed_at': '2026-03-10T10:00:00Z',
          },
          {
            'duration_minutes': 30,
            'total_volume': 2000,
            'completed_at': '2026-03-10T20:00:00Z',
          },
          {
            'duration_minutes': 50,
            'total_volume': 4000,
            'completed_at': '2026-03-11T08:00:00Z',
          },
        ],
        'total_reps': 100,
        'total_distance_meters': 0,
      });

      expect(totals.totalWorkouts, 2);
      expect(totals.totalVolumeKg, 9000);
    });
  });

  group('ProgressStatsCalculator', () {
    test('workoutsTotal y workouts7d usan dias unicos', () {
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
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

      final stats = ProgressStatsCalculator.compute(workouts);

      expect(stats.workouts7d, 1);
      expect(stats.workoutsTotal, 1);
      expect(stats.volumeTotalKg, 5000);
    });
  });
}
