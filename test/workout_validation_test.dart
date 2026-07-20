import 'package:fitforge/core/workout/workout_validation.dart';
import 'package:fitforge/models/exercise_logging.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

Workout _workout({
  List<WorkoutExercise> exercises = const [],
  double totalVolume = 0,
}) {
  return Workout(
    id: 'w1',
    userId: 'u1',
    name: 'Test',
    startedAt: DateTime.utc(2026, 1, 1, 10),
    completedAt: DateTime.utc(2026, 1, 1, 11),
    durationMinutes: 60,
    totalVolume: totalVolume,
    exercises: exercises,
  );
}

WorkoutExercise _exercise({
  required String id,
  required List<WorkoutSet> sets,
}) {
  return WorkoutExercise(
    id: id,
    exerciseId: 'ex1',
    exerciseName: 'Press',
    orderIndex: 0,
    sets: sets,
  );
}

void main() {
  group('WorkoutValidator', () {
    test('accepts normal strength session', () {
      final workout = _workout(
        totalVolume: 5000,
        exercises: [
          _exercise(
            id: 'we1',
            sets: const [
              WorkoutSet(id: 's1', setNumber: 1, weight: 100, reps: 10, completed: true),
              WorkoutSet(id: 's2', setNumber: 2, weight: 100, reps: 10, completed: true),
            ],
          ),
        ],
      );

      final result = WorkoutValidator.validate(
        workout: workout,
        startedAt: workout.startedAt,
        completedAt: workout.completedAt!,
        durationMinutes: 45,
        totalVolumeKg: 2000,
      );

      expect(result.status, WorkoutValidationStatus.valid);
      expect(result.countsForLeaderboard, isTrue);
    });

    test('rejects impossibly short session with huge volume', () {
      final workout = _workout(totalVolume: 50000);

      final result = WorkoutValidator.validate(
        workout: workout,
        startedAt: workout.startedAt,
        completedAt: workout.startedAt.add(const Duration(minutes: 1)),
        durationMinutes: 1,
        totalVolumeKg: 50000,
      );

      expect(result.status, WorkoutValidationStatus.rejected);
      expect(result.reasons, contains('duration_too_short'));
    });

    test('rejects absurd weight and rep counts', () {
      final workout = _workout(
        exercises: [
          _exercise(
            id: 'we1',
            sets: const [
              WorkoutSet(id: 's1', setNumber: 1, weight: 600, reps: 400, completed: true),
            ],
          ),
        ],
      );

      final result = WorkoutValidator.validate(
        workout: workout,
        startedAt: workout.startedAt,
        completedAt: workout.completedAt!,
        durationMinutes: 60,
        totalVolumeKg: 240000,
      );

      expect(result.status, WorkoutValidationStatus.rejected);
      expect(result.reasons, contains('weight_too_high'));
      expect(result.reasons, contains('reps_per_set_too_high'));
    });

    test('flags suspicious volume without rejecting moderate sessions', () {
      final workout = _workout(totalVolume: 35000);

      final result = WorkoutValidator.validate(
        workout: workout,
        startedAt: workout.startedAt,
        completedAt: workout.completedAt!,
        durationMinutes: 90,
        totalVolumeKg: 35000,
      );

      expect(result.status, WorkoutValidationStatus.suspicious);
      expect(result.reasons, contains('volume_high'));
      expect(result.countsForLeaderboard, isFalse);
    });

    test('rejects impossible running pace on cardio set', () {
      final workout = _workout(
        exercises: [
          _exercise(
            id: 'we1',
            sets: const [
              WorkoutSet(
                id: 's1',
                setNumber: 1,
                completed: true,
                durationSeconds: 60,
                distanceMeters: 1000,
                loggingType: ExerciseLoggingType.cardio,
              ),
            ],
          ),
        ],
      );

      final result = WorkoutValidator.validate(
        workout: workout,
        startedAt: workout.startedAt,
        completedAt: workout.completedAt!,
        durationMinutes: 30,
        totalVolumeKg: 0,
        runnerAvgPaceSecPerKm: 90,
      );

      expect(result.status, WorkoutValidationStatus.rejected);
      expect(result.reasons, anyElement(isIn(['pace_too_fast', 'runner_pace_too_fast'])));
    });

    test('skips heavy volume checks for hyrox system workouts', () {
      final workout = _workout(totalVolume: 40000);

      final result = WorkoutValidator.validate(
        workout: workout,
        startedAt: workout.startedAt,
        completedAt: workout.completedAt!,
        durationMinutes: 60,
        totalVolumeKg: 40000,
        isHyroxSystem: true,
      );

      expect(result.status, isNot(WorkoutValidationStatus.rejected));
      expect(result.reasons, isNot(contains('volume_too_high')));
    });
  });
}
