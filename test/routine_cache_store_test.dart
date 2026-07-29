import 'package:fitforge/models/routine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifica el contrato JSON que usa RoutineCacheStore al persistir rutinas.
Map<String, dynamic> routineCacheJson(Routine routine) {
  return {
    'id': routine.id,
    'user_id': routine.userId,
    'name': routine.name,
    'description': routine.description,
    'target_muscles': routine.targetMuscles,
    'created_at': routine.createdAt.toUtc().toIso8601String(),
    'updated_at': routine.updatedAt.toUtc().toIso8601String(),
    'is_ai_generated': routine.isAiGenerated,
    'is_favorite': routine.isFavorite,
    'is_hyrox_system': routine.isHyroxSystem,
    if (routine.hyroxLevel != null) 'hyrox_level': routine.hyroxLevel!.code,
    'is_runner_system': routine.isRunnerSystem,
    if (routine.runnerType != null) 'runner_type': routine.runnerType!.code,
    'exercises': routine.exercises.map((e) => e.toJson()).toList(),
  };
}

void main() {
  test('routine cache json roundtrips through Routine.fromJson', () {
    final routine = Routine(
      id: 'r1',
      userId: 'u1',
      name: 'Push Day',
      description: 'Chest focus',
      targetMuscles: const ['chest'],
      exercises: const [
        RoutineExercise(
          id: 're1',
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          orderIndex: 0,
        ),
      ],
      createdAt: DateTime.utc(2026, 1, 1, 12),
      updatedAt: DateTime.utc(2026, 1, 2, 8),
      isFavorite: true,
    );

    final json = routineCacheJson(routine);
    final loaded = Routine.fromJson(
      json,
      exercises: (json['exercises'] as List)
          .map((e) => RoutineExercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );

    expect(loaded.id, 'r1');
    expect(loaded.userId, 'u1');
    expect(loaded.name, 'Push Day');
    expect(loaded.exercises.first.exerciseId, 'bench');
    expect(loaded.isFavorite, isTrue);
  });
}
