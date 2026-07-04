import 'package:fitforge/core/utils/train_suggestion_resolver.dart';
import 'package:fitforge/models/routine.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final upperRoutines = [
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

  final allRoutines = [
    ...upperRoutines,
    Routine(
      id: 'legs',
      userId: 'u1',
      name: 'Legs',
      targetMuscles: const ['Cuádriceps', 'Isquios', 'Glúteos'],
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

  test('prefers routine with best recovery over last completed routine', () {
    final suggestion = TrainSuggestionResolver.resolve(
      routines: upperRoutines,
      recentWorkouts: [
        workout(id: 'w1', routineId: 'pull'),
        workout(id: 'w2', routineId: 'push'),
      ],
      recovery: const {'Pecho': 95, 'Espalda': 40},
    );

    expect(suggestion?.routine.id, 'push');
    expect(suggestion?.reason, TrainSuggestionReason.recovery);
  });

  test('suggests legs when upper body was last and is still fatigued', () {
    final upperBody = Routine(
      id: 'upper',
      userId: 'u1',
      name: 'Upper Body',
      targetMuscles: const ['Pecho', 'Espalda', 'Bíceps'],
      exercises: const [],
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

    final suggestion = TrainSuggestionResolver.resolve(
      routines: [upperBody, allRoutines[2]],
      recentWorkouts: [workout(id: 'w1', routineId: 'upper')],
      recovery: const {
        'Pecho': 39,
        'Espalda': 35,
        'Bíceps': 32,
        'Cuádriceps': 96,
        'Isquios': 94,
        'Glúteos': 98,
      },
    );

    expect(suggestion?.routine.id, 'legs');
    expect(suggestion?.reason, TrainSuggestionReason.recovery);
  });

  test('uses last routine reason only when it also has the best recovery', () {
    final suggestion = TrainSuggestionResolver.resolve(
      routines: upperRoutines,
      recentWorkouts: [workout(id: 'w1', routineId: 'push')],
      recovery: const {
        'Pecho': 92,
        'Hombros': 88,
        'Espalda': 40,
        'Bíceps': 35,
      },
    );

    expect(suggestion?.routine.id, 'push');
    expect(suggestion?.reason, TrainSuggestionReason.lastRoutine);
  });

  test('suggests routine with best recovery when no recent routine match', () {
    final suggestion = TrainSuggestionResolver.resolve(
      routines: upperRoutines,
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

  test('falls back to best available routine when all are fatigued', () {
    final suggestion = TrainSuggestionResolver.resolve(
      routines: allRoutines,
      recentWorkouts: const [],
      recovery: const {
        'Pecho': 30,
        'Hombros': 25,
        'Espalda': 20,
        'Bíceps': 15,
        'Cuádriceps': 28,
        'Isquios': 22,
        'Glúteos': 18,
      },
    );

    expect(suggestion?.routine.id, 'push');
    expect(suggestion?.reason, TrainSuggestionReason.defaultPick);
  });
}
