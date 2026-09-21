import '../../models/routine.dart';
import '../../models/workout.dart';
import 'offline_json_file.dart';

/// Caché local de rutinas del usuario para iniciar entrenos sin red.
class RoutineCacheStore {
  static const _fileName = 'routine_cache.json';

  Future<void> saveAll(String userId, List<Routine> routines) async {
    await OfflineJsonFile.writeMap(_fileName, {
      'user_id': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'routines': routines.map(_routineToJson).toList(),
    });
  }

  Future<List<Routine>> loadAll(String userId) async {
    final state = await OfflineJsonFile.readMap(_fileName);
    if (state['user_id'] != userId) return [];
    final raw = state['routines'] as List? ?? [];
    final routines = <Routine>[];
    for (final item in raw.whereType<Map>()) {
      try {
        final r = Map<String, dynamic>.from(item);
        routines.add(
          Routine.fromJson(
            r,
            exercises: (r['exercises'] as List? ?? [])
                .whereType<Map>()
                .map((e) => RoutineExercise.fromJson(Map<String, dynamic>.from(e)))
                .toList(),
          ),
        );
      } catch (_) {
        // Ignora entradas de caché antiguas/incompletas.
      }
    }
    return routines;
  }

  Future<void> saveRoutine(Routine routine) async {
    final state = await OfflineJsonFile.readMap(_fileName);
    if (state['user_id'] != routine.userId) {
      await saveAll(routine.userId, [routine]);
      return;
    }
    final routines = await loadAll(routine.userId);
    final updated = [...routines.where((r) => r.id != routine.id), routine];
    await saveAll(routine.userId, updated);
  }

  Map<String, dynamic> _routineToJson(Routine routine) {
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
}

/// Previous sets por ejercicio para autocompletar series offline.
/// El archivo viejo sin usuario se ignora: mezclaba el historial de todas las cuentas del teléfono.
class PreviousSetsCache {
  static const _fileName = 'previous_sets_cache.json';

  Future<void> save(String userId, String exerciseId, List<WorkoutSet> sets) async {
    if (userId.isEmpty || exerciseId.isEmpty) return;
    final state = await OfflineJsonFile.readMap(_fileName);
    final byUser = Map<String, dynamic>.from(state['by_user'] as Map? ?? {});
    final userSets = Map<String, dynamic>.from(byUser[userId] as Map? ?? {});
    userSets[exerciseId] = sets
        .map((s) => {
              'id': s.id,
              ...s.toJson(),
            })
        .toList();
    byUser[userId] = userSets;
    await OfflineJsonFile.writeMap(_fileName, {
      'by_user': byUser,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<WorkoutSet>?> load(String userId, String exerciseId) async {
    if (userId.isEmpty || exerciseId.isEmpty) return null;
    final state = await OfflineJsonFile.readMap(_fileName);
    final byUser = state['by_user'] as Map?;
    final userSets = byUser?[userId] as Map?;
    final raw = userSets?[exerciseId];
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map((s) => WorkoutSet.fromJson(Map<String, dynamic>.from(s)))
        .toList();
  }
}
