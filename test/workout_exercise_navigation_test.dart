import 'package:fitforge/core/utils/workout_exercise_navigation.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutExercise _exercise(String id, int order) {
  return WorkoutExercise(
    id: id,
    exerciseId: 'catalog-$id',
    exerciseName: 'Exercise $id',
    orderIndex: order,
  );
}

void main() {
  group('WorkoutExerciseNavigation', () {
    test('resolves next index by exercise id across different instances', () {
      final rawA = _exercise('a', 0);
      final rawB = _exercise('b', 1);
      final mergedA = _exercise('a', 0);

      final visible = [mergedA, rawB];
      final workoutExercises = [rawA, rawB];

      expect(
        WorkoutExerciseNavigation.resolveNextWorkoutIndex(
          workoutExercises: workoutExercises,
          visibleExercises: visible,
          currentExerciseId: mergedA.id,
        ),
        1,
      );
      expect(WorkoutExerciseNavigation.hasNext(visible, mergedA.id), isTrue);
    });

    test('returns null when already on last visible exercise', () {
      final exercises = [_exercise('a', 0), _exercise('b', 1)];

      expect(
        WorkoutExerciseNavigation.resolveNextWorkoutIndex(
          workoutExercises: exercises,
          visibleExercises: exercises,
          currentExerciseId: 'b',
        ),
        isNull,
      );
      expect(WorkoutExerciseNavigation.hasNext(exercises, 'b'), isFalse);
    });

    test('resolves previous index by exercise id', () {
      final rawA = _exercise('a', 0);
      final rawB = _exercise('b', 1);
      final mergedB = _exercise('b', 1);

      expect(
        WorkoutExerciseNavigation.resolvePreviousWorkoutIndex(
          workoutExercises: [rawA, rawB],
          visibleExercises: [rawA, mergedB],
          currentExerciseId: mergedB.id,
        ),
        0,
      );
    });
  });
}
