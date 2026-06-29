import 'dart:convert';

import '../../models/food_entry.dart';
import 'food_serving_parser.dart';

/// Parsea la respuesta JSON de estimación nutricional por IA.
abstract final class FoodEstimateParser {
  /// Serializa la estimación previa para correcciones incrementales.
  static Map<String, dynamic> toRevisionContext(FoodNutritionEstimate estimate) {
    return {
      'name': estimate.name,
      'brand': estimate.brand,
      'calories_kcal': estimate.caloriesKcal,
      'protein_g': estimate.proteinG,
      'carbs_g': estimate.carbsG,
      'fat_g': estimate.fatG,
      'fiber_g': estimate.fiberG,
      'serving_description': estimate.servingDescription,
      'reference_amount_g': estimate.referenceAmount,
      'ingredients': estimate.ingredients,
    };
  }

  static bool correctionImpliesRemoval(String correction) {
    final lower = correction.toLowerCase();
    const markers = [
      'sin ',
      'quitar',
      'elimina',
      'remove',
      'no hay',
      'no lleva',
      'no tiene',
      'solo ',
      'solamente',
    ];
    return markers.any(lower.contains);
  }

  static bool ingredientRejectedByCorrection(String ingredient, String correction) {
    final ing = ingredient.toLowerCase().trim();
    if (ing.isEmpty) return false;
    final lower = correction.toLowerCase();
    const prefixes = ['no es ', 'no era ', 'no son ', 'sin '];
    for (final prefix in prefixes) {
      final index = lower.indexOf(prefix);
      if (index < 0) continue;
      final after = lower.substring(index + prefix.length);
      if (after.contains(ing)) return true;
    }
    return false;
  }

  /// Evita que una corrección puntual borre ingredientes no mencionados.
  static FoodNutritionEstimate stabilizeRevision({
    required FoodNutritionEstimate previous,
    required FoodNutritionEstimate revised,
    required String correction,
  }) {
    if (correctionImpliesRemoval(correction)) return revised;
    if (previous.ingredients.isEmpty) return revised;

    final mergedIngredients = <String>[...revised.ingredients];
    for (final ingredient in previous.ingredients) {
      if (ingredientRejectedByCorrection(ingredient, correction)) continue;
      final alreadyListed = mergedIngredients.any(
        (item) => item.toLowerCase() == ingredient.toLowerCase(),
      );
      if (!alreadyListed) mergedIngredients.add(ingredient);
    }

    if (mergedIngredients.length <= revised.ingredients.length) return revised;

    return FoodNutritionEstimate(
      name: revised.name,
      brand: revised.brand,
      caloriesKcal: revised.caloriesKcal,
      proteinG: revised.proteinG,
      carbsG: revised.carbsG,
      fatG: revised.fatG,
      fiberG: revised.fiberG,
      servingDescription: revised.servingDescription ?? previous.servingDescription,
      ingredients: mergedIngredients,
      referenceAmount: revised.referenceAmount > 0 ? revised.referenceAmount : previous.referenceAmount,
      amountUnit: revised.amountUnit.isNotEmpty ? revised.amountUnit : previous.amountUnit,
    );
  }

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
