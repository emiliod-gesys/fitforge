import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge/core/utils/workout_calorie_estimator.dart';
import 'package:fitforge/models/body_metric.dart';
import 'package:fitforge/models/profile.dart';

void main() {
  test('estima calorías con peso del perfil y duración', () {
    final profile = UserProfile(
      id: 'u1',
      bodyWeight: 80,
      age: 28,
      heightCm: 178,
      gender: Gender.male,
      createdAt: DateTime.utc(2026),
    );

    final result = WorkoutCalorieEstimator.estimate(
      durationMinutes: 50,
      totalVolumeKg: 6000,
      completedSets: 18,
      totalReps: 120,
      profile: profile,
    );

    expect(result.isAvailable, isTrue);
    expect(result.caloriesKcal, inInclusiveRange(180, 480));
    expect(result.usedDefaultWeight, isFalse);
    expect(result.met, inInclusiveRange(3.5, 6.0));
  });

  test('usa peso por defecto si no hay datos corporales', () {
    final result = WorkoutCalorieEstimator.estimate(
      durationMinutes: 45,
      totalVolumeKg: 4000,
      completedSets: 15,
      totalReps: 90,
    );

    expect(result.isAvailable, isTrue);
    expect(result.usedDefaultWeight, isTrue);
  });

  test('prioriza peso de métricas corporales', () {
    final profile = UserProfile(
      id: 'u1',
      bodyWeight: 60,
      createdAt: DateTime.utc(2026),
    );

    final result = WorkoutCalorieEstimator.estimate(
      durationMinutes: 40,
      totalVolumeKg: 3000,
      completedSets: 12,
      totalReps: 72,
      profile: profile,
      bodyMetrics: {
        'weight': const BodyMetricSnapshot(type: 'weight', valueKg: 85),
      },
    );

    expect(result.usedDefaultWeight, isFalse);
    expect(result.caloriesKcal, greaterThan(150));
  });

  test('net active calories are lower than gross MET estimate', () {
    final profile = UserProfile(
      id: 'u1',
      bodyWeight: 80,
      age: 28,
      heightCm: 178,
      gender: Gender.male,
      createdAt: DateTime.utc(2026),
    );

    final result = WorkoutCalorieEstimator.estimate(
      durationMinutes: 60,
      totalVolumeKg: 5000,
      completedSets: 20,
      totalReps: 100,
      profile: profile,
    );

    final met = result.met!;
    const durationHours = 1.0;
    const weightKg = 80.0;
    final gross = met * weightKg * durationHours;

    expect(result.caloriesKcal!, lessThan(gross.round()));
  });
}
