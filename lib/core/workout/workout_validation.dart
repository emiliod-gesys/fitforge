import '../../models/exercise_logging.dart';
import '../../models/workout.dart';
import '../hyrox/hyrox_validation.dart';

enum WorkoutValidationStatus {
  valid,
  suspicious,
  rejected;

  String get code => name;

  static WorkoutValidationStatus fromCode(String? value) {
    return switch (value) {
      'valid' => WorkoutValidationStatus.valid,
      'suspicious' => WorkoutValidationStatus.suspicious,
      'rejected' => WorkoutValidationStatus.rejected,
      _ => WorkoutValidationStatus.valid,
    };
  }

  bool get countsForLeaderboard => this == WorkoutValidationStatus.valid;
}

class WorkoutValidationResult {
  final WorkoutValidationStatus status;
  final List<String> reasons;

  const WorkoutValidationResult({
    this.status = WorkoutValidationStatus.valid,
    this.reasons = const [],
  });

  bool get countsForLeaderboard => status.countsForLeaderboard;

  factory WorkoutValidationResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WorkoutValidationResult();
    final reasonsRaw = json['reasons'];
    final reasons = reasonsRaw is List
        ? reasonsRaw.map((e) => e.toString()).toList()
        : const <String>[];
    return WorkoutValidationResult(
      status: WorkoutValidationStatus.fromCode(json['status'] as String?),
      reasons: reasons,
    );
  }
}

/// Umbrales generosos para detectar entrenos imposibles sin castigar errores de tipeo.
abstract final class WorkoutValidator {
  static const minDurationMinutesReject = 2;
  static const minDurationMinutesSuspicious = 5;
  static const maxDurationMinutesReject = 8 * 60;

  static const maxVolumeKgReject = 80000.0;
  static const maxVolumeKgSuspicious = 30000.0;
  static const maxVolumePerMinuteReject = 2000.0;
  static const maxVolumePerMinuteSuspicious = 800.0;

  static const maxTotalRepsReject = 5000;
  static const maxTotalRepsSuspicious = 2000;
  static const maxRepsPerSetReject = 300;
  static const maxRepsPerSetSuspicious = 100;

  static const maxDistanceMetersReject = 100000.0;
  static const maxDistanceMetersSuspicious = 50000.0;

  static const maxCaloriesReject = 3000;
  static const maxCaloriesSuspicious = 1800;

  static const maxWeightKgReject = 500.0;
  static const maxWeightKgSuspicious = 350.0;

  static const minPaceSecPerKmReject = 120.0;
  static const minPaceSecPerKmSuspicious = 160.0;

  static const maxWorkoutsSameDayReject = 8;
  static const maxWorkoutsSameDaySuspicious = 5;

  static WorkoutValidationResult validate({
    required Workout workout,
    required DateTime startedAt,
    required DateTime completedAt,
    required int durationMinutes,
    required double totalVolumeKg,
    int? activeCaloriesKcal,
    double? runnerAvgPaceSecPerKm,
    bool isHyroxSystem = false,
    int workoutsCompletedSameDay = 0,
  }) {
    final reasons = <String>[];
    var status = WorkoutValidationStatus.valid;

    void reject(String reason) {
      reasons.add(reason);
      status = WorkoutValidationStatus.rejected;
    }

    void flag(String reason) {
      if (status == WorkoutValidationStatus.valid) {
        reasons.add(reason);
        status = WorkoutValidationStatus.suspicious;
      }
    }

    final duration = durationMinutes > 0
        ? durationMinutes
        : completedAt.difference(startedAt).inMinutes.clamp(0, maxDurationMinutesReject);

    if (duration < minDurationMinutesReject) {
      reject('duration_too_short');
    } else if (duration > maxDurationMinutesReject) {
      reject('duration_too_long');
    } else if (duration < minDurationMinutesSuspicious &&
        totalVolumeKg > maxVolumeKgSuspicious * 0.25) {
      flag('duration_short_high_volume');
    }

    if (!isHyroxSystem) {
      if (totalVolumeKg > maxVolumeKgReject) {
        reject('volume_too_high');
      } else if (totalVolumeKg > maxVolumeKgSuspicious) {
        flag('volume_high');
      }

      if (duration >= 1) {
        final volumePerMinute = totalVolumeKg / duration;
        if (volumePerMinute > maxVolumePerMinuteReject) {
          reject('volume_per_minute_too_high');
        } else if (volumePerMinute > maxVolumePerMinuteSuspicious) {
          flag('volume_per_minute_high');
        }
      }
    }

    var totalReps = 0;
    var totalDistanceMeters = 0.0;

    for (final exercise in workout.exercises) {
      for (final set in exercise.sets.where((s) => s.completed)) {
        if (set.loggingType == ExerciseLoggingType.strength) {
          totalReps += set.reps;
          if (set.reps > maxRepsPerSetReject) {
            reject('reps_per_set_too_high');
          } else if (set.reps > maxRepsPerSetSuspicious) {
            flag('reps_per_set_high');
          }
        }

        final weight = set.weight;
        if (weight != null && weight > 0) {
          if (weight > maxWeightKgReject) {
            reject('weight_too_high');
          } else if (weight > maxWeightKgSuspicious) {
            flag('weight_high');
          }
        }

        final distance = set.distanceMeters;
        if (distance != null && distance > 0) {
          totalDistanceMeters += distance;
          if (set.durationSeconds != null && set.durationSeconds! > 0) {
            final paceSecPerKm = set.durationSeconds! / (distance / 1000.0);
            if (paceSecPerKm < minPaceSecPerKmReject) {
              reject('pace_too_fast');
            } else if (paceSecPerKm < minPaceSecPerKmSuspicious) {
              flag('pace_fast');
            }
          }
        }
      }
    }

    if (totalReps > maxTotalRepsReject) {
      reject('total_reps_too_high');
    } else if (totalReps > maxTotalRepsSuspicious) {
      flag('total_reps_high');
    }

    if (totalDistanceMeters > maxDistanceMetersReject) {
      reject('distance_too_high');
    } else if (totalDistanceMeters > maxDistanceMetersSuspicious) {
      flag('distance_high');
    }

    final calories = activeCaloriesKcal;
    if (calories != null) {
      if (calories > maxCaloriesReject) {
        reject('calories_too_high');
      } else if (calories > maxCaloriesSuspicious) {
        flag('calories_high');
      }
    }

    final runnerPace = runnerAvgPaceSecPerKm;
    if (runnerPace != null && runnerPace > 0) {
      if (runnerPace < minPaceSecPerKmReject) {
        reject('runner_pace_too_fast');
      } else if (runnerPace < minPaceSecPerKmSuspicious) {
        flag('runner_pace_fast');
      }
    }

    if (workoutsCompletedSameDay >= maxWorkoutsSameDayReject) {
      reject('too_many_workouts_same_day');
    } else if (workoutsCompletedSameDay >= maxWorkoutsSameDaySuspicious) {
      flag('many_workouts_same_day');
    }

    return WorkoutValidationResult(status: status, reasons: reasons);
  }
}

class WorkoutCompletionValidation {
  final WorkoutValidationResult validation;
  final HyroxValidationResult? hyroxValidation;

  const WorkoutCompletionValidation({
    required this.validation,
    this.hyroxValidation,
  });

  bool get skipXp =>
      validation.status == WorkoutValidationStatus.rejected ||
      hyroxValidation?.status == HyroxValidationStatus.rejected;

  bool get countsForLeaderboard =>
      validation.countsForLeaderboard &&
      (hyroxValidation?.countsForLeaderboard ?? true);
}
