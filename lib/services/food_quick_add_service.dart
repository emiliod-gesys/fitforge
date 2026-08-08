import '../core/utils/food_estimate_validator.dart';
import '../core/utils/food_query_hints.dart';
import '../models/catalog_food.dart';
import '../models/food_entry.dart';
import '../models/profile.dart';
import 'catalog_food_service.dart';

typedef FoodAiEstimator = Future<FoodNutritionEstimate?> Function({
  required String query,
  UserProfile? profile,
  String? catalogFacts,
});

/// Resuelve Quick Add con datos de catálogo antes de delegar lo ambiguo a IA.
class FoodQuickAddService {
  const FoodQuickAddService({
    required CatalogFoodLookup catalog,
    required FoodAiEstimator aiEstimate,
  })  : _catalog = catalog,
        _aiEstimate = aiEstimate;

  final CatalogFoodLookup _catalog;
  final FoodAiEstimator _aiEstimate;

  Future<FoodNutritionEstimate?> estimate({
    required String query,
    UserProfile? profile,
  }) async {
    final languageCode = profile?.preferredLanguage == 'en' ? 'en' : 'es';
    final requested = _requestedPortions(query);
    final resolved = <_ResolvedCatalogPortion>[];

    for (final portion in requested) {
      final food = await _findConfidentMatch(portion.name);
      if (food != null) {
        resolved.add(
          _ResolvedCatalogPortion(food: food, grams: portion.gramsG),
        );
      }
    }

    if (requested.isNotEmpty && resolved.length == requested.length) {
      return _sumResolved(resolved, languageCode, query);
    }

    // Sin gramos explícitos, un match inequívoco puede usar la porción cultural.
    if (requested.isEmpty) {
      final food = await _findConfidentMatch(query);
      if (food != null) return food.toEstimate(languageCode);
    }

    final aiEstimate = await _aiEstimate(
      query: query,
      profile: profile,
      catalogFacts:
          resolved.isEmpty ? null : _catalogFacts(resolved, languageCode),
    );
    if (aiEstimate == null) return null;
    return FoodEstimateValidator.validateAndCorrect(aiEstimate);
  }

  List<FoodIngredientPortion> _requestedPortions(String query) {
    final parsed = FoodQueryHints.parseIngredientGramsFromQuery(query);
    if (parsed.isNotEmpty) return parsed;

    final grams = FoodQueryHints.parseGrams(query);
    if (grams == null || grams <= 0) return const [];

    final name = query
        .replaceFirst(
          RegExp(
            r'\d+(?:[.,]\d+)?\s*g(?:ramos?)?\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(RegExp(r'^\s*(?:de|del)\s+', caseSensitive: false), '')
        .trim();
    if (name.isEmpty) return const [];
    return [FoodIngredientPortion(name: name, gramsG: grams)];
  }

  Future<CatalogFood?> _findConfidentMatch(String rawName) async {
    final normalized = _normalize(rawName);
    if (normalized.isEmpty) return null;

    var results = await _catalog.search(rawName, limit: 8);
    if (results.isEmpty) {
      final simplified = _simplifySearch(rawName);
      if (simplified != normalized) {
        results = await _catalog.search(simplified, limit: 8);
      }
    }
    if (results.isEmpty) return null;

    CatalogFood? best;
    var bestScore = 0.0;
    var secondScore = 0.0;
    for (final food in results) {
      final score = _matchScore(normalized, food);
      if (score > bestScore) {
        secondScore = bestScore;
        bestScore = score;
        best = food;
      } else if (score > secondScore) {
        secondScore = score;
      }
    }

    // Exige coincidencia clara y evita elegir entre resultados casi empatados.
    if (bestScore < 0.72 ||
        (secondScore > 0 && bestScore - secondScore < 0.08)) {
      return null;
    }
    return best;
  }

  static double _matchScore(String query, CatalogFood food) {
    final candidates = [_normalize(food.nameEs), _normalize(food.nameEn)]
        .where((name) => name.isNotEmpty);
    var best = 0.0;
    for (final candidate in candidates) {
      if (query == candidate) return 1;
      if (_containsPhrase(query, candidate) ||
          _containsPhrase(candidate, query)) {
        best = best < 0.94 ? 0.94 : best;
        continue;
      }
      final queryWords = _meaningfulWords(query);
      final candidateWords = _meaningfulWords(candidate);
      if (candidateWords.isEmpty) continue;
      final overlap = candidateWords.where(queryWords.contains).length;
      final score = overlap / candidateWords.length;
      if (score > best) best = score;
    }
    return best;
  }

  static FoodNutritionEstimate _sumResolved(
    List<_ResolvedCatalogPortion> portions,
    String languageCode,
    String query,
  ) {
    var calories = 0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    var fiber = 0.0;
    var totalGrams = 0.0;
    final ingredients = <String>[];
    final ingredientPortions = <FoodIngredientPortion>[];

    for (final resolved in portions) {
      final estimate = resolved.food.toEstimateForAmount(
        languageCode,
        resolved.grams,
      );
      calories += estimate.caloriesKcal;
      protein += estimate.proteinG;
      carbs += estimate.carbsG;
      fat += estimate.fatG;
      fiber += estimate.fiberG;
      totalGrams += resolved.grams;
      final name = resolved.food.localizedName(languageCode);
      ingredients.add(name);
      ingredientPortions.add(
        FoodIngredientPortion(name: name, gramsG: resolved.grams),
      );
    }

    return FoodNutritionEstimate(
      name: _displayName(query),
      caloriesKcal: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      fiberG: fiber,
      servingDescription: '${totalGrams.round()} g',
      ingredients: ingredients,
      ingredientPortions: ingredientPortions,
      referenceAmount: totalGrams,
      amountUnit: 'g',
    );
  }

  static String _catalogFacts(
    List<_ResolvedCatalogPortion> resolved,
    String languageCode,
  ) {
    return resolved.map((item) {
      final estimate = item.food.toEstimateForAmount(
        languageCode,
        item.grams,
      );
      return '- ${item.food.localizedName(languageCode)}: '
          '${item.grams.toStringAsFixed(0)} g = '
          '${estimate.caloriesKcal} kcal, '
          'P ${estimate.proteinG.toStringAsFixed(1)} g, '
          'C ${estimate.carbsG.toStringAsFixed(1)} g, '
          'G ${estimate.fatG.toStringAsFixed(1)} g, '
          'fibra ${estimate.fiberG.toStringAsFixed(1)} g';
    }).join('\n');
  }

  static String _displayName(String query) {
    final withoutAmount = query
        .replaceAll(
          RegExp(
            r'\d+(?:[.,]\d+)?\s*g(?:ramos?)?\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return withoutAmount.isEmpty ? query.trim() : withoutAmount;
  }

  static String _simplifySearch(String value) {
    final words = _meaningfulWords(_normalize(value));
    return words.join(' ');
  }

  static Set<String> _meaningfulWords(String value) {
    const ignored = {
      'de',
      'del',
      'la',
      'el',
      'los',
      'las',
      'un',
      'una',
      'crudo',
      'cruda',
      'crudos',
      'crudas',
      'cocido',
      'cocida',
      'cocidos',
      'cocidas',
      'fresco',
      'fresca',
      'frescos',
      'frescas',
      'sin',
      'aceite',
      'g',
      'gramos',
    };
    return value
        .split(' ')
        .where((word) => word.isNotEmpty && !ignored.contains(word))
        .toSet();
  }

  static bool _containsPhrase(String text, String phrase) {
    return RegExp('(^| )${RegExp.escape(phrase)}( |\$)').hasMatch(text);
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }
}

class _ResolvedCatalogPortion {
  const _ResolvedCatalogPortion({
    required this.food,
    required this.grams,
  });

  final CatalogFood food;
  final double grams;
}
