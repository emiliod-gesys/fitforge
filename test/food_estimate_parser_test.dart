import 'package:fitforge/core/utils/food_estimate_parser.dart';
import 'package:fitforge/models/food_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoodEstimateParser', () {
    test('uses reference_amount_g from photo-style JSON', () {
      final estimate = FoodEstimateParser.parse('''
{
  "name": "Pollo con arroz",
  "calories_kcal": 520,
  "protein_g": 42,
  "carbs_g": 55,
  "fat_g": 12,
  "reference_amount_g": 320,
  "serving_description": "1 plato ~320 g"
}
''');

      expect(estimate, isNotNull);
      expect(estimate!.referenceAmount, 320);
      expect(estimate.caloriesKcal, 520);
    });

    test('parses grams from serving_description when reference missing', () {
      final estimate = FoodEstimateParser.parse('''
{
  "name": "Ensalada",
  "calories_kcal": 180,
  "protein_g": 8,
  "carbs_g": 12,
  "fat_g": 10,
  "serving_description": "1 bowl (245 g)"
}
''');

      expect(estimate?.referenceAmount, 245);
    });

    test('formats serving from reference_amount_g when description empty', () {
      final estimate = FoodEstimateParser.parse('''
{
  "name": "Pasta",
  "calories_kcal": 410,
  "protein_g": 14,
  "carbs_g": 62,
  "fat_g": 9,
  "reference_amount_g": 275
}
''');

      expect(estimate?.referenceAmount, 275);
      expect(estimate?.servingDescription, '275 g');
    });

    test('stabilizeRevision restores dropped ingredients on partial correction', () {
      const previous = FoodNutritionEstimate(
        name: 'Arroz con cerdo y brócoli',
        caloriesKcal: 520,
        proteinG: 35,
        carbsG: 55,
        fatG: 12,
        referenceAmount: 300,
        ingredients: ['arroz', 'cerdo', 'brócoli'],
      );
      const revised = FoodNutritionEstimate(
        name: 'Arroz con pollo',
        caloriesKcal: 480,
        proteinG: 38,
        carbsG: 50,
        fatG: 8,
        referenceAmount: 300,
        ingredients: ['arroz', 'pollo'],
      );

      final stabilized = FoodEstimateParser.stabilizeRevision(
        previous: previous,
        revised: revised,
        correction: 'no es cerdo, es pollo',
      );

      expect(stabilized.ingredients, contains('brócoli'));
      expect(stabilized.ingredients, contains('pollo'));
      expect(stabilized.ingredients, isNot(contains('cerdo')));
    });

    test('correctionImpliesRemoval detects explicit removal', () {
      expect(FoodEstimateParser.correctionImpliesRemoval('sin brócoli'), isTrue);
      expect(FoodEstimateParser.correctionImpliesRemoval('es pollo no cerdo'), isFalse);
    });
  });
}
