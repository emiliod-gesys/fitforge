import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/utils/food_serving_parser.dart';
import '../models/food_entry.dart';

/// Consulta productos por código de barras y texto (Open Food Facts).
class OpenFoodFactsService {
  static const _headers = {'User-Agent': 'FORGEN/1.0 (nutrition tracking)'};
  static const _minServing = 1.0;
  static const _maxServing = 2000.0;

  Future<FoodNutritionEstimate?> lookupBarcode(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return null;

    final uri = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$code.json');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['status'] != 1) return null;

    final product = body['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    return estimateFromProduct(product);
  }

  /// Búsqueda de productos empacados por texto, ordenada por popularidad
  /// (los productos más escaneados en la región aparecen primero).
  Future<List<FoodNutritionEstimate>> searchByText(String query, {int limit = 12}) async {
    final q = query.trim();
    if (q.length < 3) return const [];

    final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
      'search_terms': q,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '$limit',
      'sort_by': 'unique_scans_n',
      'lc': 'es',
      'fields':
          'product_name,product_name_es,brands,nutriments,product_quantity_unit,ingredients_text,serving_size,serving_quantity',
    });

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final products = body['products'] as List? ?? const [];
      return products
          .whereType<Map>()
          .map((p) => estimateFromProduct(Map<String, dynamic>.from(p)))
          .whereType<FoodNutritionEstimate>()
          .where((e) => e.caloriesKcal > 0)
          .toList();
    } catch (_) {
      // Sin conexión o servicio caído: la búsqueda degrada sin romperse.
      return const [];
    }
  }

  FoodNutritionEstimate? estimateFromProduct(Map<String, dynamic> product) {
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
    final name = ((product['product_name_es'] as String?)?.trim().isNotEmpty == true
            ? product['product_name_es'] as String
            : product['product_name'] as String?)
        ?.trim();
    if (name == null || name.isEmpty) return null;

    final brand = (product['brands'] as String?)?.trim();
    final unit = _resolveUnit(product);
    final per100 = _macrosPer100(nutriments);
    final perServing = _macrosPerServing(nutriments);
    final servingAmount = _servingAmount(
      product,
      kcalPer100: per100.kcal,
      kcalServing: perServing.kcal,
    );

    final ingredients = (product['ingredients_text'] as String?)
            ?.split(RegExp(r'[,;]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .take(8)
            .toList() ??
        const <String>[];

    final useServing = servingAmount != null;
    final macros = useServing
        ? _macrosForServing(
            servingAmount: servingAmount,
            per100: per100,
            perServing: perServing,
          )
        : per100;
    if (macros.kcal <= 0 && macros.protein <= 0 && macros.carbs <= 0 && macros.fat <= 0) {
      return null;
    }

    final reference = useServing ? servingAmount : 100.0;
    final servingSize = (product['serving_size'] as String?)?.trim();
    final servingDescription = useServing
        ? (servingSize != null && servingSize.isNotEmpty
            ? servingSize
            : FoodServingParser.formatAmount(reference, unit))
        : FoodServingParser.formatAmount(100, unit);

    return FoodNutritionEstimate(
      name: name,
      brand: brand?.isEmpty == true ? null : brand,
      caloriesKcal: macros.kcal.round().clamp(0, 9999),
      proteinG: macros.protein,
      carbsG: macros.carbs,
      fatG: macros.fat,
      fiberG: macros.fiber,
      servingDescription: servingDescription,
      ingredients: ingredients,
      referenceAmount: reference,
      amountUnit: unit,
    );
  }

  ({double kcal, double protein, double carbs, double fat, double fiber}) _macrosPer100(
    Map<String, dynamic> nutriments,
  ) {
    final kcal = _num(nutriments['energy-kcal_100g']) ??
        (_num(nutriments['energy_100g']) != null ? _num(nutriments['energy_100g'])! / 4.184 : null) ??
        0.0;
    return (
      kcal: kcal,
      protein: _num(nutriments['proteins_100g']) ?? 0,
      carbs: _num(nutriments['carbohydrates_100g']) ?? 0,
      fat: _num(nutriments['fat_100g']) ?? 0,
      fiber: _num(nutriments['fiber_100g']) ?? 0,
    );
  }

  ({double? kcal, double? protein, double? carbs, double? fat, double? fiber}) _macrosPerServing(
    Map<String, dynamic> nutriments,
  ) {
    final kcal = _num(nutriments['energy-kcal_serving']) ??
        (_num(nutriments['energy_serving']) != null ? _num(nutriments['energy_serving'])! / 4.184 : null);
    return (
      kcal: kcal,
      protein: _num(nutriments['proteins_serving']),
      carbs: _num(nutriments['carbohydrates_serving']),
      fat: _num(nutriments['fat_serving']),
      fiber: _num(nutriments['fiber_serving']),
    );
  }

  ({double kcal, double protein, double carbs, double fat, double fiber}) _macrosForServing({
    required double servingAmount,
    required ({double kcal, double protein, double carbs, double fat, double fiber}) per100,
    required ({double? kcal, double? protein, double? carbs, double? fat, double? fiber}) perServing,
  }) {
    final factor = servingAmount / 100.0;
    return (
      kcal: (perServing.kcal != null && perServing.kcal! > 0) ? perServing.kcal! : per100.kcal * factor,
      protein: perServing.protein ?? per100.protein * factor,
      carbs: perServing.carbs ?? per100.carbs * factor,
      fat: perServing.fat ?? per100.fat * factor,
      fiber: perServing.fiber ?? per100.fiber * factor,
    );
  }

  double? _servingAmount(
    Map<String, dynamic> product, {
    required double kcalPer100,
    required double? kcalServing,
  }) {
    final fromQuantity = _num(product['serving_quantity']);
    if (_isValidServing(fromQuantity)) return fromQuantity;

    final fromSize = FoodServingParser.amountFromDescription(product['serving_size'] as String?);
    if (_isValidServing(fromSize)) return fromSize;

    if (kcalServing != null && kcalServing > 0 && kcalPer100 > 0) {
      final inferred = kcalServing / kcalPer100 * 100;
      if (_isValidServing(inferred) && (inferred - 100).abs() > 1) return inferred;
    }
    return null;
  }

  bool _isValidServing(double? amount) {
    if (amount == null) return false;
    return amount >= _minServing && amount <= _maxServing;
  }

  String _resolveUnit(Map<String, dynamic> product) {
    final servingUnit = FoodServingParser.unitFromDescription(product['serving_size'] as String?);
    if (servingUnit == 'ml') return 'ml';
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
