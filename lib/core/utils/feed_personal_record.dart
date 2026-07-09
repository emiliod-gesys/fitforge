import '../../models/exercise_logging.dart';
import '../../models/profile.dart';
import '../utils/cardio_format.dart';
import '../utils/unit_converter.dart';

/// Serialización y formato de récords personales para el feed social.
abstract final class FeedPersonalRecord {
  static String keyFor(PersonalRecord pr) =>
      '${pr.exerciseId}:${pr.recordType.toJson()}';

  static Map<String, dynamic> toMetadata(PersonalRecord pr) {
    return {
      'exercise_id': pr.exerciseId,
      'exercise_name': pr.exerciseName,
      'record_type': pr.recordType.toJson(),
      if (pr.weight != null) 'weight_kg': pr.weight,
      'reps': pr.reps,
      if (pr.oneRepMax != null) 'one_rep_max': pr.oneRepMax,
      if (pr.distanceMeters != null) 'distance_meters': pr.distanceMeters,
      if (pr.durationSeconds != null) 'duration_seconds': pr.durationSeconds,
      if (pr.steps != null) 'steps': pr.steps,
      if (pr.inclinePercent != null) 'incline_percent': pr.inclinePercent,
    };
  }

  static PersonalRecord? fromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;
    final exerciseId = metadata['exercise_id'] as String?;
    final exerciseName = metadata['exercise_name'] as String?;
    if (exerciseId == null || exerciseName == null) return null;

    return PersonalRecord(
      id: '',
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      weight: (metadata['weight_kg'] as num?)?.toDouble(),
      reps: metadata['reps'] as int? ?? 1,
      oneRepMax: (metadata['one_rep_max'] as num?)?.toDouble(),
      achievedAt: DateTime.now(),
      recordType: PersonalRecordType.fromJson(metadata['record_type'] as String?),
      durationSeconds: metadata['duration_seconds'] as int?,
      distanceMeters: (metadata['distance_meters'] as num?)?.toDouble(),
      inclinePercent: (metadata['incline_percent'] as num?)?.toDouble(),
      steps: metadata['steps'] as int?,
    );
  }

  static String formatValue(PersonalRecord pr, String unitSystem) {
    switch (pr.recordType) {
      case PersonalRecordType.strength:
        return UnitConverter.formatSetLine(pr.weight ?? 0, pr.reps, unitSystem);
      case PersonalRecordType.cardioDistance:
        return CardioFormat.distance(pr.distanceMeters, unitSystem);
      case PersonalRecordType.cardioDuration:
        return CardioFormat.duration(pr.durationSeconds);
      case PersonalRecordType.cardioSteps:
        return CardioFormat.steps(pr.steps);
      case PersonalRecordType.cardioIncline:
        return CardioFormat.incline(pr.inclinePercent);
      case PersonalRecordType.cardioDifficulty:
        return CardioFormat.difficulty(pr.inclinePercent);
    }
  }
}
