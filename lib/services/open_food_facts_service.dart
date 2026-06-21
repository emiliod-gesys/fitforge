import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food_entry.dart';

/// Consulta productos por código de barras (Open Food Facts).
class OpenFoodFactsService {
  Future<FoodNutritionEstimate?> lookupBarcode(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return null;

    final uri = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$code.json');
    final response = await http.get(
      uri,
      headers: const {'User-Agent': 'FitForge/1.0 (nutrition tracking)'},
    );
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['status'] != 1) return null;

    final product = body['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
    final name = (product['product_name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;

    final brand = (product['brands'] as String?)?.trim();
    final unit = _resolveUnit(product);
    final kcalPer100 = _num(nutriments['energy-kcal_100g']) ??
        (_num(nutriments['energy_100g']) != null ? _num(nutriments['energy_100g'])! / 4.184 : null) ??
        0.0;

    final ingredients = (product['ingredients_text'] as String?)
            ?.split(RegExp(r'[,;]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .take(8)
            .toList() ??
        const <String>[];

    return FoodNutritionEstimate(
      name: name,
      brand: brand?.isEmpty == true ? null : brand,
      caloriesKcal: kcalPer100.round().clamp(0, 9999),
      proteinG: _num(nutriments['proteins_100g']) ?? 0,
      carbsG: _num(nutriments['carbohydrates_100g']) ?? 0,
      fatG: _num(nutriments['fat_100g']) ?? 0,
      fiberG: _num(nutriments['fiber_100g']) ?? 0,
      servingDescription: '100 $unit',
      ingredients: ingredients,
      referenceAmount: 100,
      amountUnit: unit,
    );
  }

  String _resolveUnit(Map<String, dynamic> product) {
    final quantityUnit = (product['product_quantity_unit'] as String?)?.toLowerCase();
    if (quantityUnit == 'ml' || quantityUnit == 'l') return 'ml';
    return 'g';
  }

  double? _num(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }
}
