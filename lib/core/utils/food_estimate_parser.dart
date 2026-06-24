import 'dart:convert';

import '../../models/food_entry.dart';
import 'food_serving_parser.dart';

/// Parsea la respuesta JSON de estimación nutricional por IA.
abstract final class FoodEstimateParser {
  static FoodNutritionEstimate? parse(String response) {
    try {
      final cleaned = response.replaceAll(RegExp(r'```json|```'), '').trim();
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start < 0 || end <= start) return null;

      final json = jsonDecode(cleaned.substring(start, end + 1));
      if (json is! Map<String, dynamic>) return null;

      final name = json['name'] as String?;
      if (name == null || name.isEmpty) return null;

      final servingRaw = json['serving_description'] as String?;
      final unit = FoodServingParser.unitFromDescription(servingRaw);
      final refFromJson = (json['reference_amount_g'] as num?)?.toDouble();
      final parsedFromServing = FoodServingParser.amountFromDescription(servingRaw);
      final referenceAmount = refFromJson ?? parsedFromServing ?? 100.0;
      final servingDescription = servingRaw != null && servingRaw.trim().isNotEmpty
          ? servingRaw.trim()
          : (refFromJson != null || parsedFromServing != null)
              ? FoodServingParser.formatAmount(referenceAmount, unit)
              : null;

      return FoodNutritionEstimate(
        name: name,
        brand: json['brand'] as String?,
        caloriesKcal: (json['calories_kcal'] as num?)?.round().clamp(0, 9999) ?? 0,
        proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
        fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
        servingDescription: servingDescription,
        ingredients: (json['ingredients'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        referenceAmount: referenceAmount,
        amountUnit: unit,
      );
    } catch (_) {
      return null;
    }
  }
}
