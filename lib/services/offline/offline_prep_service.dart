import '../../models/routine.dart';
import '../custom_exercise_repository.dart';
import '../routine_service.dart';
import '../workout_service.dart';
import 'offline_json_file.dart';
import 'routine_cache_store.dart';

/// Prepara datos locales para uso offline (rutinas, previous sets, metadatos).
class OfflinePrepService {
  OfflinePrepService({
    required RoutineService routineService,
    required WorkoutService workoutService,
    required RoutineCacheStore routineCache,
    required PreviousSetsCache previousSetsCache,
    required CustomExerciseRepository customExerciseRepository,
  })  : _routineService = routineService,
        _workoutService = workoutService,
        _routineCache = routineCache,
        _previousSetsCache = previousSetsCache,
        _customExerciseRepository = customExerciseRepository;

  final RoutineService _routineService;
  final WorkoutService _workoutService;
  final RoutineCacheStore _routineCache;
  final PreviousSetsCache _previousSetsCache;
  final CustomExerciseRepository _customExerciseRepository;

  static const _metaFile = 'offline_prep_meta.json';

  Future<OfflinePrepResult> prepare({required String userId}) async {
    final routines = await _routineService.getRoutinesForUser(userId);
    await _routineCache.saveAll(userId, routines);

    final exerciseIds = <String>{};
    for (final routine in routines) {
      for (final ex in routine.exercises) {
        exerciseIds.add(ex.exerciseId);
      }
    }

    var cachedPreviousSets = 0;
    for (final exerciseId in exerciseIds) {
      final previous = await _workoutService.getPreviousSetsForExercise(exerciseId);
      if (previous != null && previous.isNotEmpty) {
        await _previousSetsCache.save(exerciseId, previous);
        cachedPreviousSets++;
      }
    }

    // Custom exercises ya están en disco; forzamos recarga en memoria.
    await _customExerciseRepository.loadAll();

    await OfflineJsonFile.writeMap(_metaFile, {
      'user_id': userId,
      'prepared_at': DateTime.now().toUtc().toIso8601String(),
      'routine_count': routines.length,
      'previous_sets_count': cachedPreviousSets,
    });

    return OfflinePrepResult(
      routineCount: routines.length,
      previousSetsCount: cachedPreviousSets,
    );
  }

  Future<DateTime?> lastPreparedAt(String userId) async {
    final meta = await OfflineJsonFile.readMap(_metaFile);
    if (meta['user_id'] != userId) return null;
    final raw = meta['prepared_at'] as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}

class OfflinePrepResult {
  final int routineCount;
  final int previousSetsCount;

  const OfflinePrepResult({
    required this.routineCount,
    required this.previousSetsCount,
  });
}

/// Extiende RoutineCacheStore con saveRoutine helper usado al guardar rutinas.
extension RoutineCacheStoreExtensions on RoutineCacheStore {
  Future<void> cacheRoutineList(String userId, List<Routine> routines) =>
      saveAll(userId, routines);
}
