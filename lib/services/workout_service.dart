import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/exercise_logging_resolver.dart';
import '../core/utils/muscle_inference.dart';
import '../core/utils/milestones.dart';
import '../core/utils/previous_set_utils.dart';
import '../models/exercise.dart';
import '../models/exercise_history.dart';
import '../models/exercise_logging.dart';
import '../models/profile.dart';
import '../core/utils/supabase_datetime.dart';
import '../models/workout.dart';
import 'supabase_service.dart';

class WorkoutService {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

  Future<List<Workout>> getWorkoutSummaries({int limit = 20}) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final workoutsData = await _client
        .from('workouts')
        .select('*, routines(name)')
        .eq('user_id', userId)
        .order('started_at', ascending: false)
        .limit(limit);

    return (workoutsData as List).map((w) {
      final map = Map<String, dynamic>.from(w as Map);
      if (map['routines'] != null) {
        map['routine_name'] = (map['routines'] as Map)['name'];
      }
      return Workout.fromJson(map, exercises: const []);
    }).toList();
  }

  /// Entrenos completados en un día (sin ejercicios/series — para presupuesto calórico de Comida).
  Future<List<Workout>> getCompletedWorkoutsOnDay(DateTime day) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final workoutsData = await _client
        .from('workouts')
        .select(
          'id, user_id, name, started_at, completed_at, duration_minutes, total_volume, active_calories_kcal, notes',
        )
        .eq('user_id', userId)
        .gte('completed_at', start.toUtc().toIso8601String())
        .lt('completed_at', end.toUtc().toIso8601String())
        .order('completed_at', ascending: true);

    return (workoutsData as List)
        .map(
          (w) => Workout.fromJson(
            Map<String, dynamic>.from(w as Map),
            exercises: const [],
          ),
        )
        .toList();
  }

  /// Totales acumulados para milestones (incluye reps y distancia de todas las series).
  Future<MilestoneTotals> getMilestoneTotals({UserProfile? profile}) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return MilestoneTotals.empty;

    final workoutsData = await _client
        .from('workouts')
        .select('id, duration_minutes, total_volume, completed_at')
        .eq('user_id', userId)
        .not('completed_at', 'is', null);

    final workoutRows = (workoutsData as List).cast<Map<String, dynamic>>();
    if (workoutRows.isEmpty) return MilestoneTotals.empty;

    final workoutIds = workoutRows.map((w) => w['id'] as String).toList();
    var totalReps = 0;
    var totalDistance = 0.0;

    for (final workoutChunk in _chunkIds(workoutIds)) {
      final exercisesData = await _client
          .from('workout_exercises')
          .select('id')
          .inFilter('workout_id', workoutChunk);

      final exerciseIds = (exercisesData as List)
          .map((row) => (row as Map<String, dynamic>)['id'] as String)
          .toList();
      if (exerciseIds.isEmpty) continue;

      for (final exerciseChunk in _chunkIds(exerciseIds, size: 200)) {
        final setsData = await _client
            .from('workout_sets')
            .select('reps, distance_meters, logging_type, completed')
            .inFilter('workout_exercise_id', exerciseChunk);

        for (final row in setsData as List) {
          final map = row as Map<String, dynamic>;
          if (map['completed'] != true) continue;
          final loggingType = ExerciseLoggingType.fromJson(map['logging_type'] as String?);
          if (loggingType == ExerciseLoggingType.strength) {
            totalReps += map['reps'] as int? ?? 0;
          } else {
            final distance = (map['distance_meters'] as num?)?.toDouble();
            if (distance != null && distance > 0) {
              totalDistance += distance;
            }
          }
        }
      }
    }

    return MilestonesCalculator.fromFriendData(
      {
        'workouts': workoutRows
            .map(
              (w) => {
                'duration_minutes': w['duration_minutes'],
                'total_volume': w['total_volume'],
                'completed_at': w['completed_at'],
              },
            )
            .toList(),
        'total_reps': totalReps,
        'total_distance_meters': totalDistance,
      },
      profile: profile,
    );
  }

  static List<List<String>> _chunkIds(List<String> ids, {int size = 100}) {
    if (ids.isEmpty) return const [];
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += size) {
      chunks.add(ids.sublist(i, i + size > ids.length ? ids.length : i + size));
    }
    return chunks;
  }

  Future<List<Workout>> getWorkouts({int limit = 20}) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final workoutsData = await _client
        .from('workouts')
        .select('*, routines(name)')
        .eq('user_id', userId)
        .order('started_at', ascending: false)
        .limit(limit);

    final workouts = <Workout>[];
    for (final w in workoutsData as List) {
      final map = Map<String, dynamic>.from(w as Map);
      if (map['routines'] != null) {
        map['routine_name'] = (map['routines'] as Map)['name'];
      }
      final exercises = await _getWorkoutExercises(map['id'] as String);
      workouts.add(Workout.fromJson(map, exercises: exercises));
    }
    return workouts;
  }

  /// Solo entrenos completados recientes, con consultas en lote (para recuperación muscular).
  Future<List<Workout>> getWorkoutsForMuscleRecovery({int limit = 10}) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final workoutsData = await _client
        .from('workouts')
        .select(
          'id, user_id, routine_id, name, started_at, completed_at, duration_minutes, total_volume, notes',
        )
        .eq('user_id', userId)
        .not('completed_at', 'is', null)
        .order('completed_at', ascending: false)
        .limit(limit);

    final workoutRows = workoutsData as List;
    if (workoutRows.isEmpty) return [];

    final workoutIds = workoutRows.map((w) => (w as Map)['id'] as String).toList();

    final exercisesData = await _client
        .from('workout_exercises')
        .select('id, workout_id, exercise_id, exercise_name, order_index')
        .inFilter('workout_id', workoutIds);

    final exerciseRows = exercisesData as List;
    if (exerciseRows.isEmpty) {
      return workoutRows
          .map((w) => Workout.fromJson(Map<String, dynamic>.from(w as Map), exercises: const []))
          .toList();
    }

    final exerciseIds = exerciseRows.map((e) => (e as Map)['id'] as String).toList();

    final setsData = await _client
        .from('workout_sets')
        .select('workout_exercise_id, set_number, completed')
        .inFilter('workout_exercise_id', exerciseIds);

    final setsByExercise = <String, List<WorkoutSet>>{};
    for (final row in setsData as List) {
      final map = row as Map<String, dynamic>;
      final exId = map['workout_exercise_id'] as String;
      setsByExercise.putIfAbsent(exId, () => []).add(
            WorkoutSet(
              id: '',
              setNumber: map['set_number'] as int? ?? 1,
              completed: map['completed'] as bool? ?? false,
            ),
          );
    }

    final exercisesByWorkout = <String, List<WorkoutExercise>>{};
    for (final row in exerciseRows) {
      final map = row as Map<String, dynamic>;
      final workoutId = map['workout_id'] as String;
      final exRowId = map['id'] as String;
      exercisesByWorkout.putIfAbsent(workoutId, () => []).add(
            WorkoutExercise(
              id: exRowId,
              exerciseId: map['exercise_id'] as String,
              exerciseName: map['exercise_name'] as String? ?? '',
              orderIndex: map['order_index'] as int? ?? 0,
              sets: setsByExercise[exRowId] ?? const [],
            ),
          );
    }

    for (final list in exercisesByWorkout.values) {
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }

    return workoutRows.map((w) {
      final map = Map<String, dynamic>.from(w as Map);
      final id = map['id'] as String;
      return Workout.fromJson(map, exercises: exercisesByWorkout[id] ?? const []);
    }).toList();
  }

  Future<List<DateTime>> getCompletedWorkoutTimestamps() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('workouts')
        .select('completed_at')
        .eq('user_id', userId)
        .not('completed_at', 'is', null)
        .order('completed_at', ascending: false);

    return (data as List)
        .map((row) => SupabaseDateTime.parse((row as Map<String, dynamic>)['completed_at'] as String))
        .toList();
  }

  Future<Workout?> getActiveWorkout() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;

    final rows = await _client
        .from('workouts')
        .select()
        .eq('user_id', userId)
        .filter('completed_at', 'is', null)
        .order('started_at', ascending: false);

    final list = rows as List;
    if (list.isEmpty) return null;

    final active = Map<String, dynamic>.from(list.first as Map);
    final activeId = active['id'] as String;

    if (list.length > 1) {
      await _closeStaleActiveWorkouts(userId, keepWorkoutId: activeId);
    }

    final exercises = await _getWorkoutExercises(activeId);
    return Workout.fromJson(active, exercises: exercises);
  }

  Future<void> _closeStaleActiveWorkouts(String userId, {String? keepWorkoutId}) async {
    var query = _client
        .from('workouts')
        .update({
          'completed_at': SupabaseDateTime.nowUtc.toIso8601String(),
          'duration_minutes': 0,
        })
        .eq('user_id', userId)
        .filter('completed_at', 'is', null);

    if (keepWorkoutId != null) {
      query = query.neq('id', keepWorkoutId);
    }

    await query;
  }

  Future<List<WorkoutExercise>> _getWorkoutExercises(String workoutId) async {
    final exercisesData = await _client
        .from('workout_exercises')
        .select('*, workout_sets(*)')
        .eq('workout_id', workoutId)
        .order('order_index', ascending: true);

    final exercises = <WorkoutExercise>[];
    for (final ex in exercisesData as List) {
      final exMap = Map<String, dynamic>.from(ex as Map);
      final setsRaw = exMap.remove('workout_sets') as List? ?? [];
      final sets = setsRaw
          .map((s) => WorkoutSet.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList()
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

      exercises.add(WorkoutExercise.fromJson(exMap, sets: sets));
    }
    exercises.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return exercises;
  }

  Future<Workout> startWorkout({
    required String name,
    String? routineId,
    List<WorkoutExercise>? exercises,
    Future<List<WorkoutExercise>> Function(
      List<WorkoutExercise> locallyEnriched,
      String workoutId,
    )? applyProactiveSuggestions,
  }) async {
    final userId = SupabaseService.currentUser!.id;
    await _closeStaleActiveWorkouts(userId);

    final workoutId = _uuid.v4();

    await _client.from('workouts').insert({
      'id': workoutId,
      'user_id': userId,
      'routine_id': routineId,
      'name': name,
      'started_at': SupabaseDateTime.nowUtc.toIso8601String(),
    });

    var workoutExercises = exercises;
    if (workoutExercises != null) {
      var enriched = await _applyPreviousSetSuggestions(
        workoutExercises,
        excludeWorkoutId: workoutId,
      );
      if (applyProactiveSuggestions != null) {
        try {
          enriched = await applyProactiveSuggestions(enriched, workoutId);
        } catch (_) {
          // Mantiene sugerencias locales si la IA falla.
        }
      }
      for (final ex in enriched) {
        await _addExerciseToWorkout(workoutId, ex);
      }
      workoutExercises = enriched;
    }

    return Workout(
      id: workoutId,
      userId: userId,
      routineId: routineId,
      name: name,
      startedAt: SupabaseDateTime.nowUtc,
      exercises: workoutExercises ?? [],
    );
  }

  Future<List<WorkoutExercise>> _applyPreviousSetSuggestions(
    List<WorkoutExercise> exercises, {
    String? excludeWorkoutId,
  }) async {
    final result = <WorkoutExercise>[];
    for (final ex in exercises) {
      final previous = await getPreviousSetsForExercise(
        ex.exerciseId,
        excludeWorkoutId: excludeWorkoutId,
      );
      if (previous == null || previous.isEmpty) {
        result.add(ex);
        continue;
      }

      final isCardio = ExerciseLoggingResolver.isCardioExercise(
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        sets: ex.sets,
      );

      final templates = [...ex.sets]..sort((a, b) => a.setNumber.compareTo(b.setNumber));
      final setCount = PreviousSetUtils.resolveSetCount(
        templateCount: templates.length,
        previous: previous,
      );

      final sets = List.generate(setCount, (i) {
        final setNumber = i + 1;
        final template = PreviousSetUtils.forSetNumber(templates, setNumber) ??
            (templates.isNotEmpty ? templates.last : null);
        final prev = PreviousSetUtils.forSetNumber(previous, setNumber);
        return WorkoutSet(
          id: '',
          setNumber: setNumber,
          weight: isCardio ? null : (prev?.weight ?? template?.weight),
          reps: isCardio ? 0 : ((prev?.reps ?? 0) > 0 ? prev!.reps : (template?.reps ?? 10)),
          durationSeconds: isCardio
              ? (prev?.durationSeconds ?? template?.durationSeconds)
              : null,
          distanceMeters: isCardio
              ? (prev?.distanceMeters ?? template?.distanceMeters)
              : null,
          inclinePercent: isCardio
              ? (prev?.inclinePercent ?? template?.inclinePercent)
              : null,
          steps: isCardio ? (prev?.steps ?? template?.steps) : null,
          loggingType: isCardio
              ? ExerciseLoggingType.cardio
              : (prev != null && prev.loggingType != ExerciseLoggingType.strength
                  ? prev.loggingType
                  : template?.loggingType ?? ExerciseLoggingType.strength),
        );
      });

      result.add(WorkoutExercise(
        id: ex.id,
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        imageUrl: ex.imageUrl,
        orderIndex: ex.orderIndex,
        sets: sets,
        notes: ex.notes,
      ));
    }
    return result;
  }

  Future<List<ExerciseSessionHistory>> getExerciseHistory(
    String exerciseId, {
    int limit = 5,
    String? excludeWorkoutId,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('workout_exercises')
        .select('id, workouts!inner(id, name, completed_at)')
        .eq('exercise_id', exerciseId)
        .not('workouts.completed_at', 'is', null);

    final entries = <({String weId, Map<String, dynamic> workout})>[];
    for (final row in data as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final workout = Map<String, dynamic>.from(map['workouts'] as Map);
      final wId = workout['id'] as String;
      if (excludeWorkoutId != null && wId == excludeWorkoutId) continue;
      entries.add((weId: map['id'] as String, workout: workout));
    }

    entries.sort((a, b) {
      final aDate = SupabaseDateTime.parse(a.workout['completed_at'] as String);
      final bDate = SupabaseDateTime.parse(b.workout['completed_at'] as String);
      return bDate.compareTo(aDate);
    });

    final history = <ExerciseSessionHistory>[];
    for (final entry in entries.take(limit)) {
      final setsData = await _client
          .from('workout_sets')
          .select()
          .eq('workout_exercise_id', entry.weId)
          .order('set_number', ascending: true);

      final sets = (setsData as List)
          .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
          .toList();
      final meaningful = PreviousSetUtils.sortedMeaningfulSets(sets);
      if (meaningful.isEmpty) continue;

      history.add(ExerciseSessionHistory(
        workoutId: entry.workout['id'] as String,
        workoutName: entry.workout['name'] as String? ?? 'Entrenamiento',
        date: SupabaseDateTime.parse(entry.workout['completed_at'] as String),
        sets: meaningful,
      ));
    }
    return history;
  }

  Future<List<WorkoutSet>?> getPreviousSetsForExercise(
    String exerciseId, {
    String? excludeWorkoutId,
  }) async {
    final entry = await _lastCompletedWorkoutExerciseEntry(
      exerciseId,
      excludeWorkoutId: excludeWorkoutId,
    );
    if (entry == null) return null;

    final setsData = await _client
        .from('workout_sets')
        .select()
        .eq('workout_exercise_id', entry.weId)
        .order('set_number', ascending: true);

    final sets = (setsData as List)
        .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
        .toList();
    if (sets.isEmpty) return null;
    return PreviousSetUtils.sortedBySetNumber(sets);
  }

  Future<({String weId, Map<String, dynamic> workout})?> _lastCompletedWorkoutExerciseEntry(
    String exerciseId, {
    String? excludeWorkoutId,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('workout_exercises')
        .select('id, workouts!inner(id, name, completed_at)')
        .eq('exercise_id', exerciseId)
        .not('workouts.completed_at', 'is', null);

    final entries = <({String weId, Map<String, dynamic> workout})>[];
    for (final row in data as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final workout = Map<String, dynamic>.from(map['workouts'] as Map);
      final wId = workout['id'] as String;
      if (excludeWorkoutId != null && wId == excludeWorkoutId) continue;
      entries.add((weId: map['id'] as String, workout: workout));
    }

    if (entries.isEmpty) return null;

    entries.sort((a, b) {
      final aDate = SupabaseDateTime.parse(a.workout['completed_at'] as String);
      final bDate = SupabaseDateTime.parse(b.workout['completed_at'] as String);
      return bDate.compareTo(aDate);
    });

    return entries.first;
  }

  /// Expuesto para pantallas que añaden series durante el entreno.
  WorkoutSet? previousSetForNumber(List<WorkoutSet> previous, int setNumber) {
    return PreviousSetUtils.forSetNumber(previous, setNumber);
  }

  Future<WorkoutExercise> addExerciseToWorkout(
    String workoutId, {
    required String exerciseId,
    required String exerciseName,
    String? imageUrl,
    int defaultSets = 3,
    int defaultReps = 10,
    ExerciseLoggingType loggingType = ExerciseLoggingType.strength,
  }) async {
    final resolvedType = ExerciseLoggingResolver.resolveLoggingType(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      explicit: loggingType,
    );
    final isCardio = resolvedType == ExerciseLoggingType.cardio;
    final existing = await _getWorkoutExercises(workoutId);
    final nextOrder = existing.isEmpty
        ? 0
        : existing.map((e) => e.orderIndex).reduce((a, b) => a > b ? a : b) + 1;

    final previous = await getPreviousSetsForExercise(exerciseId, excludeWorkoutId: workoutId);
    final setCount = PreviousSetUtils.resolveSetCount(
      templateCount: defaultSets,
      previous: previous,
    );
    final sets = List.generate(setCount, (i) {
      final setNumber = i + 1;
      final prev = previous != null
          ? PreviousSetUtils.forSetNumber(previous, setNumber)
          : null;
      return WorkoutSet(
        id: '',
        setNumber: i + 1,
        weight: isCardio ? null : prev?.weight,
        reps: isCardio ? 0 : ((prev?.reps ?? 0) > 0 ? prev!.reps : defaultReps),
        durationSeconds: isCardio ? prev?.durationSeconds : null,
        distanceMeters: isCardio ? prev?.distanceMeters : null,
        inclinePercent: isCardio ? prev?.inclinePercent : null,
        steps: isCardio ? prev?.steps : null,
        loggingType: resolvedType,
      );
    });

    final exercise = WorkoutExercise(
      id: _uuid.v4(),
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      imageUrl: imageUrl,
      orderIndex: nextOrder,
      sets: sets,
    );

    await _addExerciseToWorkout(workoutId, exercise);
    return exercise;
  }

  Future<void> swapExerciseInWorkout(
    String workoutExerciseId,
    String workoutId, {
    required String newExerciseId,
    required String newExerciseName,
    String? newImageUrl,
  }) async {
    final exercises = await _getWorkoutExercises(workoutId);
    final current = exercises.firstWhere((e) => e.id == workoutExerciseId);
    final templateSetCount = current.sets.isEmpty ? 3 : current.sets.length;

    await _client.from('workout_exercises').update({
      'exercise_id': newExerciseId,
      'exercise_name': newExerciseName,
      'image_url': newImageUrl,
    }).eq('id', workoutExerciseId);

    await _client.from('workout_sets').delete().eq('workout_exercise_id', workoutExerciseId);

    final previous = await getPreviousSetsForExercise(newExerciseId, excludeWorkoutId: workoutId);
    final isCardio = ExerciseLoggingResolver.isCardioExercise(
      exerciseId: newExerciseId,
      exerciseName: newExerciseName,
    );
    final resolvedSetCount = PreviousSetUtils.resolveSetCount(
      templateCount: templateSetCount,
      previous: previous,
    );
    final sets = List.generate(resolvedSetCount, (i) {
      final setNumber = i + 1;
      final prev = previous != null
          ? PreviousSetUtils.forSetNumber(previous, setNumber)
          : null;
      final oldSet = PreviousSetUtils.forSetNumber(current.sets, setNumber);
      return WorkoutSet(
        id: _uuid.v4(),
        setNumber: i + 1,
        weight: isCardio ? null : (prev?.weight ?? oldSet?.weight),
        reps: isCardio ? 0 : ((prev?.reps ?? 0) > 0 ? prev!.reps : (oldSet?.reps ?? 10)),
        durationSeconds: isCardio ? prev?.durationSeconds : null,
        distanceMeters: isCardio ? prev?.distanceMeters : null,
        inclinePercent: isCardio ? prev?.inclinePercent : null,
        steps: isCardio ? prev?.steps : null,
        loggingType: isCardio ? ExerciseLoggingType.cardio : ExerciseLoggingType.strength,
      );
    });

    for (final set in sets) {
      await _client.from('workout_sets').insert({
        'id': set.id,
        'workout_exercise_id': workoutExerciseId,
        ...set.toJson(),
      });
    }
  }

  Future<void> reorderWorkoutExercises(
    String workoutId,
    List<String> orderedExerciseIds,
  ) async {
    await Future.wait([
      for (var i = 0; i < orderedExerciseIds.length; i++)
        _client
            .from('workout_exercises')
            .update({'order_index': i})
            .eq('id', orderedExerciseIds[i])
            .eq('workout_id', workoutId),
    ]);
  }

  Future<void> removeExerciseFromWorkout(String workoutExerciseId) async {
    final row = await _client
        .from('workout_exercises')
        .select('workout_id')
        .eq('id', workoutExerciseId)
        .maybeSingle();
    if (row == null) return;

    final workoutId = row['workout_id'] as String;
    await _client.from('workout_exercises').delete().eq('id', workoutExerciseId);

    final remaining = await _client
        .from('workout_exercises')
        .select('id')
        .eq('workout_id', workoutId)
        .order('order_index', ascending: true);

    final rows = remaining as List;
    for (var i = 0; i < rows.length; i++) {
      await _client
          .from('workout_exercises')
          .update({'order_index': i})
          .eq('id', (rows[i] as Map<String, dynamic>)['id'] as String);
    }
  }

  Future<void> _addExerciseToWorkout(String workoutId, WorkoutExercise exercise) async {
    final exId = exercise.id.isEmpty ? _uuid.v4() : exercise.id;
    await _client.from('workout_exercises').insert({
      'id': exId,
      'workout_id': workoutId,
      'exercise_id': exercise.exerciseId,
      'exercise_name': exercise.exerciseName,
      'image_url': exercise.imageUrl,
      'order_index': exercise.orderIndex,
      'notes': exercise.notes,
    });

    if (exercise.sets.isNotEmpty) {
      final setRows = exercise.sets
          .map(
            (set) => {
              'id': set.id.isEmpty ? _uuid.v4() : set.id,
              'workout_exercise_id': exId,
              ...set.toJson(),
            },
          )
          .toList();
      await _client.from('workout_sets').insert(setRows);
    }
  }

  Future<void> completeWorkout(
    String workoutId, {
    int durationMinutes = 0,
    double totalVolume = 0,
    int? activeCaloriesKcal,
  }) async {
    await _client.from('workouts').update({
      'completed_at': SupabaseDateTime.nowUtc.toIso8601String(),
      'duration_minutes': durationMinutes,
      'total_volume': totalVolume,
      if (activeCaloriesKcal != null) 'active_calories_kcal': activeCaloriesKcal,
    }).eq('id', workoutId);

    await _updatePersonalRecords(workoutId);
  }

  /// Elimina un entrenamiento en curso sin guardarlo en el historial.
  Future<void> cancelWorkout(String workoutId) async {
    await _client.from('workouts').delete().eq('id', workoutId);
  }

  /// Último entrenamiento completado de la misma rutina (excluye el actual).
  Future<Workout?> getPreviousRoutineWorkout({
    required String? routineId,
    required String excludeWorkoutId,
  }) async {
    if (routineId == null || routineId.isEmpty) return null;

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;

    final rows = await _client
        .from('workouts')
        .select('*, routines(name)')
        .eq('user_id', userId)
        .eq('routine_id', routineId)
        .not('completed_at', 'is', null)
        .neq('id', excludeWorkoutId)
        .order('completed_at', ascending: false)
        .limit(1);

    final list = rows as List;
    if (list.isEmpty) return null;

    final map = Map<String, dynamic>.from(list.first as Map);
    if (map['routines'] != null) {
      map['routine_name'] = (map['routines'] as Map)['name'];
    }
    final exercises = await _getWorkoutExercises(map['id'] as String);
    return Workout.fromJson(map, exercises: exercises);
  }

  Future<void> _updatePersonalRecords(String workoutId) async {
    final userId = SupabaseService.currentUser!.id;
    final exercises = await _getWorkoutExercises(workoutId);

    for (final ex in exercises) {
      final completedSets = ex.sets.where((s) => s.completed).toList();
      if (completedSets.isEmpty) continue;

      final strengthSets = completedSets.where((s) => !s.isCardio && s.weight != null).toList();
      for (final set in strengthSets) {
        final oneRm = PersonalRecord.calculate1RM(set.weight!, set.reps);
        await _upsertPersonalRecord(
          userId: userId,
          exerciseId: ex.exerciseId,
          exerciseName: ex.exerciseName,
          recordType: PersonalRecordType.strength,
          payload: {
            'weight': set.weight,
            'reps': set.reps,
            'one_rep_max': oneRm,
          },
          isBetter: (existing) =>
              existing == null ||
              ((existing['one_rep_max'] as num?)?.toDouble() ?? 0) < oneRm,
        );
      }

      final cardioSets = completedSets.where((s) => s.isCardio).toList();
      if (cardioSets.isEmpty) continue;

      final maxDistance = cardioSets
          .map((s) => s.distanceMeters)
          .whereType<double>()
          .fold<double?>(null, (best, v) => best == null || v > best ? v : best);
      if (maxDistance != null) {
        await _upsertPersonalRecord(
          userId: userId,
          exerciseId: ex.exerciseId,
          exerciseName: ex.exerciseName,
          recordType: PersonalRecordType.cardioDistance,
          payload: {'distance_meters': maxDistance},
          isBetter: (existing) =>
              existing == null ||
              (existing['distance_meters'] as num?)?.toDouble() == null ||
              (existing['distance_meters'] as num).toDouble() < maxDistance,
        );
      }

      final maxDuration = cardioSets
          .map((s) => s.durationSeconds)
          .whereType<int>()
          .fold<int?>(null, (best, v) => best == null || v > best ? v : best);
      if (maxDuration != null) {
        await _upsertPersonalRecord(
          userId: userId,
          exerciseId: ex.exerciseId,
          exerciseName: ex.exerciseName,
          recordType: PersonalRecordType.cardioDuration,
          payload: {'duration_seconds': maxDuration},
          isBetter: (existing) =>
              existing == null ||
              (existing['duration_seconds'] as int?) == null ||
              (existing['duration_seconds'] as int) < maxDuration,
        );
      }

      final maxSteps = cardioSets
          .map((s) => s.steps)
          .whereType<int>()
          .fold<int?>(null, (best, v) => best == null || v > best ? v : best);
      if (maxSteps != null) {
        await _upsertPersonalRecord(
          userId: userId,
          exerciseId: ex.exerciseId,
          exerciseName: ex.exerciseName,
          recordType: PersonalRecordType.cardioSteps,
          payload: {'steps': maxSteps},
          isBetter: (existing) =>
              existing == null ||
              (existing['steps'] as int?) == null ||
              (existing['steps'] as int) < maxSteps,
        );
      }

      final maxIncline = cardioSets
          .map((s) => s.inclinePercent)
          .whereType<double>()
          .fold<double?>(null, (best, v) => best == null || v > best ? v : best);
      if (maxIncline != null) {
        final config = ExerciseLoggingResolver.cardioConfigFor(
          exerciseId: ex.exerciseId,
          exerciseName: ex.exerciseName,
        );
        if (config.tracksDifficulty) {
          await _upsertPersonalRecord(
            userId: userId,
            exerciseId: ex.exerciseId,
            exerciseName: ex.exerciseName,
            recordType: PersonalRecordType.cardioDifficulty,
            payload: {'incline_percent': maxIncline},
            isBetter: (existing) =>
                existing == null ||
                (existing['incline_percent'] as num?)?.toDouble() == null ||
                (existing['incline_percent'] as num).toDouble() < maxIncline,
          );
        } else if (config.tracksIncline) {
          await _upsertPersonalRecord(
            userId: userId,
            exerciseId: ex.exerciseId,
            exerciseName: ex.exerciseName,
            recordType: PersonalRecordType.cardioIncline,
            payload: {'incline_percent': maxIncline},
            isBetter: (existing) =>
                existing == null ||
                (existing['incline_percent'] as num?)?.toDouble() == null ||
                (existing['incline_percent'] as num).toDouble() < maxIncline,
          );
        }
      }
    }
  }

  Future<void> _upsertPersonalRecord({
    required String userId,
    required String exerciseId,
    required String exerciseName,
    required PersonalRecordType recordType,
    required Map<String, dynamic> payload,
    required bool Function(Map<String, dynamic>? existing) isBetter,
  }) async {
    final existing = await _client
        .from('personal_records')
        .select()
        .eq('user_id', userId)
        .eq('exercise_id', exerciseId)
        .eq('record_type', recordType.toJson())
        .maybeSingle();

    if (!isBetter(existing == null ? null : Map<String, dynamic>.from(existing))) {
      return;
    }

    await _client.from('personal_records').upsert(
      {
        'user_id': userId,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'record_type': recordType.toJson(),
        'achieved_at': SupabaseDateTime.nowUtc.toIso8601String(),
        ...payload,
      },
      onConflict: 'user_id,exercise_id,record_type',
    );
  }

  Future<void> logSet(String workoutExerciseId, WorkoutSet set) async {
    await _client.from('workout_sets').upsert({
      'id': set.id.isEmpty ? _uuid.v4() : set.id,
      'workout_exercise_id': workoutExerciseId,
      ...set.toJson(),
    });
  }

  Future<void> deleteSet(String workoutExerciseId, String setId) async {
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

  Future<List<PersonalRecord>> getPersonalRecords() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('personal_records')
        .select()
        .eq('user_id', userId)
        .order('achieved_at', ascending: false);

    return (data as List)
        .map((r) => PersonalRecord.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<BodyMeasurement>> getBodyMeasurements({String type = 'weight'}) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('body_measurements')
        .select()
        .eq('user_id', userId)
        .eq('type', type)
        .order('measured_at', ascending: false)
        .limit(30);

    return (data as List)
        .map((m) => BodyMeasurement.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> addBodyMeasurement(BodyMeasurement measurement) async {
    final userId = SupabaseService.currentUser!.id;
    await _client.from('body_measurements').insert({
      'id': _uuid.v4(),
      'user_id': userId,
      ...measurement.toJson(),
    });
  }

  Map<String, double> calculateMuscleRecovery(
    List<Workout> recentWorkouts, {
    List<Exercise>? catalog,
  }) {
    final recovery = <String, double>{};
    final now = DateTime.now();

    for (final muscle in AppConstants.muscleGroups) {
      if (muscle == 'Cardio') continue;
      recovery[muscle] = 100.0;
    }

    for (final workout in recentWorkouts.where((w) => w.completedAt != null)) {
      final hoursSince = now.difference(workout.completedAt!).inMinutes / 60.0;

      for (final ex in workout.exercises) {
        final completedSets = ex.sets.where((s) => s.completed).length;
        if (completedSets == 0) continue;

        final muscles = MuscleInference.resolve(
          exerciseName: ex.exerciseName,
          exerciseId: ex.exerciseId,
          catalog: catalog,
        );
        if (muscles.isEmpty) continue;

        // Más series = mayor fatiga inicial (mín. 50 %, máx. 100 %).
        final fatigueDepth = (0.5 + (completedSets.clamp(1, 6) / 6.0) * 0.5).clamp(0.5, 1.0);

        for (final muscle in muscles) {
          if (!recovery.containsKey(muscle)) continue;

          final recoveryHours = _recoveryHours(muscle);
          final timeRecovery = (hoursSince / recoveryHours * 100).clamp(0.0, 100.0);
          final muscleRecovery = timeRecovery + (100 - timeRecovery) * (1 - fatigueDepth);

          recovery[muscle] = recovery[muscle]!.clamp(0.0, muscleRecovery);
        }
      }
    }

    return recovery;
  }

  double _recoveryHours(String muscle) {
    return AppConstants.muscleRecoveryHours[muscle]?.toDouble() ?? 48.0;
  }
}
