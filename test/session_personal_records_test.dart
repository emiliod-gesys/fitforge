import 'package:fitforge/core/utils/session_personal_records.dart';
import 'package:fitforge/models/exercise_logging.dart';
import 'package:fitforge/models/profile.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionPersonalRecords', () {
    test('detects new strength PR by 1RM', () {
      final workout = Workout(
        id: 'w1',
        userId: 'u1',
        name: 'Push',
        startedAt: DateTime(2026, 1, 1),
        exercises: const [
          WorkoutExercise(
            id: 'we1',
            exerciseId: 'bench',
            exerciseName: 'Bench Press',
            orderIndex: 0,
            sets: [
              WorkoutSet(id: 's1', setNumber: 1, reps: 5, weight: 100, completed: true),
            ],
          ),
        ],
      );

      final existing = [
        PersonalRecord(
          id: 'pr1',
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          weight: 90,
          reps: 5,
          oneRepMax: PersonalRecord.calculate1RM(90, 5),
          achievedAt: DateTime(2025, 12, 1),
        ),
      ];

      final detected = SessionPersonalRecords.detect(
        workout: workout,
        existing: existing,
      );

      expect(detected, hasLength(2));
      final strengthPr = detected.firstWhere(
        (pr) => pr.recordType == PersonalRecordType.strength,
      );
      expect(strengthPr.oneRepMax, greaterThan(existing.first.oneRepMax!));
    });

    test('does not flag PR when 1RM is not improved', () {
      final workout = Workout(
        id: 'w1',
        userId: 'u1',
        name: 'Push',
        startedAt: DateTime(2026, 1, 1),
        exercises: const [
          WorkoutExercise(
            id: 'we1',
            exerciseId: 'bench',
            exerciseName: 'Bench Press',
            orderIndex: 0,
            sets: [
              WorkoutSet(id: 's1', setNumber: 1, reps: 5, weight: 80, completed: true),
            ],
          ),
        ],
      );

      final existing = [
        PersonalRecord(
          id: 'pr1',
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          weight: 100,
          reps: 5,
          oneRepMax: PersonalRecord.calculate1RM(100, 5),
          achievedAt: DateTime(2025, 12, 1),
        ),
      ];

      final detected = SessionPersonalRecords.detect(
        workout: workout,
        existing: existing,
      );

      expect(detected, isEmpty);
    });

    test('detects new max weight PR even when 1RM does not improve', () {
      final workout = Workout(
        id: 'w1',
        userId: 'u1',
        name: 'Push',
        startedAt: DateTime(2026, 1, 1),
        exercises: const [
          WorkoutExercise(
            id: 'we1',
            exerciseId: 'bench',
            exerciseName: 'Bench Press',
            orderIndex: 0,
            sets: [
              WorkoutSet(id: 's1', setNumber: 1, reps: 3, weight: 105, completed: true),
            ],
          ),
        ],
      );

      final existing = [
        PersonalRecord(
          id: 'pr1',
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          weight: 100,
          reps: 5,
          oneRepMax: PersonalRecord.calculate1RM(100, 5),
          achievedAt: DateTime(2025, 12, 1),
        ),
        PersonalRecord(
          id: 'pr2',
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          weight: 100,
          reps: 5,
          achievedAt: DateTime(2025, 12, 1),
          recordType: PersonalRecordType.strengthMaxWeight,
        ),
      ];

      final detected = SessionPersonalRecords.detect(
        workout: workout,
        existing: existing,
      );

      expect(detected, hasLength(1));
      expect(detected.first.recordType, PersonalRecordType.strengthMaxWeight);
      expect(detected.first.weight, 105);
      expect(detected.first.reps, 3);
    });

    test('detects both 1RM and max weight PRs in same session', () {
      final workout = Workout(
        id: 'w1',
        userId: 'u1',
        name: 'Push',
        startedAt: DateTime(2026, 1, 1),
        exercises: const [
          WorkoutExercise(
            id: 'we1',
            exerciseId: 'bench',
            exerciseName: 'Bench Press',
            orderIndex: 0,
            sets: [
              WorkoutSet(id: 's1', setNumber: 1, reps: 1, weight: 120, completed: true),
            ],
          ),
        ],
      );

      final detected = SessionPersonalRecords.detect(
        workout: workout,
        existing: const [],
      );

      expect(detected, hasLength(2));
      expect(
        detected.map((pr) => pr.recordType).toSet(),
        {PersonalRecordType.strength, PersonalRecordType.strengthMaxWeight},
      );
    });
  });
}
