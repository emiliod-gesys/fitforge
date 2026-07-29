import 'package:fitforge/services/offline/workout_local_serializer.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutLocalSerializer', () {
    test('roundtrips workout with exercises and sets', () {
      final workout = Workout(
        id: 'w1',
        userId: 'u1',
        name: 'Push',
        startedAt: DateTime.utc(2026, 1, 1, 12),
        exercises: const [
          WorkoutExercise(
            id: 'we1',
            exerciseId: 'bench',
            exerciseName: 'Bench Press',
            orderIndex: 0,
            sets: [
              WorkoutSet(
                id: 's1',
                setNumber: 1,
                reps: 8,
                weight: 80,
                completed: true,
              ),
            ],
          ),
        ],
      );

      final json = WorkoutLocalSerializer.toJson(workout, pendingSync: true);
      final restored = WorkoutLocalSerializer.fromJson(json);

      expect(restored.id, workout.id);
      expect(restored.exercises, hasLength(1));
      expect(restored.exercises.first.sets.first.weight, 80);
      expect(json['pending_sync'], isTrue);
    });
  });
}
