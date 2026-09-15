import 'package:fitforge/core/tutorials/tutorial_workout_session.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:fitforge/models/exercise_logging.dart';
import 'package:fitforge/models/routine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tutorialDemoExercises picks two strength moves with three sets', () {
    final catalog = [
      Exercise(
        name: 'Run',
        catalogId: 'run',
        loggingType: ExerciseLoggingType.cardio,
      ),
      Exercise(name: 'Squat', catalogId: 'squat'),
      Exercise(name: 'Bench', catalogId: 'bench'),
      Exercise(name: 'Row', catalogId: 'row'),
    ];

    final demo = tutorialDemoExercises(catalog);
    expect(demo.length, 2);
    expect(demo.map((e) => e.exerciseId), ['squat', 'bench']);
    expect(demo[0].sets.length, 3);
    expect(demo[1].orderIndex, 1);
  });

  test('tutorialDemoExercises is empty when catalog has no strength work', () {
    final catalog = [
      Exercise(
        name: 'Run',
        catalogId: 'run',
        loggingType: ExerciseLoggingType.cardio,
      ),
    ];
    expect(tutorialDemoExercises(catalog), isEmpty);
  });

  test('workout tutorial requires a non-empty gym routine', () {
    final now = DateTime.utc(2026, 1, 1);
    Routine stub({
      bool hyrox = false,
      bool runner = false,
      bool withExercise = false,
    }) {
      return Routine(
        id: 'r',
        userId: 'u',
        name: 'A',
        createdAt: now,
        updatedAt: now,
        isHyroxSystem: hyrox,
        isRunnerSystem: runner,
        exercises: withExercise
            ? const [
                RoutineExercise(
                  id: 'e',
                  exerciseId: 'squat',
                  exerciseName: 'Squat',
                  orderIndex: 0,
                ),
              ]
            : const [],
      );
    }

    expect(isWorkoutTutorialRoutine(stub()), isFalse);
    expect(
      isWorkoutTutorialRoutine(stub(withExercise: true, hyrox: true)),
      isFalse,
    );
    expect(
      isWorkoutTutorialRoutine(stub(withExercise: true, runner: true)),
      isFalse,
    );
    expect(isWorkoutTutorialRoutine(stub(withExercise: true)), isTrue);
    expect(
      firstWorkoutTutorialRoutine([stub(hyrox: true, withExercise: true)]),
      isNull,
    );
    expect(
      firstWorkoutTutorialRoutine([stub(), stub(withExercise: true)])?.name,
      'A',
    );
  });
}
