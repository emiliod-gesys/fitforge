import 'package:fitforge/core/utils/food_query_hints.dart';
import 'package:fitforge/models/food_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoodQueryHints', () {
    const query =
        'Dos huevos estrellados sin aceite y dos tortillas de harina de 56kcal cada una';

    test('parses labeled kcal and egg count', () {
      expect(FoodQueryHints.labeledKcalTotal(query), 112);
      expect(FoodQueryHints.eggCount(query), 2);
    });

    test('reconcile raises underestimated AI calories', () {
      const ai = FoodNutritionEstimate(
        name: 'huevos con tortillas',
        caloriesKcal: 168,
        proteinG: 12,
        carbsG: 28,
        fatG: 10,
        referenceAmount: 180,
      );

      final fixed = FoodQueryHints.reconcile(query, ai);

      expect(fixed.caloriesKcal, greaterThanOrEqualTo(260));
      expect(fixed.proteinG, greaterThan(14));
    });

    test('anchored estimate corrects green apple per 100g', () {
      const ai = FoodNutritionEstimate(
        name: 'Manzana verde',
        caloriesKcal: 96,
        proteinG: 0.5,
        carbsG: 25,
        fatG: 0.3,
        referenceAmount: 100,
      );

      final fixed = FoodQueryHints.reconcile('manzana verde 100g', ai);

      expect(fixed.caloriesKcal, 52);
      expect(fixed.carbsG, closeTo(14, 0.5));
    });
  });
}
