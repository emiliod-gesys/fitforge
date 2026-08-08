import '../../models/food_entry.dart';

/// Barreras deterministas para no mostrar estimaciones físicamente imposibles.
abstract final class FoodEstimateValidator {
  static FoodNutritionEstimate? validateAndCorrect(
    FoodNutritionEstimate estimate,
  ) {
    if (estimate.referenceAmount <= 0 || estimate.caloriesKcal < 0) return null;
    if (_hasNegativeMacros(estimate)) return null;

    var corrected = estimate;
    final portionTotal = estimate.ingredientPortions.fold<double>(
      0,
      (sum, portion) => sum + portion.gramsG,
    );
    if (portionTotal > 0) {
      final difference =
          (portionTotal - estimate.referenceAmount).abs() / portionTotal;
      if (difference > 0.25) return null;
      if (difference > 0.05) {
        corrected = corrected.copyWith(
          referenceAmount: portionTotal,
          servingDescription: '${portionTotal.round()} g',
        );
      }
    }

    final amount = corrected.referenceAmount;
    final factor = 100 / amount;
    final kcalPer100 = corrected.caloriesKcal * factor;
    final proteinPer100 = corrected.proteinG * factor;
    final carbsPer100 = corrected.carbsG * factor;
    final fatPer100 = corrected.fatG * factor;
    final fiberPer100 = corrected.fiberG * factor;

    if (kcalPer100 > 950 ||
        proteinPer100 > 100 ||
        carbsPer100 > 100 ||
        fatPer100 > 100 ||
        fiberPer100 > 100) {
      return null;
    }

    final macroCalories =
        corrected.proteinG * 4 + corrected.carbsG * 4 + corrected.fatG * 9;
    if (macroCalories > 0) {
      final difference =
          (corrected.caloriesKcal - macroCalories).abs() / macroCalories;
      // Tolera redondeo, fibra y alcohol; corrige discrepancias claramente
      // incompatibles con los macros devueltos.
      if (difference > 0.35 &&
          (corrected.caloriesKcal - macroCalories).abs() > 40) {
        corrected = corrected.copyWith(
          caloriesKcal: macroCalories.round(),
        );
      }
    }

    return corrected;
  }

  static bool _hasNegativeMacros(FoodNutritionEstimate estimate) {
    return estimate.proteinG < 0 ||
        estimate.carbsG < 0 ||
        estimate.fatG < 0 ||
        estimate.fiberG < 0;
  }
}
