import 'food_entry.dart';

/// Nutrición del usuario para el Coach IA: hoy en tiempo real + últimos 7 días.
class CoachNutritionSnapshot {
  const CoachNutritionSnapshot({
    required this.today,
    required this.weekHistory,
    required this.loadedAt,
  });

  final DailyNutritionSummary today;
  final List<DailyNutritionSummary> weekHistory;
  final DateTime loadedAt;
}
