import 'package:fitforge/core/hyrox/hyrox_routine_builder.dart';
import 'package:fitforge/core/hyrox/hyrox_standards.dart';
import 'package:fitforge/core/hyrox/hyrox_validation.dart';
import 'package:fitforge/models/exercise_logging.dart';
import 'package:fitforge/models/profile.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

Workout _hyroxWorkout({
  required List<WorkoutExercise> exercises,
  DateTime? startedAt,
  DateTime? completedAt,
}) {
  return Workout(
    id: 'w1',
    userId: 'u1',
    routineId: 'r1',
    name: 'Hyrox Race',
    startedAt: startedAt ?? DateTime(2026, 1, 1, 10),
    completedAt: completedAt,
    exercises: exercises,
  );
}

WorkoutExercise _station({
  required int order,
  required String exerciseId,
  required int seconds,
  double? distance,
  double? weight,
  int reps = 1,
  ExerciseLoggingType loggingType = ExerciseLoggingType.strength,
}) {
  return WorkoutExercise(
    id: 'we$order',
    exerciseId: exerciseId,
    exerciseName: exerciseId,
    orderIndex: order,
    sets: [
      WorkoutSet(
        id: 's$order',
        setNumber: 1,
        completed: true,
        durationSeconds: seconds,
        distanceMeters: distance,
        weight: weight,
        reps: reps,
        loggingType: loggingType,
      ),
    ],
  );
}

UserProfile _profile({Gender? gender}) {
  return UserProfile(
    id: 'u1',
    gender: gender,
    bodyWeight: 80,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('HyroxValidator', () {
    test('rejects impossibly fast race day total', () {
      final exercises = List.generate(
        16,
        (i) => _station(
          order: i,
          exerciseId: 'ff_cardio_outdoor_running',
          seconds: 120,
          distance: 1000,
          loggingType: ExerciseLoggingType.cardio,
        ),
      );
      final workout = _hyroxWorkout(
        exercises: exercises,
        completedAt: DateTime(2026, 1, 1, 10, 30),
      );

      final result = HyroxValidator.validate(
        workout: workout,
        level: HyroxLevel.race,
        gender: Gender.male,
        startedAt: workout.startedAt,
        completedAt: workout.completedAt!,
      );

      expect(result.status, HyroxValidationStatus.rejected);
      expect(result.reasons, contains('total_time_too_fast'));
    });

    test('accepts realistic race day built from official routine', () {
      final routine = HyroxRoutineBuilder.build(
        profile: _profile(gender: Gender.male),
        level: HyroxLevel.race,
      );
      final started = DateTime(2026, 1, 1, 10);
      final exercises = routine.exercises
          .map(
            (re) => _station(
              order: re.orderIndex,
              exerciseId: re.exerciseId,
              seconds: 180 + re.orderIndex * 8,
              distance: re.targetDistanceMeters,
              weight: re.targetWeight,
              reps: re.targetReps,
              loggingType: re.loggingType,
            ),
          )
          .toList();

      final workout = _hyroxWorkout(
        exercises: exercises,
        startedAt: started,
        completedAt: started.add(const Duration(minutes: 78)),
      );

      final result = HyroxValidator.validate(
        workout: workout,
        level: HyroxLevel.race,
        gender: Gender.male,
        startedAt: workout.startedAt,
        completedAt: workout.completedAt!,
        expectations: HyroxValidator.expectationsFromRoutineExercises(routine.exercises),
      );

      expect(result.status, HyroxValidationStatus.valid);
      expect(result.countsForLeaderboard, isTrue);
    });

    test('rejects station faster than human threshold', () {
      final started = DateTime(2026, 1, 1, 10);
      final exercises = [
        _station(
          order: 0,
          exerciseId: 'ff_cardio_outdoor_running',
          seconds: 90,
          distance: 1000,
          loggingType: ExerciseLoggingType.cardio,
        ),
      ];

      final workout = _hyroxWorkout(
        exercises: exercises,
        startedAt: started,
        completedAt: started.add(const Duration(minutes: 50)),
      );

      final result = HyroxValidator.validate(
        workout: workout,
        level: HyroxLevel.race,
        startedAt: workout.startedAt,
        completedAt: workout.completedAt!,
      );

      expect(result.status, HyroxValidationStatus.rejected);
      expect(result.reasons.any((r) => r.startsWith('station_time_too_fast')), isTrue);
    });
  });
}
