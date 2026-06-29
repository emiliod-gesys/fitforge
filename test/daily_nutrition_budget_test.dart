import 'package:fitforge/core/utils/daily_nutrition_budget.dart';
import 'package:fitforge/models/food_entry.dart';
import 'package:fitforge/models/manual_activity_entry.dart';
import 'package:fitforge/models/profile.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyNutritionBudget', () {
    test('adds manual activity calories to daily budget', () {
      final day = DateTime(2026, 6, 15);
      final activities = [
        ManualActivityEntry(
          id: 'a1',
          userId: 'u1',
          loggedAt: day.add(const Duration(hours: 11)),
          name: 'Caminata',
          caloriesKcal: 200,
        ),
      ];

      final summary = DailyNutritionBudget.build(
        day: day,
        entries: const [],
        workoutsCompletedOnDay: const [],
        manualActivities: activities,
        profile: null,
        bodyMetrics: null,
      );

      expect(summary.manualActivityCaloriesBurned, 200);
      expect(summary.totalCaloriesBurned, 200);
      expect(summary.calorieBudget, 2200 + 200);
    });

    test('adds workout calories to daily budget', () {
      final day = DateTime(2026, 6, 15);
      final profile = UserProfile(
        id: 'u1',
        bodyWeight: 80,
        fitnessGoal: 'Mantenimiento',
        createdAt: DateTime(2026, 1, 1),
      );
      final workout = Workout(
        id: 'w1',
        userId: 'u1',
        name: 'Push',
        startedAt: day.add(const Duration(hours: 9)),
        completedAt: day.add(const Duration(hours: 10)),
        durationMinutes: 60,
        totalVolume: 5000,
      );

      final summary = DailyNutritionBudget.build(
        day: day,
        entries: const [],
        workoutsCompletedOnDay: [workout],
        profile: profile,
        bodyMetrics: null,
      );

      expect(summary.workoutCaloriesBurned, greaterThan(0));
      expect(summary.calorieBudget, greaterThan(summary.baseCalorieGoal));
    });

    test('uses stored workout calories when available', () {
      final day = DateTime(2026, 6, 15);
      final workout = Workout(
        id: 'w1',
        userId: 'u1',
        name: 'Push',
        startedAt: day.add(const Duration(hours: 9)),
        completedAt: day.add(const Duration(hours: 10)),
        durationMinutes: 60,
        totalVolume: 5000,
        activeCaloriesKcal: 390,
      );

      final summary = DailyNutritionBudget.build(
        day: day,
        entries: const [],
        workoutsCompletedOnDay: [workout],
        profile: UserProfile(
          id: 'u1',
          bodyWeight: 80,
          createdAt: DateTime(2026, 1, 1),
        ),
        bodyMetrics: null,
      );

      expect(summary.workoutCaloriesBurned, 390);
    });

    test('sums eaten macros from entries on the same day', () {
      final day = DateTime(2026, 6, 15);
      final entries = [
        FoodEntry(
          id: '1',
          userId: 'u1',
          loggedAt: day.add(const Duration(hours: 8)),
          mealType: MealType.breakfast,
          name: 'Avena',
          caloriesKcal: 300,
          proteinG: 10,
          carbsG: 40,
          fatG: 8,
          fiberG: 5,
        ),
      ];

      final summary = DailyNutritionBudget.build(
        day: day,
        entries: entries,
        workoutsCompletedOnDay: const [],
        profile: null,
        bodyMetrics: null,
      );

      expect(summary.caloriesEaten, 300);
      expect(summary.eaten.proteinG, 10);
      expect(summary.eaten.fiberG, 5);
    });
    test('sedentary fat loss yields lower goal than moderate', () {
      final sedentary = DailyNutritionBudget.build(
        day: DateTime(2026, 6, 15),
        entries: const [],
        workoutsCompletedOnDay: const [],
        profile: UserProfile(
          id: 'u1',
          bodyWeight: 82,
          age: 28,
          gender: Gender.male,
          heightCm: 178,
          fitnessGoal: 'Pérdida de grasa',
          activityLevel: DailyActivityLevel.sedentary,
          createdAt: DateTime(2026, 1, 1),
        ),
        bodyMetrics: null,
      );
      final moderate = DailyNutritionBudget.build(
        day: DateTime(2026, 6, 15),
        entries: const [],
        workoutsCompletedOnDay: const [],
        profile: UserProfile(
          id: 'u1',
          bodyWeight: 82,
          age: 28,
          gender: Gender.male,
          heightCm: 178,
          fitnessGoal: 'Pérdida de grasa',
          activityLevel: DailyActivityLevel.moderate,
          createdAt: DateTime(2026, 1, 1),
        ),
        bodyMetrics: null,
      );

      expect(sedentary.baseCalorieGoal, lessThan(moderate.baseCalorieGoal));
      expect(
        sedentary.baseCalorieGoal / moderate.baseCalorieGoal,
        closeTo(1.2 / 1.55, 0.01),
      );
    });
  });
}
