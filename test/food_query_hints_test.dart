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

    test('reconcile fixes spaghetti when AI returns per-100g kcal at full weight', () {
      const ai = FoodNutritionEstimate(
        name: 'Espagueti cocido simple',
        caloriesKcal: 128,
        proteinG: 5,
        carbsG: 25,
        fatG: 1,
        referenceAmount: 320,
      );

      final fixed = FoodQueryHints.reconcile('320g espagueti cocido simple', ai);

      expect(fixed.referenceAmount, 320);
      expect(fixed.caloriesKcal, greaterThan(350));
      expect(fixed.caloriesKcal, lessThan(450));
    });

    test('fixPer100gConfusion scales when reference is 100g but user asked more', () {
      const ai = FoodNutritionEstimate(
        name: 'Pasta',
        caloriesKcal: 131,
        proteinG: 5,
        carbsG: 25,
        fatG: 1,
        referenceAmount: 100,
      );

      final fixed = FoodQueryHints.fixPer100gConfusion('300g pasta cocida', ai);

      expect(fixed.caloriesKcal, 393);
      expect(fixed.referenceAmount, 300);
    });
  });
}
