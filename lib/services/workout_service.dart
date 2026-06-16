import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../models/workout.dart';
import 'supabase_service.dart';

class WorkoutService {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

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
        .map((row) => DateTime.parse((row as Map<String, dynamic>)['completed_at'] as String))
        .toList();
  }

  Future<Workout?> getActiveWorkout() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('workouts')
        .select()
        .eq('user_id', userId)
        .filter('completed_at', 'is', null)
        .maybeSingle();

    if (data == null) return null;
    final exercises = await _getWorkoutExercises(data['id'] as String);
    return Workout.fromJson(data, exercises: exercises);
  }

  Future<List<WorkoutExercise>> _getWorkoutExercises(String workoutId) async {
    final exercisesData = await _client
        .from('workout_exercises')
        .select()
        .eq('workout_id', workoutId)
        .order('order_index');

    final exercises = <WorkoutExercise>[];
    for (final ex in exercisesData as List) {
      final exMap = ex as Map<String, dynamic>;
      final setsData = await _client
          .from('workout_sets')
          .select()
          .eq('workout_exercise_id', exMap['id'])
          .order('set_number');

      final sets = (setsData as List)
          .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
          .toList();

      exercises.add(WorkoutExercise.fromJson(exMap, sets: sets));
    }
    return exercises;
  }

  Future<Workout> startWorkout({
    required String name,
    String? routineId,
    List<WorkoutExercise>? exercises,
  }) async {
    final userId = SupabaseService.currentUser!.id;
    final workoutId = _uuid.v4();

    await _client.from('workouts').insert({
      'id': workoutId,
      'user_id': userId,
      'routine_id': routineId,
      'name': name,
      'started_at': DateTime.now().toIso8601String(),
    });

    if (exercises != null) {
      for (final ex in exercises) {
        await _addExerciseToWorkout(workoutId, ex);
      }
    }

    return Workout(
      id: workoutId,
      userId: userId,
      routineId: routineId,
      name: name,
      startedAt: DateTime.now(),
      exercises: exercises ?? [],
    );
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
      'completed_at': DateTime.now().toIso8601String(),
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
              'achieved_at': DateTime.now().toIso8601String(),
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

    for (final muscle in ['Pecho', 'Espalda', 'Hombros', 'Bíceps', 'Tríceps', 'Piernas', 'Glúteos', 'Abdominales']) {
      recovery[muscle] = 100.0;
    }

    for (final workout in recentWorkouts.where((w) => w.completedAt != null)) {
      final hoursSince = now.difference(workout.completedAt!).inHours.toDouble();
      for (final ex in workout.exercises) {
        for (final muscle in _inferMuscles(ex.exerciseName)) {
          final recoveryHours = _recoveryHours(muscle);
          final percent = (hoursSince / recoveryHours * 100).clamp(0.0, 100.0);
          if (recovery.containsKey(muscle)) {
            recovery[muscle] = recovery[muscle]!.clamp(0.0, 100 - percent);
          }
        }
      }
    }
    return recovery;
  }

  List<String> _inferMuscles(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('press') || name.contains('pecho') || name.contains('bench')) return ['Pecho'];
    if (name.contains('remo') || name.contains('pull') || name.contains('espalda')) return ['Espalda'];
    if (name.contains('hombro') || name.contains('shoulder') || name.contains('militar')) return ['Hombros'];
    if (name.contains('curl') || name.contains('bícep')) return ['Bíceps'];
    if (name.contains('trícep') || name.contains('extension')) return ['Tríceps'];
    if (name.contains('sentadilla') || name.contains('squat') || name.contains('pierna')) return ['Piernas'];
    if (name.contains('glúteo') || name.contains('hip')) return ['Glúteos'];
    if (name.contains('abdominal') || name.contains('crunch')) return ['Abdominales'];
    return ['Pecho'];
  }

  double _recoveryHours(String muscle) {
    const hours = {
      'Pecho': 48.0,
      'Espalda': 48.0,
      'Hombros': 36.0,
      'Bíceps': 24.0,
      'Tríceps': 24.0,
      'Piernas': 72.0,
      'Glúteos': 48.0,
      'Abdominales': 24.0,
    };
    return hours[muscle] ?? 48.0;
  }
}
