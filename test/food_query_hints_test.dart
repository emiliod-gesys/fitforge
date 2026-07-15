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

    test('parseIngredientGramsFromQuery reads explicit item weights', () {
      final portions = FoodQueryHints.parseIngredientGramsFromQuery(
        '320g espagueti cocido y 150g pollo a la plancha',
      );

      expect(portions.length, 2);
      expect(portions.any((p) => p.gramsG == 320 && p.name.contains('espagueti')), isTrue);
      expect(portions.any((p) => p.gramsG == 150 && p.name.contains('pollo')), isTrue);
    });

    test('ensureIngredientPortions applies user grams to AI ingredients', () {
      const ai = FoodNutritionEstimate(
        name: 'Espagueti cocido simple',
        caloriesKcal: 420,
        proteinG: 16,
        carbsG: 80,
        fatG: 3,
        referenceAmount: 320,
        ingredients: ['espagueti cocido'],
      );

      final fixed = FoodQueryHints.reconcile('320g espagueti cocido simple', ai);

      expect(fixed.ingredientPortions, isNotEmpty);
      expect(fixed.ingredientPortions.first.gramsG, 320);
    });

    test('reconcile builds portions for multi-ingredient AI response', () {
      const ai = FoodNutritionEstimate(
        name: 'Pollo con arroz',
        caloriesKcal: 520,
        proteinG: 40,
        carbsG: 55,
        fatG: 12,
        referenceAmount: 400,
        ingredients: ['pollo', 'arroz blanco'],
      );

      final fixed = FoodQueryHints.reconcile('pollo con arroz', ai);

      expect(fixed.ingredientPortions.length, 2);
      expect(
        fixed.ingredientPortions.fold<double>(0, (sum, p) => sum + p.gramsG),
        closeTo(400, 1),
      );
    });

    test('reconcilePhotoEstimate fills calories from ingredient portions when AI returns 0', () {
      const ai = FoodNutritionEstimate(
        name: 'Pechuga de pollo con arroz y brócoli',
        caloriesKcal: 0,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        referenceAmount: 320,
        ingredientPortions: [
          FoodIngredientPortion(name: 'pechuga de pollo', gramsG: 150),
          FoodIngredientPortion(name: 'arroz blanco', gramsG: 120),
          FoodIngredientPortion(name: 'brócoli', gramsG: 50),
        ],
      );

      final fixed = FoodQueryHints.reconcilePhotoEstimate(ai);

      // ~165*1.5 + 130*1.2 + 35*0.5 = 247.5 + 156 + 17.5 = 421
      expect(fixed.caloriesKcal, greaterThan(350));
      expect(fixed.caloriesKcal, lessThan(500));
      expect(fixed.proteinG, greaterThan(40));
      expect(fixed.referenceAmount, 320);
    });
  });
}
