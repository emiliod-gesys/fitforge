import '../../models/workout.dart';
import 'offline_json_file.dart';
import 'workout_local_serializer.dart';

/// Almacén local de entrenamientos activos y completados pendientes de sync.
class LocalWorkoutStore {
  static const _fileName = 'local_workouts.json';

  Future<Map<String, dynamic>> _readState() => OfflineJsonFile.readMap(_fileName);

  Future<void> _writeState(Map<String, dynamic> state) =>
      OfflineJsonFile.writeMap(_fileName, state);

  Future<void> clearForUser(String userId) async {
    final state = await _readState();
    if (state['user_id'] != userId) return;
    await _writeState({});
  }

  Future<void> saveWorkout(Workout workout, {required bool pendingSync, bool? syncedToServer}) async {
    final state = await _readState();
    final workouts = Map<String, dynamic>.from(state['workouts'] as Map? ?? {});
    final existing = workouts[workout.id];
    final preserveSynced = syncedToServer ??
        (existing is Map ? existing['synced_to_server'] as bool? : null) ??
        false;
    final json = WorkoutLocalSerializer.toJson(
      workout,
      pendingSync: pendingSync,
    );
    if (preserveSynced) {
      json['synced_to_server'] = true;
    }
    workouts[workout.id] = json;

    await _writeState({
      'user_id': workout.userId,
      'active_workout_id': workout.isActive ? workout.id : state['active_workout_id'],
      'workouts': workouts,
    });

    if (!workout.isActive && state['active_workout_id'] == workout.id) {
      await setActiveWorkoutId(workout.userId, null);
    }
  }

  Future<void> setActiveWorkoutId(String userId, String? workoutId) async {
    final state = await _readState();
    if (state['user_id'] != null && state['user_id'] != userId) {
      await _writeState({
        'user_id': userId,
        'active_workout_id': workoutId,
        'workouts': {},
      });
      return;
    }
    state['user_id'] = userId;
    state['active_workout_id'] = workoutId;
    await _writeState(state);
  }

  Future<Workout?> getActiveWorkout(String userId) async {
    final state = await _readState();
    if (state['user_id'] != userId) return null;
    final activeId = state['active_workout_id'] as String?;
    if (activeId == null) return null;
    return getWorkout(activeId);
  }

  Future<Workout?> getWorkout(String workoutId) async {
    final state = await _readState();
    final workouts = state['workouts'] as Map?;
    final raw = workouts?[workoutId];
    if (raw is! Map) return null;
    return WorkoutLocalSerializer.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<bool> isPendingSync(String workoutId) async {
    final state = await _readState();
    final workouts = state['workouts'] as Map?;
    final raw = workouts?[workoutId];
    if (raw is! Map) return false;
    return raw['pending_sync'] as bool? ?? false;
  }

  Future<bool> wasSyncedToServer(String workoutId) async {
    final state = await _readState();
    final workouts = state['workouts'] as Map?;
    final raw = workouts?[workoutId];
    if (raw is! Map) return false;
    return raw['synced_to_server'] as bool? ?? false;
  }

  Future<void> markSynced(String workoutId) async {
    final state = await _readState();
    final workouts = Map<String, dynamic>.from(state['workouts'] as Map? ?? {});
    final raw = workouts[workoutId];
    if (raw is Map) {
      final copy = Map<String, dynamic>.from(raw);
      copy['pending_sync'] = false;
      copy['synced_to_server'] = true;
      workouts[workoutId] = copy;
      state['workouts'] = workouts;
      await _writeState(state);
    }
  }

  Future<void> removeWorkout(String workoutId) async {
    final state = await _readState();
    final workouts = Map<String, dynamic>.from(state['workouts'] as Map? ?? {});
    workouts.remove(workoutId);
    state['workouts'] = workouts;
    if (state['active_workout_id'] == workoutId) {
      state['active_workout_id'] = null;
    }
    await _writeState(state);
  }

  Future<List<Workout>> pendingWorkouts() async {
    final state = await _readState();
    final workouts = state['workouts'] as Map? ?? {};
    return workouts.values
        .whereType<Map>()
        .map((raw) => WorkoutLocalSerializer.fromJson(Map<String, dynamic>.from(raw)))
        .where((w) => w.completedAt != null)
        .toList();
  }

  Future<List<Workout>> listForUser(
    String userId, {
    int? limit,
    bool completedOnly = false,
  }) async {
    final state = await _readState();
    if (state['user_id'] != userId) return [];

    final workouts = state['workouts'] as Map? ?? {};
    var list = workouts.values
        .whereType<Map>()
        .map((raw) => WorkoutLocalSerializer.fromJson(Map<String, dynamic>.from(raw)))
        .toList();

    if (completedOnly) {
      list = list.where((w) => w.completedAt != null).toList();
    }

    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (limit != null && list.length > limit) {
      list = list.sublist(0, limit);
    }
    return list;
  }

  Future<int> pendingSyncCount() async {
    final state = await _readState();
    final workouts = state['workouts'] as Map? ?? {};
    var count = 0;
    for (final raw in workouts.values) {
      if (raw is! Map) continue;
      if (raw['pending_sync'] as bool? ?? false) {
        final completedAt = raw['completed_at'];
        if (completedAt != null) count++;
      }
    }
    return count;
  }

  Future<void> upsertSet({
    required String workoutId,
    required String workoutExerciseId,
    required WorkoutSet set,
  }) async {
    final workout = await getWorkout(workoutId);
    if (workout == null) return;

    final exercises = workout.exercises.map((ex) {
      if (ex.id != workoutExerciseId) return ex;
      final sets = [...ex.sets];
      final index = sets.indexWhere((s) => s.id == set.id);
      if (index >= 0) {
        sets[index] = set;
      } else {
        sets.add(set);
        sets.sort((a, b) => a.setNumber.compareTo(b.setNumber));
      }
      return WorkoutExercise(
        id: ex.id,
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        imageUrl: ex.imageUrl,
        orderIndex: ex.orderIndex,
        sets: sets,
        notes: ex.notes,
      );
    }).toList();

    await saveWorkout(
      Workout(
        id: workout.id,
        userId: workout.userId,
        routineId: workout.routineId,
        routineName: workout.routineName,
        name: workout.name,
        startedAt: workout.startedAt,
        completedAt: workout.completedAt,
        durationMinutes: workout.durationMinutes,
        activeCaloriesKcal: workout.activeCaloriesKcal,
        exercises: exercises,
        notes: workout.notes,
        totalVolume: workout.totalVolume,
        runnerSurface: workout.runnerSurface,
        runnerRoute: workout.runnerRoute,
        runnerSplits: workout.runnerSplits,
        runnerAvgPaceSecPerKm: workout.runnerAvgPaceSecPerKm,
        runnerElevationGainMeters: workout.runnerElevationGainMeters,
        runnerElevationLossMeters: workout.runnerElevationLossMeters,
      ),
      pendingSync: true,
    );
  }

  Future<void> upsertExercise({
    required String workoutId,
    required WorkoutExercise exercise,
  }) async {
    final workout = await getWorkout(workoutId);
    if (workout == null) return;

    final exercises = [...workout.exercises];
    final index = exercises.indexWhere((e) => e.id == exercise.id);
    if (index >= 0) {
      exercises[index] = exercise;
    } else {
      exercises.add(exercise);
    }
    exercises.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    await saveWorkout(
      Workout(
        id: workout.id,
        userId: workout.userId,
        routineId: workout.routineId,
        routineName: workout.routineName,
        name: workout.name,
        startedAt: workout.startedAt,
        completedAt: workout.completedAt,
        durationMinutes: workout.durationMinutes,
        activeCaloriesKcal: workout.activeCaloriesKcal,
        exercises: exercises,
        notes: workout.notes,
        totalVolume: workout.totalVolume,
        runnerSurface: workout.runnerSurface,
        runnerRoute: workout.runnerRoute,
        runnerSplits: workout.runnerSplits,
        runnerAvgPaceSecPerKm: workout.runnerAvgPaceSecPerKm,
        runnerElevationGainMeters: workout.runnerElevationGainMeters,
        runnerElevationLossMeters: workout.runnerElevationLossMeters,
      ),
      pendingSync: true,
    );
  }
}
