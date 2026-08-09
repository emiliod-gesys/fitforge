import 'package:fitforge/core/utils/water_goal_calculator.dart';
import 'package:fitforge/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WaterGoalCalculator', () {
    test('uses weight and gender for goal in glass multiples', () {
      final male = WaterGoalCalculator.goalMl(
        profile: UserProfile(
          id: '1',
          createdAt: DateTime(2024),
          bodyWeight: 80,
          gender: Gender.male,
        ),
      );
      expect(male, 2800);

      final female = WaterGoalCalculator.goalMl(
        profile: UserProfile(
          id: '2',
          createdAt: DateTime(2024),
          bodyWeight: 60,
          gender: Gender.female,
        ),
      );
      // 60 * 31 = 1860
      expect(female, 1860);
    });

    test('falls back without weight', () {
      expect(
        WaterGoalCalculator.goalMl(
          profile: UserProfile(
            id: '1',
            createdAt: DateTime(2024),
            gender: Gender.male,
          ),
        ),
        WaterGoalCalculator.fallbackMaleMl,
      );
      expect(
        WaterGoalCalculator.goalMl(profile: null),
        WaterGoalCalculator.fallbackDefaultMl,
      );
    });

    test('formats liters and fl oz', () {
      expect(
        WaterGoalCalculator.formatVolume(2500, useFlOz: false),
        '2.50 L',
      );
      expect(
        WaterGoalCalculator.formatVolume(2000, useFlOz: false),
        '2 L',
      );
      final oz = WaterGoalCalculator.formatVolume(250, useFlOz: true);
      expect(oz, contains('oz'));
      expect(WaterGoalCalculator.flOzToMl(8.45), inInclusiveRange(249, 251));
    });

    test('uses profile override for goal', () {
      final profile = UserProfile(
        id: '1',
        createdAt: DateTime(2024),
        bodyWeight: 80,
        gender: Gender.male,
        waterGoalMl: 3200,
      );
      expect(
        WaterGoalCalculator.suggestedGoalMl(profile: profile),
        2800,
      );
      expect(WaterGoalCalculator.goalMl(profile: profile), 3200);
    });

    test('warns when water goal is too low or too high', () {
      expect(
        WaterGoalCalculator.evaluate(selectedMl: 1000, suggestedMl: 2800),
        WaterGoalWarning.tooLow,
      );
      expect(
        WaterGoalCalculator.evaluate(selectedMl: 4500, suggestedMl: 2800),
        WaterGoalWarning.tooHigh,
      );
      expect(
        WaterGoalCalculator.evaluate(selectedMl: 2800, suggestedMl: 2800),
        isNull,
      );
    });
  });
}
