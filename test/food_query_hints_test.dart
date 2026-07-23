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

    test('parses English egg count', () {
      expect(
        FoodQueryHints.eggCount('Three scrambled eggs and a cup of raw oatmeal'),
        3,
      );
    });

    test('parses cup of dry oats as grams', () {
      final portions = FoodQueryHints.parseVolumePortionsFromQuery(
        'Three scrambled eggs and a cup of raw oatmeal',
      );

      expect(portions.length, 1);
      expect(portions.first.name, contains('avena'));
      expect(portions.first.gramsG, 80);
    });

    test('reconcile fixes eggs plus oatmeal when AI drops oat macros', () {
      const query = 'Three scrambled eggs and a cup of raw oatmeal';
      const ai = FoodNutritionEstimate(
        name: 'Three scrambled eggs and a cup of raw oatmeal',
        caloriesKcal: 233,
        proteinG: 19.5,
        carbsG: 1.7,
        fatG: 16.5,
        fiberG: 0,
        referenceAmount: 210,
        ingredients: ['huevos', 'avena cruda'],
        ingredientPortions: [
          FoodIngredientPortion(name: 'huevos', gramsG: 150),
          FoodIngredientPortion(name: 'avena cruda', gramsG: 60),
        ],
      );

      final fixed = FoodQueryHints.reconcile(query, ai);

      expect(fixed.caloriesKcal, greaterThan(400));
      expect(fixed.carbsG, greaterThan(35));
      expect(fixed.fiberG, greaterThan(4));
      expect(fixed.ingredientPortions.length, greaterThanOrEqualTo(2));
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

    test('parseTotalPlateGrams treats weight as full dish not addon', () {
      const query = '315g de tacos al pastor con costra de queso';

      final total = FoodQueryHints.parseTotalPlateGrams(query);
      expect(total, isNotNull);
      expect(total!.grams, 315);
      expect(total.name.toLowerCase(), contains('tacos al pastor'));

      final portions = FoodQueryHints.parseIngredientGramsFromQuery(query);
      expect(portions.length, 2);
      expect(
        portions.any((p) => p.name.contains('tacos al pastor') && p.gramsG > 250),
        isTrue,
      );
      expect(
        portions.any((p) => p.name.contains('costra de queso') && p.gramsG < 60),
        isTrue,
      );
      expect(portions.fold<double>(0, (sum, p) => sum + p.gramsG), closeTo(315, 0.5));
    });

    test('reconcile fixes tacos al pastor when AI assigns all grams to cheese', () {
      const query = '315g de tacos al pastor con costra de queso';
      const ai = FoodNutritionEstimate(
        name: 'Tacos al pastor con costra de queso',
        caloriesKcal: 1103,
        proteinG: 79,
        carbsG: 6,
        fatG: 89,
        referenceAmount: 315,
        ingredients: ['queso'],
        ingredientPortions: [
          FoodIngredientPortion(name: 'queso', gramsG: 315),
        ],
      );

      final fixed = FoodQueryHints.reconcile(query, ai);

      expect(fixed.ingredientPortions.length, greaterThanOrEqualTo(2));
      expect(
        fixed.ingredientPortions.any((p) => p.name.toLowerCase().contains('taco')),
        isTrue,
      );
      expect(fixed.caloriesKcal, lessThan(950));
      expect(fixed.caloriesKcal, greaterThan(650));
      expect(fixed.referenceAmount, closeTo(315, 1));
    });

    test('anchoredEstimateForQuery estimates composite plate from total grams', () {
      const query = '315g de tacos al pastor con costra de queso';
      const ai = FoodNutritionEstimate(
        name: 'Tacos al pastor',
        caloriesKcal: 0,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
      );

      final anchored = FoodQueryHints.anchoredEstimateForQuery(query, ai);

      expect(anchored, isNotNull);
      expect(anchored!.caloriesKcal, greaterThan(650));
      expect(anchored.caloriesKcal, lessThan(950));
      expect(anchored.ingredientPortions.length, 2);
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

    test('reconcile respects explicit grams for peanut butter despite accent mismatch', () {
      const query = '14g de mantequilla de mani';
      const ai = FoodNutritionEstimate(
        name: 'Mantequilla de maní',
        caloriesKcal: 180,
        proteinG: 7,
        carbsG: 6,
        fatG: 15,
        referenceAmount: 28,
        ingredients: ['mantequilla de maní'],
        ingredientPortions: [
          FoodIngredientPortion(name: 'mantequilla de maní', gramsG: 28),
        ],
      );

      final fixed = FoodQueryHints.reconcile(query, ai);

      expect(fixed.referenceAmount, closeTo(14, 0.5));
      expect(fixed.ingredientPortions.length, 1);
      expect(fixed.ingredientPortions.first.gramsG, closeTo(14, 0.5));
      expect(fixed.caloriesKcal, lessThan(120));
    });

    test('reconcile scales large chicken breast from size adjective', () {
      const query = 'Gran pechuga de pollo';
      const ai = FoodNutritionEstimate(
        name: 'Pechuga de pollo',
        caloriesKcal: 165,
        proteinG: 31,
        carbsG: 0,
        fatG: 3.6,
        referenceAmount: 100,
        ingredients: ['pechuga de pollo'],
        ingredientPortions: [
          FoodIngredientPortion(name: 'pechuga de pollo', gramsG: 100),
        ],
      );

      final fixed = FoodQueryHints.reconcile(query, ai);

      expect(fixed.referenceAmount, greaterThan(170));
      expect(fixed.referenceAmount, lessThan(230));
      expect(fixed.caloriesKcal, greaterThan(250));
    });

    test('parsePortionSizeMultiplier detects large and small adjectives', () {
      expect(FoodQueryHints.parsePortionSizeMultiplier('Gran pechuga de pollo'), 1.75);
      expect(FoodQueryHints.parsePortionSizeMultiplier('pechuga pequeña'), 0.65);
      expect(FoodQueryHints.parsePortionSizeMultiplier('pechuga de pollo'), 1.0);
    });

    test('reconcile does not double-apply size modifier when AI already sized portion', () {
      const query = 'big chicken breast';
      const ai = FoodNutritionEstimate(
        name: 'Big chicken breast',
        caloriesKcal: 363,
        proteinG: 68,
        carbsG: 0,
        fatG: 7.9,
        referenceAmount: 220,
        ingredients: ['chicken breast'],
        ingredientPortions: [
          FoodIngredientPortion(name: 'chicken breast', gramsG: 220),
        ],
      );

      final fixed = FoodQueryHints.reconcile(query, ai);

      expect(fixed.referenceAmount, closeTo(220, 1));
      expect(fixed.referenceAmount, lessThan(280));
    });

    test('reconcile applies size modifier when AI returns generic 100g', () {
      const query = 'big chicken breast';
      const ai = FoodNutritionEstimate(
        name: 'Chicken breast',
        caloriesKcal: 165,
        proteinG: 31,
        carbsG: 0,
        fatG: 3.6,
        referenceAmount: 100,
        ingredients: ['chicken breast'],
        ingredientPortions: [
          FoodIngredientPortion(name: 'chicken breast', gramsG: 100),
        ],
      );

      final fixed = FoodQueryHints.reconcile(query, ai);

      expect(fixed.referenceAmount, greaterThan(170));
      expect(fixed.referenceAmount, lessThan(230));
    });
  });
}
