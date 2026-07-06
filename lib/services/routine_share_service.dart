import '../models/routine.dart';
import 'supabase_service.dart';

class RoutineShareService {
  final _client = SupabaseService.client;

  Future<String> sendRoutineShare({
    required String routineId,
    required String recipientId,
  }) async {
    final id = await _client.rpc(
      'send_routine_share',
      params: {
        'p_routine_id': routineId,
        'p_recipient_id': recipientId,
      },
    );
    return id as String;
  }

  Future<void> respondToShare({
    required String requestId,
    required bool accept,
  }) async {
    await _client.rpc(
      'respond_routine_share',
      params: {
        'p_request_id': requestId,
        'p_accept': accept,
      },
    );
  }

  Future<Routine?> getSharePreview(String requestId) async {
    final uid = SupabaseService.currentUser?.id;
    if (uid == null) return null;

    final row = await _client
        .from('routine_share_requests')
        .select('routine_snapshot, status, recipient_id')
        .eq('id', requestId)
        .maybeSingle();

    if (row == null) return null;
    final map = Map<String, dynamic>.from(row);
    if (map['recipient_id'] != uid) return null;
    if (map['status'] != 'pending') return null;

    final snapshot = Map<String, dynamic>.from(map['routine_snapshot'] as Map);
    final exercisesRaw = snapshot.remove('exercises');
    final exercises = <RoutineExercise>[];
    if (exercisesRaw is List) {
      for (var i = 0; i < exercisesRaw.length; i++) {
        final exMap = Map<String, dynamic>.from(exercisesRaw[i] as Map);
        exercises.add(
          RoutineExercise.fromJson({
            ...exMap,
            'id': 'preview-$i',
          }),
        );
      }
    }

    final now = DateTime.now();
    return Routine(
      id: requestId,
      userId: '',
      name: snapshot['name'] as String? ?? '',
      description: snapshot['description'] as String?,
      targetMuscles: List<String>.from(snapshot['target_muscles'] ?? []),
      exercises: exercises,
      createdAt: now,
      updatedAt: now,
      isAiGenerated: snapshot['is_ai_generated'] as bool? ?? false,
    );
  }
}
