import '../core/utils/daily_nutrition_budget.dart';
import '../models/body_metric.dart';
import '../models/coach_nutrition_snapshot.dart';
import '../models/food_entry.dart';
import '../models/manual_activity_entry.dart';
import '../models/profile.dart';
import '../models/workout.dart';
import 'activity_log_service.dart';
import 'food_service.dart';
import 'workout_service.dart';

/// Carga ingesta nutricional actual y historial semanal para el Coach IA.
class CoachNutritionService {
  CoachNutritionService({
    required FoodService foodService,
    required WorkoutService workoutService,
    required ActivityLogService activityLogService,
  })  : _foodService = foodService,
        _workoutService = workoutService,
        _activityLogService = activityLogService;

  final FoodService _foodService;
  final WorkoutService _workoutService;
  final ActivityLogService _activityLogService;

  Future<CoachNutritionSnapshot?> load({
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));

    final results = await Future.wait([
      _foodService.getEntriesSince(weekStart),
      _workoutService.getCompletedWorkoutsSince(weekStart),
      _activityLogService.getEntriesSince(weekStart),
    ]);

    final allEntries = results[0] as List<FoodEntry>;
    final allWorkouts = results[1] as List<Workout>;
    final allActivities = results[2] as List<ManualActivityEntry>;

    final weekHistory = <DailyNutritionSummary>[];
    for (var offset = 0; offset < 7; offset++) {
      final day = weekStart.add(Duration(days: offset));
      final dayEnd = day.add(const Duration(days: 1));

      final dayEntries = allEntries.where((entry) {
        final local = entry.loggedAt.toLocal();
        return !local.isBefore(day) && local.isBefore(dayEnd);
      }).toList();

      final dayWorkouts = allWorkouts.where((workout) {
        final completed = workout.completedAt;
        if (completed == null) return false;
        final local = completed.toLocal();
        return !local.isBefore(day) && local.isBefore(dayEnd);
      }).toList();

      final dayActivities = allActivities.where((activity) {
        final local = activity.loggedAt.toLocal();
        return !local.isBefore(day) && local.isBefore(dayEnd);
      }).toList();

      weekHistory.add(
        DailyNutritionBudget.build(
          day: day,
          entries: dayEntries,
          workoutsCompletedOnDay: dayWorkouts,
          manualActivities: dayActivities,
          profile: profile,
          bodyMetrics: bodyMetrics,
        ),
      );
    }

    return CoachNutritionSnapshot(
      today: weekHistory.last,
      weekHistory: weekHistory,
      loadedAt: now,
    );
  }
}
