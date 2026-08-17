import 'package:fitforge/models/food_entry.dart';
import 'package:fitforge/services/open_food_facts_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpenFoodFactsService', () {
    test('barcode source round-trips for food_entries', () {
      expect(FoodEntrySource.barcode.toJson(), 'barcode');
      expect(FoodEntrySource.fromJson('barcode'), FoodEntrySource.barcode);
    });

    test('uses labeled serving macros instead of 100 g', () {
      final estimate = OpenFoodFactsService().estimateFromProduct({
        'product_name': 'Greek Yogurt',
        'brands': 'Fage',
        'serving_size': '150 g',
        'serving_quantity': 150,
        'nutriments': {
          'energy-kcal_100g': 97,
          'energy-kcal_serving': 146,
          'proteins_100g': 9,
          'proteins_serving': 13.5,
          'carbohydrates_100g': 3,
          'carbohydrates_serving': 4.5,
          'fat_100g': 5,
          'fat_serving': 7.5,
          'fiber_100g': 0,
        },
      });

      expect(estimate, isNotNull);
      expect(estimate!.referenceAmount, 150);
      expect(estimate.caloriesKcal, 146);
      expect(estimate.proteinG, 13.5);
      expect(estimate.servingDescription, '150 g');
    });

    test('scales 100 g macros to serving size when serving nutrients are missing', () {
      final estimate = OpenFoodFactsService().estimateFromProduct({
        'product_name': 'Oat Bar',
        'serving_size': '1 bar (40 g)',
        'nutriments': {
          'energy-kcal_100g': 400,
          'proteins_100g': 10,
          'carbohydrates_100g': 50,
          'fat_100g': 12,
          'fiber_100g': 8,
        },
      });

      expect(estimate, isNotNull);
      expect(estimate!.referenceAmount, 40);
      expect(estimate.caloriesKcal, 160);
      expect(estimate.proteinG, 4);
      expect(estimate.carbsG, 20);
      expect(estimate.fatG, closeTo(4.8, 0.01));
    });

    test('falls back to 100 g when the product has no serving', () {
      final estimate = OpenFoodFactsService().estimateFromProduct({
        'product_name': 'Rice',
        'nutriments': {
          'energy-kcal_100g': 130,
          'proteins_100g': 2.7,
          'carbohydrates_100g': 28,
          'fat_100g': 0.3,
        },
      });

      expect(estimate, isNotNull);
      expect(estimate!.referenceAmount, 100);
      expect(estimate.caloriesKcal, 130);
      expect(estimate.servingDescription, '100 g');
    });

    test('lookupBarcode returns macros for a known product', () async {
      final estimate = await OpenFoodFactsService().lookupBarcode('3017620422003');
      expect(estimate, isNotNull);
      expect(estimate!.name.toLowerCase(), contains('nutella'));
      expect(estimate.caloriesKcal, greaterThan(0));
      expect(estimate.referenceAmount, greaterThan(0));
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('lookupBarcode returns null for unknown code', () async {
      final estimate = await OpenFoodFactsService().lookupBarcode('0000000000000');
      expect(estimate, isNull);
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
