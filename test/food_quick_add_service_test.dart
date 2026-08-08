import 'package:fitforge/models/catalog_food.dart';
import 'package:fitforge/models/food_entry.dart';
import 'package:fitforge/services/catalog_food_service.dart';
import 'package:fitforge/services/food_quick_add_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const strawberries = CatalogFood(
    id: 'cf_fresas',
    nameEs: 'Fresas',
    nameEn: 'Strawberries',
    region: 'latam',
    category: 'fruta',
    caloriesKcalPer100: 32,
    proteinGPer100: 0.7,
    carbsGPer100: 7.7,
    fatGPer100: 0.3,
    fiberGPer100: 2,
    amountUnit: 'g',
    servingAmount: 150,
    servingLabelEs: '1 taza (150 g)',
    servingLabelEn: '1 cup (150 g)',
  );
  const eggWhites = CatalogFood(
    id: 'cf_claras_huevo',
    nameEs: 'Claras de huevo',
    nameEn: 'Egg whites',
    region: 'latam',
    category: 'proteina',
    caloriesKcalPer100: 52,
    proteinGPer100: 10.9,
    carbsGPer100: 0.7,
    fatGPer100: 0.2,
    fiberGPer100: 0,
    amountUnit: 'g',
    servingAmount: 100,
    servingLabelEs: '100 g',
    servingLabelEn: '100 g',
  );

  test('uses catalog values for a weighted single food without calling AI',
      () async {
    var aiCalls = 0;
    final service = FoodQuickAddService(
      catalog: const _FakeCatalog([strawberries]),
      aiEstimate: ({
        required query,
        profile,
        catalogFacts,
      }) async {
        aiCalls++;
        return null;
      },
    );

    final result = await service.estimate(query: '77g de fresas frescas');

    expect(result, isNotNull);
    expect(result!.caloriesKcal, 25);
    expect(result.proteinG, closeTo(0.54, 0.01));
    expect(result.referenceAmount, 77);
    expect(aiCalls, 0);
  });

  test('sums fully matched ingredients deterministically', () async {
    var aiCalls = 0;
    final service = FoodQuickAddService(
      catalog: const _FakeCatalog([strawberries, eggWhites]),
      aiEstimate: ({
        required query,
        profile,
        catalogFacts,
      }) async {
        aiCalls++;
        return null;
      },
    );

    final result = await service.estimate(
      query: '100g de fresas y 50g de claras de huevo',
    );

    expect(result, isNotNull);
    expect(result!.caloriesKcal, 58);
    expect(result.proteinG, closeTo(6.15, 0.01));
    expect(result.referenceAmount, 150);
    expect(result.ingredientPortions, hasLength(2));
    expect(aiCalls, 0);
  });

  test('passes verified catalog facts to AI for a partial match', () async {
    String? receivedFacts;
    final service = FoodQuickAddService(
      catalog: const _FakeCatalog([strawberries]),
      aiEstimate: ({
        required query,
        profile,
        catalogFacts,
      }) async {
        receivedFacts = catalogFacts;
        return const FoodNutritionEstimate(
          name: 'Fresas con granola',
          caloriesKcal: 160,
          proteinG: 4,
          carbsG: 28,
          fatG: 4,
          referenceAmount: 107,
          ingredientPortions: [
            FoodIngredientPortion(name: 'fresas', gramsG: 77),
            FoodIngredientPortion(name: 'granola', gramsG: 30),
          ],
        );
      },
    );

    final result = await service.estimate(
      query: '77g fresas y 30g granola desconocida',
    );

    expect(result, isNotNull);
    expect(receivedFacts, contains('77 g = 25 kcal'));
  });

  test('falls back to AI when catalog has no confident match', () async {
    var aiCalls = 0;
    final service = FoodQuickAddService(
      catalog: const _FakeCatalog([]),
      aiEstimate: ({
        required query,
        profile,
        catalogFacts,
      }) async {
        aiCalls++;
        return const FoodNutritionEstimate(
          name: 'Plato desconocido',
          caloriesKcal: 200,
          proteinG: 10,
          carbsG: 25,
          fatG: 7,
          referenceAmount: 150,
        );
      },
    );

    final result = await service.estimate(query: 'plato desconocido');

    expect(result, isNotNull);
    expect(aiCalls, 1);
  });
}

class _FakeCatalog implements CatalogFoodLookup {
  const _FakeCatalog(this.foods);

  final List<CatalogFood> foods;

  @override
  Future<List<CatalogFood>> search(String query, {int limit = 30}) async {
    final normalized = query.toLowerCase();
    return foods
        .where((food) {
          final es = food.nameEs.toLowerCase();
          final en = food.nameEn.toLowerCase();
          return normalized.contains(es) ||
              es.contains(normalized) ||
              normalized.contains(en) ||
              en.contains(normalized) ||
              (normalized.contains('fresa') && es.contains('fresa')) ||
              (normalized.contains('clara') && es.contains('clara'));
        })
        .take(limit)
        .toList();
  }
}
