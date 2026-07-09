import 'package:uuid/uuid.dart';
import '../core/errors/routine_limit_exception.dart';
import '../core/subscription/subscription_features.dart';
import '../models/profile.dart';
import '../models/routine.dart';
import 'supabase_service.dart';

class RoutineService {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

  static const maxFavoriteRoutines = 5;

  Future<List<Routine>> getRoutines() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];
    return getRoutinesForUser(userId);
  }

  Future<List<Routine>> getRoutinesForUser(String userId) async {
    if (_isStudentRoutine(userId)) {
      final data = await _client.rpc(
        'get_student_routines',
        params: {'p_student_id': userId},
      );
      return _routinesFromRpcList(data);
    }

    final routinesData = await _client
        .from('routines')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    final routines = <Routine>[];
    for (final r in routinesData as List) {
      routines.add(await _routineFromRow(r as Map<String, dynamic>));
    }
    return routines;
  }

  Future<List<Routine>> getFavoriteRoutinesForUser(String userId) async {
    final routinesData = await _client
        .from('routines')
        .select()
        .eq('user_id', userId)
        .eq('is_favorite', true)
        .order('favorite_order', ascending: true)
        .order('updated_at', ascending: false);

    final routines = <Routine>[];
    for (final r in routinesData as List) {
      routines.add(await _routineFromRow(r as Map<String, dynamic>));
    }
    return routines;
  }

  Future<void> setRoutineFavorite(String routineId, bool favorite) async {
    await _client.rpc(
      'set_routine_favorite',
      params: {
        'p_routine_id': routineId,
        'p_favorite': favorite,
      },
    );
  }

  Future<int> countRoutinesForUser(String userId) async {
    final data = await _client.from('routines').select('id').eq('user_id', userId);
    return (data as List).length;
  }

  Future<SubscriptionTier> _subscriptionTierForUser(String userId) async {
    final row = await _client
        .from('profiles')
        .select('subscription_tier')
        .eq('id', userId)
        .maybeSingle();
    return SubscriptionTier.fromCode(row?['subscription_tier'] as String?);
  }

  Future<void> assertCanCreateRoutine(String userId) async {
    final tier = await _subscriptionTierForUser(userId);
    final count = await countRoutinesForUser(userId);
    if (count >= tier.maxSavedRoutines) {
      throw RoutineLimitReachedException(limit: tier.maxSavedRoutines, tier: tier);
    }
  }

  Future<Routine> copyRoutineToCurrentUser(Routine source) async {
    return createRoutine(source.copyForCurrentUser());
  }

  Future<Routine?> getRoutineById(String routineId, {String? forStudentId}) async {
    if (_isStudentRoutine(forStudentId)) {
      final data = await _client.rpc(
        'get_student_routine',
        params: {'p_routine_id': routineId},
      );
      if (data == null) return null;
      return _routineFromRpcMap(Map<String, dynamic>.from(data as Map));
    }

    final row = await _client.from('routines').select().eq('id', routineId).maybeSingle();
    if (row == null) return null;
    return _routineFromRow(Map<String, dynamic>.from(row));
  }

  List<Routine> _routinesFromRpcList(dynamic data) {
    if (data == null) return [];
    final list = data as List;
    return list
        .map((item) => _routineFromRpcMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Routine _routineFromRpcMap(Map<String, dynamic> map) {
    final mapCopy = Map<String, dynamic>.from(map);
    final exercisesRaw = mapCopy.remove('exercises');
    final exercises = <RoutineExercise>[];
    if (exercisesRaw is List) {
      for (final item in exercisesRaw) {
        exercises.add(RoutineExercise.fromJson(Map<String, dynamic>.from(item as Map)));
      }
    }
    return Routine.fromJson(mapCopy, exercises: exercises);
  }

  Future<Routine> _routineFromRow(Map<String, dynamic> row) async {
    final routineId = row['id'] as String;
    final exercisesData = await _client
        .from('routine_exercises')
        .select()
        .eq('routine_id', routineId)
        .order('order_index', ascending: true);

    final exercises = (exercisesData as List)
        .map((e) => RoutineExercise.fromJson(e as Map<String, dynamic>))
        .toList();

    return Routine.fromJson(row, exercises: exercises);
  }

  bool _isStudentRoutine(String? forUserId) {
    final currentId = SupabaseService.currentUser?.id;
    return forUserId != null && forUserId.isNotEmpty && forUserId != currentId;
  }

  Map<String, dynamic> _exerciseToRpcJson(RoutineExercise ex) => {
        'id': ex.id.isEmpty ? null : ex.id,
        'exercise_id': ex.exerciseId,
        'exercise_name': ex.exerciseName,
        'order_index': ex.orderIndex,
        'target_sets': ex.targetSets,
        'target_reps': ex.targetReps,
        if (ex.targetWeight != null) 'target_weight': ex.targetWeight,
        'rest_seconds': ex.restSeconds,
        if (ex.imageUrl != null) 'image_url': ex.imageUrl,
        'logging_type': ex.loggingType.toJson(),
        if (ex.targetDurationSeconds != null) 'target_duration_seconds': ex.targetDurationSeconds,
        if (ex.targetDistanceMeters != null) 'target_distance_meters': ex.targetDistanceMeters,
        if (ex.targetInclinePercent != null) 'target_incline_percent': ex.targetInclinePercent,
        if (ex.targetSteps != null) 'target_steps': ex.targetSteps,
        if (ex.perArmWeight != null) 'per_arm_weight': ex.perArmWeight,
        if (ex.targetSetDetails.isNotEmpty)
          'target_set_details': ex.targetSetDetails.map((s) => s.toJson()).toList(),
      };

  Future<String> _saveStudentRoutineViaRpc({
    required String studentId,
    required Routine routine,
    String? routineId,
  }) async {
    final payload = <String, dynamic>{
      'student_id': studentId,
      'name': routine.name,
      'description': routine.description,
      'target_muscles': routine.targetMuscles,
      'is_ai_generated': routine.isAiGenerated,
      'exercises': routine.exercises.map(_exerciseToRpcJson).toList(),
      if (routineId != null && routineId.isNotEmpty) 'routine_id': routineId,
    };

    final id = await _client.rpc(
      'save_student_routine',
      params: {'p_payload': payload},
    );
    return id as String;
  }

  Future<Routine> createRoutine(Routine routine, {String? forUserId}) async {
    if (_isStudentRoutine(forUserId)) {
      await assertCanCreateRoutine(forUserId!);
      final routineId = await _saveStudentRoutineViaRpc(
        studentId: forUserId!,
        routine: routine,
      );
      final saved = await getRoutineById(routineId, forStudentId: forUserId);
      return saved ??
          Routine(
            id: routineId,
            userId: forUserId,
            name: routine.name,
            description: routine.description,
            targetMuscles: routine.targetMuscles,
            exercises: routine.exercises,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isAiGenerated: routine.isAiGenerated,
          );
    }

    final userId = SupabaseService.currentUser!.id;
    await assertCanCreateRoutine(userId);
    final routineId = routine.id.isEmpty ? _uuid.v4() : routine.id;
    final description = routine.description?.trim();
    final now = DateTime.now().toUtc().toIso8601String();

    await _client.from('routines').insert({
      'id': routineId,
      'user_id': userId,
      'name': routine.name,
      'description': description == null || description.isEmpty ? null : description,
      'target_muscles': routine.targetMuscles,
      'is_ai_generated': routine.isAiGenerated,
      'updated_at': now,
    });

    if (routine.exercises.isNotEmpty) {
      await _client.from('routine_exercises').insert(
        routine.exercises
            .map(
              (ex) => {
                ...ex.toJson(),
                'routine_id': routineId,
                'id': ex.id.isEmpty ? _uuid.v4() : ex.id,
              },
            )
            .toList(),
      );
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

  Future<void> updateRoutine(Routine routine, {String? forStudentId}) async {
    if (_isStudentRoutine(forStudentId)) {
      await _saveStudentRoutineViaRpc(
        studentId: forStudentId!,
        routine: routine,
        routineId: routine.id,
      );
      return;
    }

    final description = routine.description?.trim();
    await _client.from('routines').update({
      'name': routine.name,
      'description': description == null || description.isEmpty ? null : description,
      'target_muscles': routine.targetMuscles,
      'is_ai_generated': routine.isAiGenerated,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', routine.id);

    await _client.from('routine_exercises').delete().eq('routine_id', routine.id);

    if (routine.exercises.isEmpty) return;

    await _client.from('routine_exercises').insert(
      routine.exercises
          .map(
            (ex) => {
              ...ex.toJson(),
              'routine_id': routine.id,
              'id': ex.id.isEmpty ? _uuid.v4() : ex.id,
            },
          )
          .toList(),
    );
  }

  Future<void> deleteRoutine(String id, {String? forStudentId}) async {
    if (_isStudentRoutine(forStudentId)) {
      await _client.rpc('delete_student_routine', params: {'p_routine_id': id});
      return;
    }

    await _client.from('routine_exercises').delete().eq('routine_id', id);
    await _client.from('routines').delete().eq('id', id);
  }
}
