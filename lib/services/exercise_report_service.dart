import 'package:uuid/uuid.dart';
import 'supabase_service.dart';

enum ExerciseReportCategory {
  wrongMetrics,
  wrongGif,
  wrongName,
  wrongMuscles,
  other,
}

class ExerciseReportService {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

  Future<void> submit({
    required String exerciseId,
    required String exerciseName,
    required ExerciseReportCategory category,
    String? notes,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw StateError('Not authenticated');
    }

    await _client.from('exercise_reports').insert({
      'id': _uuid.v4(),
      'user_id': userId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'category': category.name,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    });
  }
}
