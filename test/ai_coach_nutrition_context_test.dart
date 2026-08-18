import 'package:fitforge/core/utils/ai_coach_context.dart';
import 'package:fitforge/core/utils/daily_nutrition_budget.dart';
import 'package:fitforge/models/coach_nutrition_snapshot.dart';
import 'package:fitforge/models/food_entry.dart';
import 'package:fitforge/models/profile.dart';
import 'package:fitforge/models/workout.dart';
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

  test('anchors last workout with RIR and today protein at the top', () {
    final profile = UserProfile(
      id: 'u1',
      fitnessGoal: 'Hipertrofia',
      createdAt: DateTime(2026, 1, 1),
    );
    final workout = Workout(
      id: 'w1',
      userId: 'u1',
      name: 'Push',
      startedAt: DateTime(2026, 8, 16, 18),
      completedAt: DateTime(2026, 8, 16, 19),
      durationMinutes: 58,
      exercises: [
        WorkoutExercise(
          id: 'e1',
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          orderIndex: 0,
          sets: const [
            WorkoutSet(
              id: 's1',
              setNumber: 1,
              weight: 80,
              reps: 8,
              rir: 0,
              completed: true,
            ),
            WorkoutSet(
              id: 's2',
              setNumber: 2,
              weight: 82.5,
              reps: 8,
              rir: 3,
              completed: true,
            ),
          ],
        ),
      ],
    );

    final today = DateTime(2026, 8, 17);
    final lunch = FoodEntry(
      id: '1',
      userId: 'u1',
      loggedAt: DateTime(2026, 8, 17, 14, 20),
      mealType: MealType.lunch,
      name: 'Pollo',
      caloriesKcal: 450,
      proteinG: 40,
      carbsG: 10,
      fatG: 12,
    );
    final todaySummary = DailyNutritionBudget.build(
      day: today,
      entries: [lunch],
      workoutsCompletedOnDay: const [],
      profile: profile,
    );
    final nutrition = CoachNutritionSnapshot(
      today: todaySummary,
      weekHistory: [todaySummary],
      loadedAt: DateTime(2026, 8, 17, 18),
    );

    final context = AiCoachContextBuilder.build(
      profile: profile,
      recentWorkouts: [workout],
      nutrition: nutrition,
    );

    expect(context, contains('ANCLAJE OBLIGATORIO'));
    expect(context, contains('ÚLTIMO ENTRENO'));
    expect(context, contains('Bench Press'));
    expect(context, contains('RIR 0'));
    expect(context, contains('RIR +3'));
    expect(context, contains('Última comida'));
    expect(context, contains('Pollo'));
    expect(context, contains('Proteína'));
  });
}
