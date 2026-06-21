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

      expect(detected, hasLength(1));
      expect(detected.first.recordType, PersonalRecordType.strength);
      expect(detected.first.oneRepMax, greaterThan(existing.first.oneRepMax!));
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
  });
}
