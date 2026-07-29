import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/runner/runner_models.dart';
import '../../core/runner/runner_tracking.dart';
import '../../core/utils/supabase_datetime.dart';
import '../../models/workout.dart';
import '../supabase_service.dart';
import 'connectivity_service.dart';
import 'local_workout_store.dart';
import 'sync_outbox.dart';
import 'workout_local_serializer.dart';

/// Sincroniza la cola offline con Supabase.
class WorkoutSyncService {
  WorkoutSyncService({
    required SyncOutbox outbox,
    required LocalWorkoutStore localStore,
    required ConnectivityService connectivity,
    SupabaseClient? client,
  })  : _outbox = outbox,
        _localStore = localStore,
        _connectivity = connectivity,
        _client = client ?? SupabaseService.client;

  final SyncOutbox _outbox;
  final LocalWorkoutStore _localStore;
  final ConnectivityService _connectivity;
  final SupabaseClient _client;
  final _uuid = const Uuid();

  bool _syncing = false;

  Future<int> syncPending({int maxOperations = 50}) async {
    if (_syncing) return 0;
    if (!_connectivity.isOnline) return 0;
    if (SupabaseService.currentUser == null) return 0;

    _syncing = true;
    var synced = 0;
    try {
      final ops = await _outbox.loadAll();
      for (final op in ops.take(maxOperations)) {
        if (!_connectivity.isOnline) break;
        try {
          await _process(op);
          await _outbox.remove(op.id);
          synced++;
        } catch (e) {
          await _outbox.markFailed(op, e);
          continue;
        }
      }
    } finally {
      _syncing = false;
    }
    return synced;
  }

  Future<void> _process(SyncOperation op) async {
    switch (op.type) {
      case SyncOperationType.startWorkout:
        await _syncStartWorkout(op);
      case SyncOperationType.addExercise:
        await _syncAddExercise(op);
      case SyncOperationType.logSet:
        await _syncLogSet(op);
      case SyncOperationType.deleteSet:
        await _syncDeleteSet(op);
      case SyncOperationType.completeWorkout:
        await _syncCompleteWorkout(op);
      case SyncOperationType.cancelWorkout:
        await _syncCancelWorkout(op);
      case SyncOperationType.saveRunnerSession:
        await _syncRunnerSession(op);
    }
  }

  Future<bool> _workoutExists(String workoutId) async {
    final row = await _client.from('workouts').select('id').eq('id', workoutId).maybeSingle();
    return row != null;
  }

  Future<void> _ensureWorkoutFromLocal(String workoutId) async {
    if (await _workoutExists(workoutId)) return;
    final local = await _localStore.getWorkout(workoutId);
    if (local == null) {
      throw StateError('Local workout $workoutId not found for sync');
    }
    await _insertWorkout(local);
  }

  Future<void> _insertWorkout(Workout workout) async {
    await _client.from('workouts').upsert({
      'id': workout.id,
      'user_id': workout.userId,
      'routine_id': workout.routineId,
      'name': workout.name,
      'started_at': workout.startedAt.toUtc().toIso8601String(),
      if (workout.completedAt != null)
        'completed_at': workout.completedAt!.toUtc().toIso8601String(),
      'duration_minutes': workout.durationMinutes,
      'total_volume': workout.totalVolume,
      if (workout.activeCaloriesKcal != null)
        'active_calories_kcal': workout.activeCaloriesKcal,
      'notes': workout.notes,
    });

    for (final ex in workout.exercises) {
      await _insertExercise(workout.id, ex);
    }
  }

  Future<void> _insertExercise(String workoutId, WorkoutExercise exercise) async {
    final exId = exercise.id.isEmpty ? _uuid.v4() : exercise.id;
    await _client.from('workout_exercises').upsert({
      'id': exId,
      'workout_id': workoutId,
      'exercise_id': exercise.exerciseId,
      'exercise_name': exercise.exerciseName,
      'image_url': exercise.imageUrl,
      'order_index': exercise.orderIndex,
      'notes': exercise.notes,
    });

    if (exercise.sets.isEmpty) return;
    final rows = exercise.sets
        .map(
          (set) => {
            'id': set.id.isEmpty ? _uuid.v4() : set.id,
            'workout_exercise_id': exId,
            ...set.toJson(),
          },
        )
        .toList();
    await _client.from('workout_sets').upsert(rows);
  }

  Future<void> _syncStartWorkout(SyncOperation op) async {
    final payload = op.payload;
    if (payload.containsKey('workout')) {
      final workout = WorkoutLocalSerializer.fromJson(
        Map<String, dynamic>.from(payload['workout'] as Map),
      );
      if (!await _workoutExists(workout.id)) {
        await _insertWorkout(workout);
      }
    } else {
      await _ensureWorkoutFromLocal(op.workoutId);
    }
    await _localStore.markSynced(op.workoutId);
  }

  Future<void> _syncAddExercise(SyncOperation op) async {
    await _ensureWorkoutFromLocal(op.workoutId);
    final raw = Map<String, dynamic>.from(op.payload['exercise'] as Map);
    final setsRaw = raw.remove('workout_sets') as List? ?? [];
    final sets = setsRaw
        .whereType<Map>()
        .map((s) => WorkoutSet.fromJson(Map<String, dynamic>.from(s)))
        .toList();
    final exercise = WorkoutExercise.fromJson(raw, sets: sets);
    await _insertExercise(op.workoutId, exercise);
  }

  Future<void> _syncLogSet(SyncOperation op) async {
    await _ensureWorkoutFromLocal(op.workoutId);
    final workoutExerciseId = op.payload['workout_exercise_id'] as String;
    final setMap = Map<String, dynamic>.from(op.payload['set'] as Map);
    final set = WorkoutSet.fromJson(setMap);
    await _client.from('workout_sets').upsert({
      'id': set.id.isEmpty ? _uuid.v4() : set.id,
      'workout_exercise_id': workoutExerciseId,
      ...set.toJson(),
    });
  }

  Future<void> _syncDeleteSet(SyncOperation op) async {
    await _ensureWorkoutFromLocal(op.workoutId);
    final workoutExerciseId = op.payload['workout_exercise_id'] as String;
    final setId = op.payload['set_id'] as String;
    await _client.from('workout_sets').delete().eq('id', setId);

    final data = await _client
        .from('workout_sets')
        .select('id')
        .eq('workout_exercise_id', workoutExerciseId)
        .order('set_number', ascending: true);

    final rows = data as List;
    for (var i = 0; i < rows.length; i++) {
      await _client
          .from('workout_sets')
          .update({'set_number': i + 1})
          .eq('id', (rows[i] as Map<String, dynamic>)['id'] as String);
    }
  }

  Future<void> _syncCompleteWorkout(SyncOperation op) async {
    await _ensureWorkoutFromLocal(op.workoutId);
    await _client.from('workouts').update({
      'completed_at': op.payload['completed_at'] as String? ??
          SupabaseDateTime.nowUtc.toIso8601String(),
      'duration_minutes': op.payload['duration_minutes'] as int? ?? 0,
      'total_volume': op.payload['total_volume'] as num? ?? 0,
      if (op.payload['active_calories_kcal'] != null)
        'active_calories_kcal': op.payload['active_calories_kcal'],
    }).eq('id', op.workoutId);
    await _localStore.markSynced(op.workoutId);
  }

  Future<void> _syncCancelWorkout(SyncOperation op) async {
    if (await _workoutExists(op.workoutId)) {
      await _client.from('workouts').delete().eq('id', op.workoutId);
    }
    await _localStore.removeWorkout(op.workoutId);
  }

  Future<void> _syncRunnerSession(SyncOperation op) async {
    await _ensureWorkoutFromLocal(op.workoutId);
    final routeRaw = op.payload['runner_route'] as List? ?? [];
    final splitsRaw = op.payload['runner_splits'] as List? ?? [];
    final route = routeRaw
        .whereType<Map>()
        .map((p) => RunnerRoutePoint.fromJson(Map<String, dynamic>.from(p)))
        .toList();
    final simplified = RunnerTracking.simplifyRoute(route);
    await _client.from('workouts').update({
      if (op.payload['runner_surface'] != null) 'runner_surface': op.payload['runner_surface'],
      'runner_route': simplified.map((p) => p.toJson()).toList(),
      'runner_splits': splitsRaw,
      if (op.payload['runner_avg_pace_sec_per_km'] != null)
        'runner_avg_pace_sec_per_km': op.payload['runner_avg_pace_sec_per_km'],
      if (op.payload['runner_elevation_gain_m'] != null)
        'runner_elevation_gain_m': op.payload['runner_elevation_gain_m'],
      if (op.payload['runner_elevation_loss_m'] != null)
        'runner_elevation_loss_m': op.payload['runner_elevation_loss_m'],
    }).eq('id', op.workoutId);
  }
}
