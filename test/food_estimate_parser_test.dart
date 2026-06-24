import 'package:fitforge/core/utils/food_estimate_parser.dart';
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
  });
}
