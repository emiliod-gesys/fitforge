import 'package:fitforge/core/utils/exercise_history_utils.dart';
import 'package:fitforge/models/exercise_history.dart';
import 'package:fitforge/models/exercise_logging.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSet _set(int n, double? w, int reps) => WorkoutSet(
      id: '$n',
      setNumber: n,
      weight: w,
      reps: reps,
      completed: true,
      loggingType: ExerciseLoggingType.strength,
    );

void main() {
  group('ExerciseHistoryUtils', () {
    test('isStaleGhostWorkout detects auto-closed workouts', () {
      expect(
        ExerciseHistoryUtils.isStaleGhostWorkout({
          'duration_minutes': 0,
          'total_volume': 0,
        }),
        isTrue,
      );
      expect(
        ExerciseHistoryUtils.isStaleGhostWorkout({
          'duration_minutes': 45,
          'total_volume': 1200,
        }),
        isFalse,
      );
    });

    test('weightPattern detects warmup_then_work', () {
      final sets = [
        _set(1, 36.3, 12),
        _set(2, 54.4, 10),
        _set(3, 59.0, 12),
        _set(4, 59.0, 12),
        _set(5, 59.0, 10),
      ];
      expect(ExerciseHistoryUtils.weightPattern(sets), 'warmup_then_work');
      expect(ExerciseHistoryUtils.workingSets(sets).length, 4);
    });

    test('dedupeEntriesByWorkout keeps highest quality entry', () {
      final entries = [
        (
          weId: 'we-light',
          workout: {
            'id': 'w1',
            'completed_at': '2026-07-05T20:00:00Z',
          },
        ),
        (
          weId: 'we-heavy',
          workout: {
            'id': 'w1',
            'completed_at': '2026-07-05T20:00:00Z',
          },
        ),
      ];
      final setsByWeId = {
        'we-light': [_set(1, 36.3, 12), _set(2, 36.3, 12), _set(3, 36.3, 10)],
        'we-heavy': [_set(1, 59.0, 12), _set(2, 59.0, 12), _set(3, 59.0, 12)],
      };

      final deduped = ExerciseHistoryUtils.dedupeEntriesByWorkout(entries, setsByWeId);
      expect(deduped.length, 1);
      expect(deduped.first.weId, 'we-heavy');
    });

    test('anchoringSession prefers heavier session over light ghost', () {
      final history = [
        ExerciseSessionHistory(
          workoutId: 'ghost',
          workoutName: 'Leg Day',
          date: DateTime(2026, 7, 5, 21),
          sets: [_set(1, 36.3, 12), _set(2, 36.3, 12), _set(3, 36.3, 10)],
        ),
        ExerciseSessionHistory(
          workoutId: 'real',
          workoutName: 'Leg Day',
          date: DateTime(2026, 7, 5, 19),
          sets: [_set(1, 59.0, 12), _set(2, 59.0, 12), _set(3, 59.0, 12)],
        ),
      ];

      final anchor = ExerciseHistoryUtils.anchoringSession(history);
      expect(anchor?.workoutId, 'real');
    });

    test('setsForNextWorkoutSuggestion skips obvious warmups', () {
      final sets = [
        _set(1, 40, 10),
        _set(2, 60, 5),
        _set(3, 80, 5),
        _set(4, 80, 5),
      ];
      final suggested = ExerciseHistoryUtils.setsForNextWorkoutSuggestion(sets);
      expect(suggested.every((s) => (s.weight ?? 0) >= 68), isTrue);
    });
  });
}
