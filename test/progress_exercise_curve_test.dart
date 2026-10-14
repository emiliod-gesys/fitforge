import 'package:fitforge/core/utils/progress_exercise_curve.dart';
import 'package:fitforge/models/exercise_history.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ExerciseSessionHistory session({
    required DateTime date,
    required List<WorkoutSet> sets,
  }) {
    return ExerciseSessionHistory(
      workoutId: date.toIso8601String(),
      workoutName: 'Día',
      date: date,
      sets: sets,
    );
  }

  WorkoutSet set({
    required int number,
    double? weight,
    int reps = 8,
    int? rir,
  }) {
    return WorkoutSet(
      id: '$number',
      setNumber: number,
      weight: weight,
      reps: reps,
      rir: rir,
      completed: true,
    );
  }

  test('uses the last set at the working weight, including its RIR', () {
    final points = ProgressExerciseCurve.fromSessions([
      session(
        date: DateTime(2026, 10, 2),
        sets: [
          set(number: 1, weight: 40, reps: 12, rir: 3),
          set(number: 2, weight: 80, reps: 8, rir: 2),
          set(number: 3, weight: 80, reps: 6, rir: 0),
        ],
      ),
      session(
        date: DateTime(2026, 9, 20),
        sets: [
          set(number: 1, weight: 75, reps: 8, rir: 1),
        ],
      ),
    ]);

    expect(points, hasLength(2));
    expect(points.first.date, DateTime(2026, 9, 20));
    expect(points.first.weightKg, 75);
    expect(points.first.rir, 1);
    expect(points.last.weightKg, 80);
    expect(points.last.reps, 6);
    expect(points.last.rir, 0);
  });

  test('skips a session with no load and no reps', () {
    final points = ProgressExerciseCurve.fromSessions([
      session(
        date: DateTime(2026, 10, 1),
        sets: [set(number: 1, reps: 0)],
      ),
    ]);

    expect(points, isEmpty);
  });
}
