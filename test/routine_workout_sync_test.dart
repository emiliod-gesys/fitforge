import 'package:fitforge/core/utils/routine_workout_sync.dart';
import 'package:fitforge/models/exercise_logging.dart';
import 'package:fitforge/models/routine.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoutineWorkoutSync', () {
    test('maps completed strength sets to routine targets', () {
      final workout = Workout(
        id: 'w1',
        userId: 'u1',
        name: 'Push',
        startedAt: DateTime(2026, 1, 1),
        exercises: [
          WorkoutExercise(
            id: 'we1',
            exerciseId: 'bench',
            exerciseName: 'Bench Press',
            orderIndex: 0,
            sets: [
              WorkoutSet(id: 's1', setNumber: 1, reps: 8, weight: 80, completed: true),
              WorkoutSet(id: 's2', setNumber: 2, reps: 6, weight: 85, completed: true),
              WorkoutSet(id: 's3', setNumber: 3, reps: 5, weight: 90, completed: false),
            ],
          ),
        ],
      );

      final exercises = RoutineWorkoutSync.routineExercisesFromWorkout(workout);

      expect(exercises, hasLength(1));
      expect(exercises.first.targetSets, 2);
      expect(exercises.first.targetSetDetails[0].reps, 8);
      expect(exercises.first.targetSetDetails[1].weight, 85);
    });

    test('skips exercises without completed sets', () {
      final workout = Workout(
        id: 'w1',
        userId: 'u1',
        name: 'Push',
        startedAt: DateTime(2026, 1, 1),
        exercises: [
          WorkoutExercise(
            id: 'we1',
            exerciseId: 'bench',
            exerciseName: 'Bench Press',
            orderIndex: 0,
            sets: [
              WorkoutSet(id: 's1', setNumber: 1, reps: 8, weight: 80, completed: false),
            ],
          ),
        ],
      );

      expect(RoutineWorkoutSync.routineExercisesFromWorkout(workout), isEmpty);
      expect(RoutineWorkoutSync.hasSavableExercises(workout), isFalse);
    });

    test('maps cardio completed sets', () {
      final workout = Workout(
        id: 'w1',
        userId: 'u1',
        name: 'Cardio',
        startedAt: DateTime(2026, 1, 1),
        exercises: [
          WorkoutExercise(
            id: 'we1',
            exerciseId: 'run',
            exerciseName: 'Treadmill',
            orderIndex: 0,
            sets: [
              WorkoutSet(
                id: 's1',
                setNumber: 1,
                completed: true,
                loggingType: ExerciseLoggingType.cardio,
                durationSeconds: 1200,
                distanceMeters: 3000,
              ),
            ],
          ),
        ],
      );

      final exercises = RoutineWorkoutSync.routineExercisesFromWorkout(workout);

      expect(exercises, hasLength(1));
      expect(exercises.first.isCardio, isTrue);
      expect(exercises.first.targetDurationSeconds, 1200);
      expect(exercises.first.targetDistanceMeters, 3000);
    });

    test('actualizar rutina solo sustituye o agrega ejercicios', () {
      final routine = [
        RoutineExercise(
          id: 're-bench',
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          orderIndex: 0,
          targetSetDetails: const [
            RoutineSetTarget(reps: 8, weight: 80),
            RoutineSetTarget(reps: 8, weight: 80),
          ],
          restSeconds: 120,
        ),
        RoutineExercise(
          id: 're-row',
          exerciseId: 'row',
          exerciseName: 'Row',
          orderIndex: 1,
          targetSetDetails: const [
            RoutineSetTarget(reps: 10, weight: 50),
          ],
        ),
      ];
      final workout = Workout(
        id: 'w1',
        userId: 'u1',
        name: 'Push',
        startedAt: DateTime(2026, 1, 1),
        exercises: [
          WorkoutExercise(
            id: 'we1',
            exerciseId: 'bench',
            exerciseName: 'Bench Press',
            orderIndex: 0,
            sets: const [
              WorkoutSet(id: 's1', setNumber: 1, reps: 5, weight: 100, completed: true),
            ],
          ),
          WorkoutExercise(
            id: 'we2',
            exerciseId: 'fly',
            exerciseName: 'Fly',
            orderIndex: 1,
            sets: const [
              WorkoutSet(id: 's2', setNumber: 1, reps: 12, weight: 20, completed: true),
            ],
          ),
          WorkoutExercise(
            id: 'we3',
            exerciseId: 'curl',
            exerciseName: 'Curl',
            orderIndex: 2,
            sets: const [
              WorkoutSet(id: 's3', setNumber: 1, reps: 10, weight: 15, completed: true),
            ],
          ),
        ],
      );

      final merged = RoutineWorkoutSync.applyStructuralEdits(
        routineExercises: routine,
        workout: workout,
      );

      expect(merged, isNotNull);
      expect(merged!.map((e) => e.exerciseId), ['bench', 'fly', 'curl']);
      expect(merged[0].id, 're-bench');
      expect(merged[0].targetSetDetails.first.weight, 80);
      expect(merged[0].restSeconds, 120);
      expect(merged[1].exerciseName, 'Fly');
      expect(merged[1].targetSetDetails.first.weight, 20);
      expect(merged[1].restSeconds, 90);
      expect(merged[2].exerciseId, 'curl');
    });

    test('sin cambio de ejercicios no reescribe la rutina', () {
      final routine = [
        RoutineExercise(
          id: 're-bench',
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          orderIndex: 0,
        ),
      ];
      final workout = Workout(
        id: 'w1',
        userId: 'u1',
        name: 'Push',
        startedAt: DateTime(2026, 1, 1),
        exercises: [
          WorkoutExercise(
            id: 'we1',
            exerciseId: 'bench',
            exerciseName: 'Bench Press',
            orderIndex: 0,
            sets: const [
              WorkoutSet(id: 's1', setNumber: 1, reps: 3, weight: 200, completed: true),
            ],
          ),
        ],
      );

      expect(
        RoutineWorkoutSync.applyStructuralEdits(
          routineExercises: routine,
          workout: workout,
        ),
        isNull,
      );
    });
  });
}
