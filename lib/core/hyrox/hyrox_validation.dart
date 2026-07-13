import '../../models/profile.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import 'hyrox_exercise_ids.dart';
import 'hyrox_standards.dart';

enum HyroxValidationStatus {
  valid,
  suspicious,
  rejected;

  String get code => name;

  static HyroxValidationStatus? fromCode(String? value) {
    return switch (value) {
      'valid' => HyroxValidationStatus.valid,
      'suspicious' => HyroxValidationStatus.suspicious,
      'rejected' => HyroxValidationStatus.rejected,
      _ => null,
    };
  }

  bool get countsForLeaderboard => this == HyroxValidationStatus.valid;
}

class HyroxValidationResult {
  final HyroxValidationStatus? status;
  final List<String> reasons;

  const HyroxValidationResult({
    this.status,
    this.reasons = const [],
  });

  bool get isHyroxWorkout => status != null;

  bool get countsForLeaderboard =>
      status == null || status == HyroxValidationStatus.valid;

  factory HyroxValidationResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HyroxValidationResult();
    final reasonsRaw = json['reasons'];
    final reasons = reasonsRaw is List
        ? reasonsRaw.map((e) => e.toString()).toList()
        : const <String>[];
    return HyroxValidationResult(
      status: HyroxValidationStatus.fromCode(json['status'] as String?),
      reasons: reasons,
    );
  }
}

/// Umbrales mínimos para detectar tiempos imposibles o manipulación de datos.
abstract final class HyroxValidator {
  static const expectedStationCount = 16;
  static const splitTotalToleranceSeconds = 120;
  static const weightToleranceKg = 0.75;
  static const distanceToleranceMeters = 1.0;

  static int minTotalSeconds({
    required HyroxLevel level,
    Gender? gender,
  }) {
    return switch (level) {
      HyroxLevel.prep => 25 * 60,
      HyroxLevel.build => 35 * 60,
      HyroxLevel.race => switch (gender) {
          Gender.female => 42 * 60,
          _ => 45 * 60,
        },
    };
  }

  static double minStationSeconds({
    required String exerciseId,
    double? distanceMeters,
    int? reps,
  }) {
    return switch (exerciseId) {
      HyroxExerciseIds.run =>
        _scaledMin(distanceMeters, referenceMeters: 1000, baseAtReference: 150),
      HyroxExerciseIds.skiErg =>
        _scaledMin(distanceMeters, referenceMeters: 1000, baseAtReference: 150),
      HyroxExerciseIds.rowing =>
        _scaledMin(distanceMeters, referenceMeters: 1000, baseAtReference: 150),
      HyroxExerciseIds.sledPush =>
        _scaledMin(distanceMeters, referenceMeters: 50, baseAtReference: 30),
      HyroxExerciseIds.sledPull =>
        _scaledMin(distanceMeters, referenceMeters: 50, baseAtReference: 30),
      HyroxExerciseIds.burpeeBroadJump =>
        _scaledMin(distanceMeters, referenceMeters: 80, baseAtReference: 60),
      HyroxExerciseIds.farmers =>
        _scaledMin(distanceMeters, referenceMeters: 200, baseAtReference: 45),
      HyroxExerciseIds.sandbagLunges =>
        _scaledMin(distanceMeters, referenceMeters: 100, baseAtReference: 60),
      HyroxExerciseIds.wallBall => 90 * ((reps ?? 100) / 100.0),
      _ => 30,
    };
  }

  static HyroxValidationResult validate({
    required Workout workout,
    required HyroxLevel level,
    Gender? gender,
    required DateTime startedAt,
    required DateTime completedAt,
    List<HyroxStationExpectation> expectations = const [],
  }) {
    final reasons = <String>[];
    var status = HyroxValidationStatus.valid;

    void reject(String reason) {
      reasons.add(reason);
      status = HyroxValidationStatus.rejected;
    }

    void flag(String reason) {
      if (status == HyroxValidationStatus.valid) {
        reasons.add(reason);
        status = HyroxValidationStatus.suspicious;
      }
    }

    final completedSets = workout.exercises
        .expand((exercise) => exercise.sets)
        .where((set) => set.completed)
        .toList();

    if (completedSets.length < expectedStationCount) {
      reject('incomplete_stations');
    }

    final totalSeconds = completedAt.difference(startedAt).inSeconds;
    if (totalSeconds < minTotalSeconds(level: level, gender: gender)) {
      reject('total_time_too_fast');
    }

    final splitSum = completedSets.fold<int>(
      0,
      (sum, set) => sum + (set.durationSeconds ?? 0),
    );
    if (splitSum > totalSeconds + splitTotalToleranceSeconds) {
      reject('split_sum_exceeds_total');
    }

    if (completedSets.length >= expectedStationCount &&
        splitSum < totalSeconds * 0.35) {
      flag('split_sum_too_low');
    }

    final expectationByOrder = {
      for (final item in expectations) item.orderIndex: item,
    };

    for (final exercise in workout.exercises) {
      for (final set in exercise.sets.where((s) => s.completed)) {
        final duration = set.durationSeconds;
        if (duration == null || duration <= 0) {
          flag('missing_station_time');
          continue;
        }

        final minSeconds = minStationSeconds(
          exerciseId: exercise.exerciseId,
          distanceMeters: set.distanceMeters,
          reps: set.reps,
        );
        if (duration < minSeconds) {
          reject('station_time_too_fast:${exercise.exerciseId}');
        }

        final expected = expectationByOrder[exercise.orderIndex];
        if (expected == null) continue;

        if (expected.distanceMeters != null &&
            set.distanceMeters != null &&
            (set.distanceMeters! - expected.distanceMeters!).abs() >
                distanceToleranceMeters) {
          reject('target_distance_mismatch:${exercise.exerciseId}');
        }

        if (expected.weightKg != null &&
            set.weight != null &&
            (set.weight! - expected.weightKg!).abs() > weightToleranceKg) {
          reject('target_weight_mismatch:${exercise.exerciseId}');
        }

        if (expected.reps != null &&
            set.reps != expected.reps) {
          reject('target_reps_mismatch:${exercise.exerciseId}');
        }
      }
    }

    return HyroxValidationResult(
      status: status,
      reasons: reasons,
    );
  }

  static List<HyroxStationExpectation> expectationsFromRoutineExercises(
    List<RoutineExercise> exercises,
  ) {
    return exercises
        .map(
          (exercise) => HyroxStationExpectation(
            orderIndex: exercise.orderIndex,
            exerciseId: exercise.exerciseId,
            distanceMeters: exercise.targetDistanceMeters,
            weightKg: exercise.targetWeight,
            reps: exercise.targetReps > 0 ? exercise.targetReps : null,
          ),
        )
        .toList();
  }

  static double _scaledMin(
    double? meters, {
    required double referenceMeters,
    required double baseAtReference,
  }) {
    final distance = meters ?? referenceMeters;
    if (distance <= 0) return baseAtReference;
    return baseAtReference * (distance / referenceMeters);
  }
}

class HyroxStationExpectation {
  final int orderIndex;
  final String exerciseId;
  final double? distanceMeters;
  final double? weightKg;
  final int? reps;

  const HyroxStationExpectation({
    required this.orderIndex,
    required this.exerciseId,
    this.distanceMeters,
    this.weightKg,
    this.reps,
  });
}
