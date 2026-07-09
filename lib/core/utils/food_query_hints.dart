import '../../models/food_entry.dart';
import 'food_serving_parser.dart';

/// Extrae pistas numéricas del texto del usuario para corregir estimaciones de IA.
abstract final class FoodQueryHints {
  static const _wordCounts = {
    'un': 1,
    'una': 1,
    'uno': 1,
    'dos': 2,
    'tres': 3,
    'cuatro': 4,
    'cinco': 5,
    'seis': 6,
  };

  /// Huevo grande estrellado sin aceite añadido.
  static const eggKcal = 78;
  static const eggProteinG = 6.3;
  static const eggFatG = 5.3;
  static const eggCarbsG = 0.4;

  static int? _parseCount(String token) {
    final t = token.trim().toLowerCase();
    if (_wordCounts.containsKey(t)) return _wordCounts[t];
    return int.tryParse(t);
  }

  static int? _countBefore(String text) {
    final match = RegExp(
      r'(\d+|un|una|uno|dos|tres|cuatro|cinco|seis)\s+[a-záéíóúñ]+',
      caseSensitive: false,
    ).allMatches(text).lastOrNull;
    if (match == null) return null;
    return _parseCount(match.group(1)!);
  }

  /// Suma kcal de ítems con valor explícito (ej. "56 kcal cada una").
  static int labeledKcalTotal(String query) {
    final lower = query.toLowerCase();
    final pattern = RegExp(
      r'(\d+)\s*(?:kcal|cal)\s*(?:cada(?:\s+(?:una|uno))?|c/u|each|por(?:\s+(?:unidad|pieza|tortilla))?)',
      caseSensitive: false,
    );

    var total = 0;
    for (final match in pattern.allMatches(lower)) {
      final kcalEach = int.tryParse(match.group(1)!) ?? 0;
      final before = lower.substring(0, match.start);
      final count = _countBefore(before) ?? 1;
      total += kcalEach * count;
    }
    return total;
  }

  static int eggCount(String query) {
    final lower = query.toLowerCase();
    final match = RegExp(
      r'(\d+|un|una|uno|dos|tres|cuatro|cinco|seis)\s+huevos?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (match == null) return 0;
    return _parseCount(match.group(1)!) ?? 0;
  }

  /// Macros típicos por tortilla pequeña ~56 kcal (si no hay más datos).
  static ({int kcal, double p, double f, double c}) tortillaMacros(int count, int kcalEach) {
    final kcal = count * kcalEach;
    final c = kcal * 0.55 / 4;
    final f = kcal * 0.28 / 9;
    final p = kcal * 0.17 / 4;
    return (kcal: kcal, p: p, f: f, c: c);
  }

  /// Extrae gramos del texto del usuario (ej. "100g", "100 gramos").
  static double? parseGrams(String query) {
    final match = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*g(?:ramos?)?\b',
      caseSensitive: false,
    ).firstMatch(query);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  static const _anchorPer100g = {
    'manzana verde': (kcal: 52, protein: 0.3, carbs: 14.0, fat: 0.2, fiber: 2.4),
    'manzana': (kcal: 52, protein: 0.3, carbs: 14.0, fat: 0.2, fiber: 2.4),
    'apple': (kcal: 52, protein: 0.3, carbs: 14.0, fat: 0.2, fiber: 2.4),
    'plátano': (kcal: 89, protein: 1.1, carbs: 23.0, fat: 0.3, fiber: 2.6),
    'platano': (kcal: 89, protein: 1.1, carbs: 23.0, fat: 0.3, fiber: 2.6),
    'banana': (kcal: 89, protein: 1.1, carbs: 23.0, fat: 0.3, fiber: 2.6),
    // Pasta / fideos cocidos sin salsa (~USDA spaghetti cooked).
    'espagueti cocido': (kcal: 131, protein: 5.0, carbs: 25.0, fat: 1.1, fiber: 1.8),
    'spaghetti cooked': (kcal: 131, protein: 5.0, carbs: 25.0, fat: 1.1, fiber: 1.8),
    'espagueti': (kcal: 131, protein: 5.0, carbs: 25.0, fat: 1.1, fiber: 1.8),
    'spaguetti': (kcal: 131, protein: 5.0, carbs: 25.0, fat: 1.1, fiber: 1.8),
    'spaghetti': (kcal: 131, protein: 5.0, carbs: 25.0, fat: 1.1, fiber: 1.8),
    'pasta cocida': (kcal: 131, protein: 5.0, carbs: 25.0, fat: 1.1, fiber: 1.8),
    'pasta': (kcal: 131, protein: 5.0, carbs: 25.0, fat: 1.1, fiber: 1.8),
    'fideos': (kcal: 131, protein: 5.0, carbs: 25.0, fat: 1.1, fiber: 1.8),
    'macarrones': (kcal: 131, protein: 5.0, carbs: 25.0, fat: 1.1, fiber: 1.8),
    // Arroz blanco cocido.
    'arroz blanco cocido': (kcal: 130, protein: 2.7, carbs: 28.0, fat: 0.3, fiber: 0.4),
    'arroz cocido': (kcal: 130, protein: 2.7, carbs: 28.0, fat: 0.3, fiber: 0.4),
    'arroz blanco': (kcal: 130, protein: 2.7, carbs: 28.0, fat: 0.3, fiber: 0.4),
    'white rice': (kcal: 130, protein: 2.7, carbs: 28.0, fat: 0.3, fiber: 0.4),
  };

  static const _lowCalorieProduce = [
    'lechuga',
    'pepino',
    'apio',
    'calabac',
    'zucchini',
    'espinaca',
    'tomate cherry',
  ];

  static bool _isLowCalorieProduce(String query) {
    final lower = query.toLowerCase();
    return _lowCalorieProduce.any(lower.contains);
  }

  static FoodNutritionEstimate _scaleFromPer100g(FoodNutritionEstimate ai, double targetGrams) {
    final factor = targetGrams / 100;
    return FoodNutritionEstimate(
      name: ai.name,
      brand: ai.brand,
      caloriesKcal: (ai.caloriesKcal * factor).round(),
      proteinG: double.parse((ai.proteinG * factor).toStringAsFixed(1)),
      carbsG: double.parse((ai.carbsG * factor).toStringAsFixed(1)),
      fatG: double.parse((ai.fatG * factor).toStringAsFixed(1)),
      fiberG: double.parse((ai.fiberG * factor).toStringAsFixed(1)),
      servingDescription: FoodServingParser.formatAmount(targetGrams, ai.amountUnit),
      ingredients: ai.ingredients,
      ingredientPortions: ai.ingredientPortions
          .map((portion) => portion.scaledBy(targetGrams / (ai.referenceAmount > 0 ? ai.referenceAmount : 100)))
          .toList(),
      referenceAmount: targetGrams,
      amountUnit: ai.amountUnit,
    );
  }

  /// Corrige cuando la IA devuelve macros por 100 g pero el peso total en reference_amount_g.
  static FoodNutritionEstimate fixPer100gConfusion(String query, FoodNutritionEstimate ai) {
    final userGrams = parseGrams(query);
    if (userGrams == null || userGrams < 30) return ai;

    if (ai.referenceAmount <= 120 && userGrams > ai.referenceAmount * 1.4) {
      return _scaleFromPer100g(ai, userGrams);
    }

    if ((ai.referenceAmount - userGrams).abs() <= userGrams * 0.1) {
      final kcalPerG = ai.caloriesKcal / ai.referenceAmount;
      if (kcalPerG < 0.9 &&
          ai.caloriesKcal <= 400 &&
          !_isLowCalorieProduce(query)) {
        return _scaleFromPer100g(ai, userGrams);
      }
    }

    return ai;
  }

  /// Aplica anclas por alimento o corrige confusión per-100g antes de otras reglas.
  static FoodNutritionEstimate correctGramBasedEstimate(String query, FoodNutritionEstimate ai) {
    final anchored = anchoredEstimateForQuery(query, ai);
    if (anchored != null) {
      if (ai.caloriesKcal <= 0) return anchored;
      final ratio = ai.caloriesKcal / anchored.caloriesKcal;
      if (ratio < 0.8 || ratio > 1.25) return anchored;
      if ((ai.referenceAmount - anchored.referenceAmount).abs() > 1) return anchored;
      return ai;
    }
    return fixPer100gConfusion(query, ai);
  }

  static FoodNutritionEstimate? anchoredEstimateForQuery(
    String query,
    FoodNutritionEstimate ai,
  ) {
    final grams = parseGrams(query);
    if (grams == null || grams <= 0) return null;

    final lower = query.toLowerCase();
    final sortedKeys = _anchorPer100g.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final token in sortedKeys) {
      if (!lower.contains(token)) continue;
      final anchor = _anchorPer100g[token]!;
      final factor = grams / 100;
      return FoodNutritionEstimate(
        name: ai.name,
        brand: ai.brand,
        caloriesKcal: (anchor.kcal * factor).round(),
        proteinG: double.parse((anchor.protein * factor).toStringAsFixed(1)),
        carbsG: double.parse((anchor.carbs * factor).toStringAsFixed(1)),
        fatG: double.parse((anchor.fat * factor).toStringAsFixed(1)),
        fiberG: double.parse((anchor.fiber * factor).toStringAsFixed(1)),
        servingDescription: FoodServingParser.formatAmount(grams, 'g'),
        ingredients: ai.ingredients,
        ingredientPortions: ai.ingredientPortions
            .map((portion) => portion.scaledBy(grams / (ai.referenceAmount > 0 ? ai.referenceAmount : 100)))
            .toList(),
        referenceAmount: grams,
        amountUnit: 'g',
      );
    }
    return null;
  }

  /// Ajusta la estimación de IA si el usuario dio calorías explícitas o cantidades claras.
  static FoodNutritionEstimate reconcile(String query, FoodNutritionEstimate ai) {
    final gramCorrected = correctGramBasedEstimate(query, ai);
    final labeledKcal = labeledKcalTotal(query);
    final eggs = eggCount(query);

    if (labeledKcal == 0 && eggs == 0) {
      return gramCorrected;
    }

    var kcal = labeledKcal + eggs * eggKcal;
    var protein = eggs * eggProteinG;
    var fat = eggs * eggFatG;
    var carbs = eggs * eggCarbsG;

    if (labeledKcal > 0) {
      final eachMatch = RegExp(r'(\d+)\s*(?:kcal|cal)\s*cada', caseSensitive: false).firstMatch(query);
      final kcalEach = eachMatch != null ? int.tryParse(eachMatch.group(1)!) ?? 56 : 56;
      final tortillaCount = _countBefore(
            query.toLowerCase().substring(0, eachMatch?.start ?? query.length),
          ) ??
          1;
      final t = tortillaMacros(tortillaCount, kcalEach);
      if (query.toLowerCase().contains('tortilla')) {
        protein += t.p;
        fat += t.f;
        carbs += t.c;
      } else {
        carbs += labeledKcal * 0.5 / 4;
        fat += labeledKcal * 0.3 / 9;
        protein += labeledKcal * 0.2 / 4;
      }
    }

    if (kcal <= 0) return gramCorrected;

    final floor = (kcal * 0.95).round();
    if (gramCorrected.caloriesKcal >= floor) return gramCorrected;

    return FoodNutritionEstimate(
      name: gramCorrected.name,
      brand: gramCorrected.brand,
      caloriesKcal: kcal.round(),
      proteinG: double.parse(protein.toStringAsFixed(1)),
      carbsG: double.parse(carbs.toStringAsFixed(1)),
      fatG: double.parse(fat.toStringAsFixed(1)),
      fiberG: gramCorrected.fiberG,
      servingDescription: gramCorrected.servingDescription,
      ingredients: gramCorrected.ingredients,
      ingredientPortions: gramCorrected.ingredientPortions,
      referenceAmount: gramCorrected.referenceAmount > 0 ? gramCorrected.referenceAmount : 180,
      amountUnit: gramCorrected.amountUnit,
    );
  }
}

extension _IterableLastOrNull<E> on Iterable<E> {
  E? get lastOrNull => isEmpty ? null : last;
}
