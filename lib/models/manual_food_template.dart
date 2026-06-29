import 'food_entry.dart';
import '../core/utils/food_serving_parser.dart';

/// Alimento definido manualmente por el usuario, persistido solo en el dispositivo.
class ManualFoodTemplate {
  final String id;
  final String name;
  final int caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final String? servingDescription;
  final DateTime updatedAt;

  const ManualFoodTemplate({
    required this.id,
    required this.name,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG = 0,
    this.servingDescription,
    required this.updatedAt,
  });

  factory ManualFoodTemplate.fromJson(Map<String, dynamic> json) {
    return ManualFoodTemplate(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      caloriesKcal: json['calories_kcal'] as int? ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
      servingDescription: json['serving_description'] as String?,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories_kcal': caloriesKcal,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'fiber_g': fiberG,
        if (servingDescription != null) 'serving_description': servingDescription,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  FoodNutritionEstimate toEstimate() {
    final reference = FoodServingParser.amountFromDescription(servingDescription) ?? 100;
    final serving = servingDescription?.trim();
    return FoodNutritionEstimate(
      name: name,
      caloriesKcal: caloriesKcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      fiberG: fiberG,
      servingDescription: serving != null && serving.isNotEmpty
          ? serving
          : FoodServingParser.formatAmount(reference, 'g'),
      referenceAmount: reference,
      amountUnit: 'g',
    );
  }

  FoodEntry toPreviewEntry({required MealType mealType}) {
    final serving = servingDescription?.trim();
    return FoodEntry(
      id: id,
      userId: 'local',
      loggedAt: updatedAt,
      mealType: mealType,
      name: name,
      caloriesKcal: caloriesKcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      fiberG: fiberG,
      servingDescription: serving != null && serving.isNotEmpty ? serving : null,
      source: FoodEntrySource.manual,
    );
  }
}
