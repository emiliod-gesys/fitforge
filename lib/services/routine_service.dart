import 'package:uuid/uuid.dart';
import '../models/routine.dart';
import 'supabase_service.dart';

class RoutineService {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

  Future<List<Routine>> getRoutines() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final routinesData = await _client
        .from('routines')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    final routines = <Routine>[];
    for (final r in routinesData as List) {
      final exercisesData = await _client
          .from('routine_exercises')
          .select()
          .eq('routine_id', r['id'])
          .order('order_index', ascending: true);

      final exercises = (exercisesData as List)
          .map((e) => RoutineExercise.fromJson(e as Map<String, dynamic>))
          .toList();

      routines.add(Routine.fromJson(r as Map<String, dynamic>, exercises: exercises));
    }
    return routines;
  }

  Future<Routine> createRoutine(Routine routine) async {
    final userId = SupabaseService.currentUser!.id;
    final routineId = routine.id.isEmpty ? _uuid.v4() : routine.id;

    await _client.from('routines').insert({
      ...routine.toJson(),
      'id': routineId,
      'user_id': userId,
    });

    for (final ex in routine.exercises) {
      await _client.from('routine_exercises').insert({
        ...ex.toJson(),
        'routine_id': routineId,
        'id': ex.id.isEmpty ? _uuid.v4() : ex.id,
      });
    }

    return Routine(
      id: routineId,
      userId: userId,
      name: routine.name,
      description: routine.description,
      targetMuscles: routine.targetMuscles,
      exercises: routine.exercises,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isAiGenerated: routine.isAiGenerated,
    );
  }

  Future<void> updateRoutine(Routine routine) async {
    await _client.from('routines').update({
      ...routine.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', routine.id);

    await _client.from('routine_exercises').delete().eq('routine_id', routine.id);

    for (final ex in routine.exercises) {
      await _client.from('routine_exercises').insert({
        ...ex.toJson(),
        'routine_id': routine.id,
        'id': ex.id.isEmpty ? _uuid.v4() : ex.id,
      });
    }
  }

  Future<void> deleteRoutine(String id) async {
    await _client.from('routine_exercises').delete().eq('routine_id', id);
    await _client.from('routines').delete().eq('id', id);
  }
}
