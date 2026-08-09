import 'package:health/health.dart';

import '../../core/runner/runner_standards.dart';

/// Elige un [HealthWorkoutActivityType] válido en iOS y Android.
abstract final class HealthWorkoutActivityMapper {
  static HealthWorkoutActivityType resolve({
    required bool isRunner,
    required bool isHyrox,
    RunnerType? runnerType,
    required bool isIOS,
  }) {
    if (isRunner) {
      if (runnerType == RunnerType.outdoorWalk) {
        return HealthWorkoutActivityType.WALKING;
      }
      if (runnerType == RunnerType.treadmill) {
        // RUNNING_TREADMILL solo existe en Android; en iOS es RUNNING.
        return isIOS
            ? HealthWorkoutActivityType.RUNNING
            : HealthWorkoutActivityType.RUNNING_TREADMILL;
      }
      return HealthWorkoutActivityType.RUNNING;
    }

    if (isHyrox) {
      return HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING;
    }

    return isIOS
        ? HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING
        : HealthWorkoutActivityType.STRENGTH_TRAINING;
  }
}
