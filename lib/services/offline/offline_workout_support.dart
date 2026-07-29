import 'package:uuid/uuid.dart';

import '../../core/utils/connection_error.dart';
import '../../models/workout.dart';
import 'connectivity_service.dart';
import 'local_workout_store.dart';
import 'routine_cache_store.dart';
import 'sync_outbox.dart';
import 'workout_local_serializer.dart';
import 'workout_sync_service.dart';

/// Coordina persistencia local y cola de sync para entrenamientos.
class OfflineWorkoutSupport {
  OfflineWorkoutSupport({
    required LocalWorkoutStore localStore,
    required SyncOutbox outbox,
    required ConnectivityService connectivity,
    required WorkoutSyncService syncService,
    required PreviousSetsCache previousSetsCache,
  })  : _localStore = localStore,
        _outbox = outbox,
        _connectivity = connectivity,
        _syncService = syncService,
        _previousSetsCache = previousSetsCache;

  final LocalWorkoutStore _localStore;
  final SyncOutbox _outbox;
  final ConnectivityService _connectivity;
  final WorkoutSyncService _syncService;
  final PreviousSetsCache _previousSetsCache;
  final _uuid = const Uuid();

  PreviousSetsCache get previousSetsCache => _previousSetsCache;

  bool get isOnline => _connectivity.isOnline;

  Future<void> triggerSync() => _syncService.syncPending();

  Future<int> pendingSyncCount() async {
    final local = await _localStore.pendingSyncCount();
    final outbox = await _outbox.pendingWorkoutCount();
    return local > outbox ? local : outbox;
  }

  Workout assignClientIds(Workout workout) {
    final exercises = workout.exercises.map((ex) {
      final exId = ex.id.isEmpty ? _uuid.v4() : ex.id;
      final sets = ex.sets.map((set) {
        return WorkoutSet(
          id: set.id.isEmpty ? _uuid.v4() : set.id,
          setNumber: set.setNumber,
          weight: set.weight,
          reps: set.reps,
          rir: set.rir,
          completed: set.completed,
          restTaken: set.restTaken,
          durationSeconds: set.durationSeconds,
          distanceMeters: set.distanceMeters,
          inclinePercent: set.inclinePercent,
          steps: set.steps,
          loggingType: set.loggingType,
        );
      }).toList();
      return WorkoutExercise(
        id: exId,
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        imageUrl: ex.imageUrl,
        orderIndex: ex.orderIndex,
        sets: sets,
        notes: ex.notes,
      );
    }).toList();

    return Workout(
      id: workout.id.isEmpty ? _uuid.v4() : workout.id,
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
    );
  }

  Future<void> markWorkoutSynced(String workoutId) =>
      _localStore.markSynced(workoutId);

  Future<void> persistActiveWorkout(
    Workout workout, {
    bool pendingSync = false,
  }) async {
    await _localStore.saveWorkout(workout, pendingSync: pendingSync);
    await _localStore.setActiveWorkoutId(workout.userId, workout.id);
  }

  Future<void> enqueueStartWorkout(Workout workout) async {
    await _outbox.enqueue(
      type: SyncOperationType.startWorkout,
      workoutId: workout.id,
      payload: {
        'workout': WorkoutLocalSerializer.toJson(workout, pendingSync: true),
      },
      occurredAt: workout.startedAt,
    );
  }

  Future<bool> runRemoteOrQueue(Future<void> Function() remote, {
    required SyncOperationType fallbackType,
    required String workoutId,
    required Map<String, dynamic> payload,
    DateTime? occurredAt,
  }) async {
    if (!_connectivity.isOnline) {
      await _outbox.enqueue(
        type: fallbackType,
        workoutId: workoutId,
        payload: payload,
        occurredAt: occurredAt,
      );
      return false;
    }

    try {
      await remote().timeout(const Duration(seconds: 12));
      return true;
    } catch (e) {
      if (!isConnectionError(e)) rethrow;
      _connectivity.refresh();
    }

    await _outbox.enqueue(
      type: fallbackType,
      workoutId: workoutId,
      payload: payload,
      occurredAt: occurredAt,
    );
    return false;
  }

  Future<Workout?> localActiveWorkout(String userId) =>
      _localStore.getActiveWorkout(userId);

  Future<List<Workout>> localWorkoutSummaries(
    String userId, {
    int limit = 20,
    bool completedOnly = false,
  }) =>
      _localStore.listForUser(userId, limit: limit, completedOnly: completedOnly);

  Future<Workout?> localWorkout(String workoutId) => _localStore.getWorkout(workoutId);

  Future<void> updateLocalSet({
    required String workoutId,
    required String workoutExerciseId,
    required WorkoutSet set,
  }) =>
      _localStore.upsertSet(
        workoutId: workoutId,
        workoutExerciseId: workoutExerciseId,
        set: set,
      );

  Future<void> updateLocalExercise({
    required String workoutId,
    required WorkoutExercise exercise,
  }) =>
      _localStore.upsertExercise(workoutId: workoutId, exercise: exercise);

  Future<void> completeLocal({
    required Workout workout,
    required DateTime completedAt,
    required int durationMinutes,
    required double totalVolume,
    int? activeCaloriesKcal,
  }) async {
    final completed = Workout(
      id: workout.id,
      userId: workout.userId,
      routineId: workout.routineId,
      routineName: workout.routineName,
      name: workout.name,
      startedAt: workout.startedAt,
      completedAt: completedAt,
      durationMinutes: durationMinutes,
      activeCaloriesKcal: activeCaloriesKcal,
      exercises: workout.exercises,
      notes: workout.notes,
      totalVolume: totalVolume,
      runnerSurface: workout.runnerSurface,
      runnerRoute: workout.runnerRoute,
      runnerSplits: workout.runnerSplits,
      runnerAvgPaceSecPerKm: workout.runnerAvgPaceSecPerKm,
      runnerElevationGainMeters: workout.runnerElevationGainMeters,
      runnerElevationLossMeters: workout.runnerElevationLossMeters,
    );
    await _localStore.saveWorkout(completed, pendingSync: true);
    await _localStore.setActiveWorkoutId(workout.userId, null);
  }

  Future<void> enqueueComplete({
    required String workoutId,
    required DateTime completedAt,
    required int durationMinutes,
    required double totalVolume,
    int? activeCaloriesKcal,
  }) async {
    await _outbox.enqueue(
      type: SyncOperationType.completeWorkout,
      workoutId: workoutId,
      payload: {
        'completed_at': completedAt.toUtc().toIso8601String(),
        'duration_minutes': durationMinutes,
        'total_volume': totalVolume,
        if (activeCaloriesKcal != null) 'active_calories_kcal': activeCaloriesKcal,
      },
      occurredAt: completedAt,
    );
  }

  Future<void> cancelLocal(String workoutId, String userId) async {
    await _localStore.removeWorkout(workoutId);
    await _localStore.setActiveWorkoutId(userId, null);
    await _outbox.clearWorkout(workoutId);
  }
}
