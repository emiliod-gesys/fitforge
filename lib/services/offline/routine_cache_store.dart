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
    return raw
        .whereType<Map>()
        .map((r) => Routine.fromJson(
              Map<String, dynamic>.from(r),
              exercises: (r['exercises'] as List? ?? [])
                  .whereType<Map>()
                  .map((e) => RoutineExercise.fromJson(Map<String, dynamic>.from(e)))
                  .toList(),
            ))
        .toList();
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
      ...routine.toJson(),
      'exercises': routine.exercises.map((e) => e.toJson()).toList(),
    };
  }
}

/// Previous sets por ejercicio para autocompletar series offline.
class PreviousSetsCache {
  static const _fileName = 'previous_sets_cache.json';

  Future<void> save(String exerciseId, List<WorkoutSet> sets) async {
    final state = await OfflineJsonFile.readMap(_fileName);
    final map = Map<String, dynamic>.from(state['sets'] as Map? ?? {});
    map[exerciseId] = sets
        .map((s) => {
              'id': s.id,
              ...s.toJson(),
            })
        .toList();
    state['sets'] = map;
    state['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await OfflineJsonFile.writeMap(_fileName, state);
  }

  Future<List<WorkoutSet>?> load(String exerciseId) async {
    final state = await OfflineJsonFile.readMap(_fileName);
    final map = state['sets'] as Map?;
    final raw = map?[exerciseId];
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map((s) => WorkoutSet.fromJson(Map<String, dynamic>.from(s)))
        .toList();
  }
}
