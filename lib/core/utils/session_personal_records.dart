import '../../models/exercise_logging.dart';
import '../../models/profile.dart';
import '../../models/workout.dart';
import 'exercise_logging_resolver.dart';

/// Detecta récords personales que el entreno actual superaría respecto al historial.
abstract final class SessionPersonalRecords {
  static List<PersonalRecord> detect({
    required Workout workout,
    required List<PersonalRecord> existing,
  }) {
    final highlights = <PersonalRecord>[];

    for (final ex in workout.exercises) {
      final completedSets = ex.sets.where((s) => s.completed).toList();
      if (completedSets.isEmpty) continue;

      final strengthSets =
          completedSets.where((s) => !s.isCardio && s.weight != null).toList();
      for (final set in strengthSets) {
        final oneRm = PersonalRecord.calculate1RM(set.weight!, set.reps);
        final prev = _find(existing, ex.exerciseId, PersonalRecordType.strength);
        if (prev == null || (prev.oneRepMax ?? 0) < oneRm) {
          _replaceOrAdd(
            highlights,
            PersonalRecord(
              id: '',
              exerciseId: ex.exerciseId,
              exerciseName: ex.exerciseName,
              weight: set.weight,
              reps: set.reps,
              oneRepMax: oneRm,
              achievedAt: DateTime.now(),
              recordType: PersonalRecordType.strength,
            ),
          );
        }
      }

      final cardioSets = completedSets.where((s) => s.isCardio).toList();
      if (cardioSets.isEmpty) continue;

      final maxDistance = cardioSets
          .map((s) => s.distanceMeters)
          .whereType<double>()
          .fold<double?>(null, (best, v) => best == null || v > best ? v : best);
      if (maxDistance != null) {
        final prev = _find(existing, ex.exerciseId, PersonalRecordType.cardioDistance);
        if (prev == null ||
            prev.distanceMeters == null ||
            prev.distanceMeters! < maxDistance) {
          _replaceOrAdd(
            highlights,
            PersonalRecord(
              id: '',
              exerciseId: ex.exerciseId,
              exerciseName: ex.exerciseName,
              achievedAt: DateTime.now(),
              recordType: PersonalRecordType.cardioDistance,
              distanceMeters: maxDistance,
            ),
          );
        }
      }

      final maxDuration = cardioSets
          .map((s) => s.durationSeconds)
          .whereType<int>()
          .fold<int?>(null, (best, v) => best == null || v > best ? v : best);
      if (maxDuration != null) {
        final prev = _find(existing, ex.exerciseId, PersonalRecordType.cardioDuration);
        if (prev == null ||
            prev.durationSeconds == null ||
            prev.durationSeconds! < maxDuration) {
          _replaceOrAdd(
            highlights,
            PersonalRecord(
              id: '',
              exerciseId: ex.exerciseId,
              exerciseName: ex.exerciseName,
              achievedAt: DateTime.now(),
              recordType: PersonalRecordType.cardioDuration,
              durationSeconds: maxDuration,
            ),
          );
        }
      }

      final maxSteps = cardioSets
          .map((s) => s.steps)
          .whereType<int>()
          .fold<int?>(null, (best, v) => best == null || v > best ? v : best);
      if (maxSteps != null) {
        final prev = _find(existing, ex.exerciseId, PersonalRecordType.cardioSteps);
        if (prev == null || prev.steps == null || prev.steps! < maxSteps) {
          _replaceOrAdd(
            highlights,
            PersonalRecord(
              id: '',
              exerciseId: ex.exerciseId,
              exerciseName: ex.exerciseName,
              achievedAt: DateTime.now(),
              recordType: PersonalRecordType.cardioSteps,
              steps: maxSteps,
            ),
          );
        }
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
        final recordType = config.tracksDifficulty
            ? PersonalRecordType.cardioDifficulty
            : config.tracksIncline
                ? PersonalRecordType.cardioIncline
                : null;
        if (recordType != null) {
          final prev = _find(existing, ex.exerciseId, recordType);
          if (prev == null ||
              prev.inclinePercent == null ||
              prev.inclinePercent! < maxIncline) {
            _replaceOrAdd(
              highlights,
              PersonalRecord(
                id: '',
                exerciseId: ex.exerciseId,
                exerciseName: ex.exerciseName,
                achievedAt: DateTime.now(),
                recordType: recordType,
                inclinePercent: maxIncline,
              ),
            );
          }
        }
      }
    }

    return highlights;
  }

  static PersonalRecord? _find(
    List<PersonalRecord> existing,
    String exerciseId,
    PersonalRecordType type,
  ) {
    for (final record in existing) {
      if (record.exerciseId == exerciseId && record.recordType == type) {
        return record;
      }
    }
    return null;
  }

  static void _replaceOrAdd(List<PersonalRecord> list, PersonalRecord candidate) {
    final index = list.indexWhere(
      (r) =>
          r.exerciseId == candidate.exerciseId && r.recordType == candidate.recordType,
    );
    if (index >= 0) {
      list[index] = candidate;
    } else {
      list.add(candidate);
    }
  }
}
