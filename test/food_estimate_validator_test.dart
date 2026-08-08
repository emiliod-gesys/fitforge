import 'package:fitforge/core/utils/food_estimate_validator.dart';
import 'package:fitforge/models/food_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoodEstimateValidator', () {
    test('aligns reference amount with ingredient portions', () {
      const estimate = FoodNutritionEstimate(
        name: 'Plato',
        caloriesKcal: 250,
        proteinG: 20,
        carbsG: 25,
        fatG: 8,
        referenceAmount: 140,
        ingredientPortions: [
          FoodIngredientPortion(name: 'A', gramsG: 100),
          FoodIngredientPortion(name: 'B', gramsG: 50),
        ],
      );

      final corrected = FoodEstimateValidator.validateAndCorrect(estimate);

      expect(corrected, isNotNull);
      expect(corrected!.referenceAmount, 150);
      expect(corrected.servingDescription, '150 g');
    });

    test('corrects calories that conflict strongly with macros', () {
      const estimate = FoodNutritionEstimate(
        name: 'Plato',
        caloriesKcal: 600,
        proteinG: 10,
        carbsG: 20,
        fatG: 5,
        referenceAmount: 200,
      );

      final corrected = FoodEstimateValidator.validateAndCorrect(estimate);

      expect(corrected, isNotNull);
      expect(corrected!.caloriesKcal, 165);
    });

    test('rejects physically impossible density', () {
      const estimate = FoodNutritionEstimate(
        name: 'Imposible',
        caloriesKcal: 1200,
        proteinG: 10,
        carbsG: 20,
        fatG: 5,
        referenceAmount: 100,
      );

      expect(FoodEstimateValidator.validateAndCorrect(estimate), isNull);
    });
  });
}
