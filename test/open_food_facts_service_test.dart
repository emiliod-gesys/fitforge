import 'package:fitforge/models/food_entry.dart';
import 'package:fitforge/services/open_food_facts_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpenFoodFactsService', () {
    test('barcode source round-trips for food_entries', () {
      expect(FoodEntrySource.barcode.toJson(), 'barcode');
      expect(FoodEntrySource.fromJson('barcode'), FoodEntrySource.barcode);
    });

    test('lookupBarcode returns macros for a known product', () async {
      final estimate = await OpenFoodFactsService().lookupBarcode('3017620422003');
      expect(estimate, isNotNull);
      expect(estimate!.name.toLowerCase(), contains('nutella'));
      expect(estimate.caloriesKcal, greaterThan(0));
      expect(estimate.referenceAmount, 100);
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('lookupBarcode returns null for unknown code', () async {
      final estimate = await OpenFoodFactsService().lookupBarcode('0000000000000');
      expect(estimate, isNull);
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
