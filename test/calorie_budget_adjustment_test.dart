import 'package:fitforge/core/utils/calorie_budget_adjustment.dart';
import 'package:fitforge/core/utils/daily_nutrition_budget.dart';
import 'package:fitforge/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalorieBudgetAdjustment', () {
    test('custom percent yields higher goal than default deficit', () {
      final day = DateTime(2026, 6, 15);
      final baseProfile = UserProfile(
        id: 'u1',
        bodyWeight: 82,
        age: 28,
        gender: Gender.male,
        heightCm: 178,
        fitnessGoal: 'Pérdida de grasa',
        activityLevel: DailyActivityLevel.moderate,
        createdAt: DateTime(2026, 1, 1),
      );

      final defaultSummary = DailyNutritionBudget.build(
        day: day,
        entries: const [],
        workoutsCompletedOnDay: const [],
        profile: baseProfile,
        bodyMetrics: null,
      );
      final customSummary = DailyNutritionBudget.build(
        day: day,
        entries: const [],
        workoutsCompletedOnDay: const [],
        profile: UserProfile(
          id: baseProfile.id,
          bodyWeight: baseProfile.bodyWeight,
          age: baseProfile.age,
          gender: baseProfile.gender,
          heightCm: baseProfile.heightCm,
          fitnessGoal: baseProfile.fitnessGoal,
          activityLevel: baseProfile.activityLevel,
          calorieAdjustmentPct: -10,
          createdAt: baseProfile.createdAt,
        ),
        bodyMetrics: null,
      );

      expect(customSummary.baseCalorieGoal, greaterThan(defaultSummary.baseCalorieGoal));
    });

    test('display intensity maps deficit correctly', () {
      expect(
        CalorieBudgetAdjustment.displayIntensity('Pérdida de grasa', -15),
        15,
      );
      expect(
        CalorieBudgetAdjustment.adjustmentFromDisplay('Pérdida de grasa', 20),
        -20,
      );
      expect(
        CalorieBudgetAdjustment.adjustmentFromDisplay('Hipertrofia', 10),
        10,
      );
    });

    test('warns when deficit kcal below 100', () {
      final warning = CalorieBudgetAdjustment.evaluate(
        goal: 'Pérdida de grasa',
        tdee: 1500,
        adjustmentPct: -5,
      );
      expect(warning, CalorieBudgetWarning.deficitTooSmall);
    });
  });
}
