import 'package:fitforge/core/utils/ai_coach_context.dart';
import 'package:fitforge/core/utils/daily_nutrition_budget.dart';
import 'package:fitforge/models/coach_nutrition_snapshot.dart';
import 'package:fitforge/models/food_entry.dart';
import 'package:fitforge/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('includes today nutrition and weekly history in coach context', () {
    final today = DateTime(2026, 7, 9);
    final breakfast = FoodEntry(
      id: '1',
      userId: 'u1',
      loggedAt: DateTime(2026, 7, 9, 8, 30),
      mealType: MealType.breakfast,
      name: 'Avena con plátano',
      caloriesKcal: 420,
      proteinG: 12,
      carbsG: 58,
      fatG: 8,
    );

    final profile = UserProfile(
      id: 'u1',
      fitnessGoal: 'Hipertrofia',
      createdAt: DateTime(2026, 1, 1),
    );

    final todaySummary = DailyNutritionBudget.build(
      day: today,
      entries: [breakfast],
      workoutsCompletedOnDay: const [],
      profile: profile,
    );

    final emptyDay = DailyNutritionBudget.build(
      day: today.subtract(const Duration(days: 1)),
      entries: const [],
      workoutsCompletedOnDay: const [],
      profile: profile,
    );

    final nutrition = CoachNutritionSnapshot(
      today: todaySummary,
      weekHistory: [emptyDay, todaySummary],
      loadedAt: DateTime(2026, 7, 9, 14, 15),
    );

    final context = AiCoachContextBuilder.build(
      profile: profile,
      nutrition: nutrition,
    );

    expect(context, contains('NUTRICIÓN HOY'));
    expect(context, contains('Avena con plátano'));
    expect(context, contains('420 kcal'));
    expect(context, contains('HISTORIAL NUTRICIONAL'));
    expect(context, contains('Promedio en días con registro'));
  });
}
