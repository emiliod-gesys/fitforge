import 'package:fitforge/core/utils/train_suggestion_resolver.dart';
import 'package:fitforge/models/routine.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final routines = [
    Routine(
      id: 'push',
      userId: 'u1',
      name: 'Push',
      targetMuscles: const ['Pecho', 'Hombros'],
      exercises: const [],
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    ),
    Routine(
      id: 'pull',
      userId: 'u1',
      name: 'Pull',
      targetMuscles: const ['Espalda', 'Bíceps'],
      exercises: const [],
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    ),
  ];

  Workout workout({
    required String id,
    String? routineId,
    String name = 'Session',
  }) {
    return Workout(
      id: id,
      userId: 'u1',
      routineId: routineId,
      name: name,
      startedAt: DateTime(2025, 6, 1),
      completedAt: DateTime(2025, 6, 1, 1),
    );
  }

  test('prefers last completed workout routine', () {
    final suggestion = TrainSuggestionResolver.resolve(
      routines: routines,
      recentWorkouts: [
        workout(id: 'w1', routineId: 'pull'),
        workout(id: 'w2', routineId: 'push'),
      ],
      recovery: const {'Pecho': 95, 'Espalda': 40},
    );

    expect(suggestion?.routine.id, 'pull');
    expect(suggestion?.reason, TrainSuggestionReason.lastRoutine);
  });

  test('suggests routine with best recovery when no recent routine match', () {
    final suggestion = TrainSuggestionResolver.resolve(
      routines: routines,
      recentWorkouts: [workout(id: 'w1')],
      recovery: const {
        'Pecho': 95,
        'Hombros': 92,
        'Espalda': 45,
        'Bíceps': 40,
      },
    );

    expect(suggestion?.routine.id, 'push');
    expect(suggestion?.reason, TrainSuggestionReason.recovery);
  });

  test('falls back to first routine', () {
    final suggestion = TrainSuggestionResolver.resolve(
      routines: routines,
      recentWorkouts: const [],
      recovery: const {
        'Pecho': 30,
        'Hombros': 25,
        'Espalda': 20,
        'Bíceps': 15,
      },
    );

    expect(suggestion?.routine.id, 'push');
    expect(suggestion?.reason, TrainSuggestionReason.defaultPick);
  });
}
