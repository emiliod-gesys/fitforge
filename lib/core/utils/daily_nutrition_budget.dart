import '../../models/body_metric.dart';
import '../../models/food_entry.dart';
import '../../models/profile.dart';
import '../../models/workout.dart';
import 'bmr_calculator.dart';
import 'workout_calorie_estimator.dart';

/// Calcula objetivo calórico diario, macros y balance con entrenos del día.
abstract final class DailyNutritionBudget {
  static const _defaultCalorieGoal = 2200;

  static DailyNutritionSummary build({
    required DateTime day,
    required List<FoodEntry> entries,
    required List<Workout> workoutsCompletedOnDay,
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
  }) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final dayEntries = entries.where((e) {
      final local = e.loggedAt.toLocal();
      return !local.isBefore(dayStart) && local.isBefore(dayEnd);
    }).toList();

    final eaten = MacroTotals.fromEntries(dayEntries);
    final bmr = BmrCalculator.calculate(profile: profile, snapshots: bodyMetrics);
    final weightKg = _weightKg(profile, bodyMetrics);

    final baseGoal = bmr != null
        ? _baseCalorieGoal(
            bmr: bmr,
            goal: profile?.fitnessGoal,
            weightKg: weightKg,
            activityLevel: profile?.activityLevel ?? DailyActivityLevel.moderate,
          )
        : _defaultCalorieGoal;

    var workoutBurned = 0;
    for (final workout in workoutsCompletedOnDay) {
      workoutBurned += WorkoutCalorieEstimator.resolvedActiveCalories(
        workout: workout,
        profile: profile,
        bodyMetrics: bodyMetrics,
      );
    }

    final calorieBudget = baseGoal + workoutBurned;
    final remaining = (calorieBudget - eaten.caloriesKcal).clamp(0, 99999);

    final targets = _macroTargets(
      calorieGoal: calorieBudget,
      weightKg: weightKg,
      goal: profile?.fitnessGoal,
    );

    final byMeal = <MealType, List<FoodEntry>>{
      for (final meal in MealType.values) meal: [],
    };
    for (final entry in dayEntries) {
      byMeal[entry.mealType]!.add(entry);
    }
    for (final list in byMeal.values) {
      list.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    }

    return DailyNutritionSummary(
      day: dayStart,
      baseCalorieGoal: baseGoal,
      workoutCaloriesBurned: workoutBurned,
      calorieBudget: calorieBudget,
      caloriesEaten: eaten.caloriesKcal,
      caloriesRemaining: remaining,
      targets: targets,
      eaten: eaten,
      entriesByMeal: byMeal,
      bmrAvailable: bmr != null,
    );
  }

  static int _baseCalorieGoal({
    required double bmr,
    required String? goal,
    required double weightKg,
    required DailyActivityLevel activityLevel,
  }) {
    var tdee = (bmr * activityLevel.tdeeFactor).round();
    final g = (goal ?? '').toLowerCase();

    if (g.contains('pérdida') ||
        g.contains('perdida') ||
        g.contains('fat') ||
        g.contains('grasa')) {
      tdee = (tdee * 0.85).round();
    } else if (g.contains('hipertrofia') ||
        g.contains('hypertrophy') ||
        g.contains('fuerza') ||
        g.contains('strength')) {
      tdee = (tdee * 1.08).round();
    }

    return tdee.clamp(1200, 6000);
  }

  static MacroTargets _macroTargets({
    required int calorieGoal,
    required double weightKg,
    required String? goal,
  }) {
    final g = (goal ?? '').toLowerCase();
    final proteinPerKg = g.contains('hipertrofia') ||
            g.contains('hypertrophy') ||
            g.contains('fuerza') ||
            g.contains('strength')
        ? 2.0
        : g.contains('pérdida') || g.contains('perdida') || g.contains('fat')
            ? 2.2
            : 1.6;

    final proteinG = (weightKg * proteinPerKg).clamp(50.0, 350.0);
    final proteinKcal = proteinG * 4;
    final fatKcal = calorieGoal * 0.28;
    final fatG = fatKcal / 9;
    final carbsKcal = (calorieGoal - proteinKcal - fatKcal).clamp(400.0, calorieGoal.toDouble());
    final carbsG = carbsKcal / 4;

    return MacroTargets(
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      fiberG: 30,
    );
  }

  static double _weightKg(UserProfile? profile, Map<String, BodyMetricSnapshot>? metrics) {
    final fromMetrics = metrics?['weight']?.valueKg;
    if (fromMetrics != null && fromMetrics > 20) return fromMetrics;
    final fromProfile = profile?.bodyWeight;
    if (fromProfile != null && fromProfile > 20) return fromProfile;
    return 70;
  }

  static bool isSameCalendarDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }
}
