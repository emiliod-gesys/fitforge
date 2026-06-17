import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/muscle_inference.dart';
import '../models/exercise_history.dart';
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
        .select()
        .eq('workout_id', workoutId)
        .order('order_index', ascending: true);

    final exercises = <WorkoutExercise>[];
    for (final ex in exercisesData as List) {
      final exMap = ex as Map<String, dynamic>;
      final setsData = await _client
          .from('workout_sets')
          .select()
          .eq('workout_exercise_id', exMap['id'])
          .order('set_number', ascending: true);

      final sets = (setsData as List)
          .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
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
      final enriched = await _applyPreviousSetSuggestions(
        workoutExercises,
        excludeWorkoutId: workoutId,
      );
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

      final sets = List.generate(ex.sets.length, (i) {
        final template = ex.sets[i];
        final prev = i < previous.length ? previous[i] : previous.last;
        return WorkoutSet(
          id: '',
          setNumber: template.setNumber,
          weight: prev.weight ?? template.weight,
          reps: prev.reps > 0 ? prev.reps : template.reps,
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
          .order('set_number');

      final sets = (setsData as List)
          .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
          .toList();
      final meaningful = _meaningfulSets(sets);
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
    final history = await getExerciseHistory(
      exerciseId,
      limit: 1,
      excludeWorkoutId: excludeWorkoutId,
    );
    if (history.isEmpty) return null;
    return history.first.sets;
  }

  List<WorkoutSet> _meaningfulSets(List<WorkoutSet> sets) {
    final completed = sets.where((s) => s.completed).toList();
    final source = completed.isNotEmpty ? completed : sets;
    return source.where((s) => s.weight != null || s.reps > 0).toList();
  }

  Future<WorkoutExercise> addExerciseToWorkout(
    String workoutId, {
    required String exerciseId,
    required String exerciseName,
    String? imageUrl,
    int defaultSets = 3,
    int defaultReps = 10,
  }) async {
    final existing = await _getWorkoutExercises(workoutId);
    final nextOrder = existing.isEmpty
        ? 0
        : existing.map((e) => e.orderIndex).reduce((a, b) => a > b ? a : b) + 1;

    final previous = await getPreviousSetsForExercise(exerciseId, excludeWorkoutId: workoutId);
    final sets = List.generate(defaultSets, (i) {
      final prev = previous != null && previous.isNotEmpty
          ? (i < previous.length ? previous[i] : previous.last)
          : null;
      return WorkoutSet(
        id: '',
        setNumber: i + 1,
        weight: prev?.weight,
        reps: (prev?.reps ?? 0) > 0 ? prev!.reps : defaultReps,
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
    final setCount = current.sets.isEmpty ? 3 : current.sets.length;

    await _client.from('workout_exercises').update({
      'exercise_id': newExerciseId,
      'exercise_name': newExerciseName,
      'image_url': newImageUrl,
    }).eq('id', workoutExerciseId);

    await _client.from('workout_sets').delete().eq('workout_exercise_id', workoutExerciseId);

    final previous = await getPreviousSetsForExercise(newExerciseId, excludeWorkoutId: workoutId);
    final sets = List.generate(setCount, (i) {
      final prev = previous != null && previous.isNotEmpty
          ? (i < previous.length ? previous[i] : previous.last)
          : null;
      final oldSet = i < current.sets.length ? current.sets[i] : null;
      return WorkoutSet(
        id: _uuid.v4(),
        setNumber: i + 1,
        weight: prev?.weight ?? oldSet?.weight,
        reps: (prev?.reps ?? 0) > 0 ? prev!.reps : (oldSet?.reps ?? 10),
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

    for (final set in exercise.sets) {
      await _client.from('workout_sets').insert({
        'id': set.id.isEmpty ? _uuid.v4() : set.id,
        'workout_exercise_id': exId,
        ...set.toJson(),
      });
    }
  }

  Future<void> completeWorkout(String workoutId, {int durationMinutes = 0, double totalVolume = 0}) async {
    await _client.from('workouts').update({
      'completed_at': SupabaseDateTime.nowUtc.toIso8601String(),
      'duration_minutes': durationMinutes,
      'total_volume': totalVolume,
    }).eq('id', workoutId);

    await _updatePersonalRecords(workoutId);
  }

  Future<void> _updatePersonalRecords(String workoutId) async {
    final userId = SupabaseService.currentUser!.id;
    final exercises = await _getWorkoutExercises(workoutId);

    for (final ex in exercises) {
      for (final set in ex.sets.where((s) => s.completed && s.weight != null)) {
        final oneRm = PersonalRecord.calculate1RM(set.weight!, set.reps);
        final existing = await _client
            .from('personal_records')
            .select()
            .eq('user_id', userId)
            .eq('exercise_id', ex.exerciseId)
            .maybeSingle();

        if (existing == null || (existing['one_rep_max'] as num) < oneRm) {
          await _client.from('personal_records').upsert(
            {
              'user_id': userId,
              'exercise_id': ex.exerciseId,
              'exercise_name': ex.exerciseName,
              'weight': set.weight,
              'reps': set.reps,
              'one_rep_max': oneRm,
              'achieved_at': SupabaseDateTime.nowUtc.toIso8601String(),
            },
            onConflict: 'user_id,exercise_id',
          );
        }
      }
    }
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
        .order('one_rep_max', ascending: false);

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

  Map<String, double> calculateMuscleRecovery(List<Workout> recentWorkouts) {
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

        final muscles = MuscleInference.fromExerciseName(ex.exerciseName);
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
