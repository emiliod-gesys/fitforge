import 'package:fitforge/core/runner/runner_standards.dart';
import 'package:fitforge/services/health/health_workout_activity_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

void main() {
  group('HealthWorkoutActivityMapper', () {
    test('maps strength workouts per platform', () {
      expect(
        HealthWorkoutActivityMapper.resolve(
          isRunner: false,
          isHyrox: false,
          isIOS: true,
        ),
        HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING,
      );
      expect(
        HealthWorkoutActivityMapper.resolve(
          isRunner: false,
          isHyrox: false,
          isIOS: false,
        ),
        HealthWorkoutActivityType.STRENGTH_TRAINING,
      );
    });

    test('maps runner outdoor, walk, and treadmill', () {
      expect(
        HealthWorkoutActivityMapper.resolve(
          isRunner: true,
          isHyrox: false,
          runnerType: RunnerType.outdoor,
          isIOS: true,
        ),
        HealthWorkoutActivityType.RUNNING,
      );
      expect(
        HealthWorkoutActivityMapper.resolve(
          isRunner: true,
          isHyrox: false,
          runnerType: RunnerType.outdoorWalk,
          isIOS: true,
        ),
        HealthWorkoutActivityType.WALKING,
      );
      expect(
        HealthWorkoutActivityMapper.resolve(
          isRunner: true,
          isHyrox: false,
          runnerType: RunnerType.treadmill,
          isIOS: false,
        ),
        HealthWorkoutActivityType.RUNNING_TREADMILL,
      );
      expect(
        HealthWorkoutActivityMapper.resolve(
          isRunner: true,
          isHyrox: false,
          runnerType: RunnerType.treadmill,
          isIOS: true,
        ),
        HealthWorkoutActivityType.RUNNING,
      );
    });

    test('maps hyrox as HIIT', () {
      expect(
        HealthWorkoutActivityMapper.resolve(
          isRunner: false,
          isHyrox: true,
          isIOS: true,
        ),
        HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING,
      );
    });
  });
}
