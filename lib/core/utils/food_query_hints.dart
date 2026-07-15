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

  /// Extrae gramos explícitos por ítem (ej. "300g espagueti", "pollo 150 g").
  static List<FoodIngredientPortion> parseIngredientGramsFromQuery(String query) {
    final portions = <FoodIngredientPortion>[];

    final forward = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*g(?:ramos?)?(?:\s+de)?\s+([^,+\n\d]+?)(?=\s*(?:,|\s+y\s|\s+con\s|\s+e\s|\+\s|\d+\s*g|$))',
      caseSensitive: false,
    );
    for (final match in forward.allMatches(query)) {
      final grams = double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
      final name = _cleanIngredientName(match.group(2)!);
      if (grams <= 0 || name.isEmpty) continue;
      _upsertPortion(portions, name, grams);
    }

    final reverse = RegExp(
      r'([^,+\n\d]+?)\s+(\d+(?:[.,]\d+)?)\s*g(?:ramos?)?\b',
      caseSensitive: false,
    );
    for (final match in reverse.allMatches(query)) {
      final name = _cleanIngredientName(match.group(1)!);
      final grams = double.tryParse(match.group(2)!.replaceAll(',', '.')) ?? 0;
      if (grams <= 0 || name.isEmpty) continue;
      if (portions.any((p) => _namesOverlap(p.name, name))) continue;
      _upsertPortion(portions, name, grams);
    }

    return portions;
  }

  static String _cleanIngredientName(String raw) {
    var name = raw.trim().toLowerCase();
    name = name.replaceAll(RegExp(r'^(de|del|la|el|un|una|unos|unas)\s+'), '');
    name = name.replaceAll(RegExp(r'\s+(y|con|e|de)$'), '');
    return name.trim();
  }

  static bool _namesOverlap(String a, String b) {
    final x = a.toLowerCase().trim();
    final y = b.toLowerCase().trim();
    if (x.isEmpty || y.isEmpty) return false;
    return x == y || x.contains(y) || y.contains(x);
  }

  static void _upsertPortion(List<FoodIngredientPortion> portions, String name, double grams) {
    final index = portions.indexWhere((p) => _namesOverlap(p.name, name));
    if (index >= 0) {
      portions[index] = FoodIngredientPortion(name: name, gramsG: grams);
    } else {
      portions.add(FoodIngredientPortion(name: name, gramsG: grams));
    }
  }

  /// Completa o corrige gramos por ingrediente usando texto del usuario y totales.
  static FoodNutritionEstimate ensureIngredientPortions(String query, FoodNutritionEstimate ai) {
    final userPortions = parseIngredientGramsFromQuery(query);
    final portions = [...ai.ingredientPortions];

    for (final userPortion in userPortions) {
      final index = portions.indexWhere((p) => _namesOverlap(p.name, userPortion.name));
      if (index >= 0) {
        portions[index] = FoodIngredientPortion(
          name: portions[index].name,
          gramsG: userPortion.gramsG,
        );
      } else {
        portions.add(userPortion);
      }
    }

    final eggs = eggCount(query);
    if (eggs > 0) {
      _upsertPortion(portions, 'huevos', eggs * 50.0);
    }

    if (portions.isEmpty && ai.ingredients.length > 1) {
      final each = ai.referenceAmount > 0 ? ai.referenceAmount / ai.ingredients.length : 0.0;
      for (final ingredient in ai.ingredients) {
        portions.add(FoodIngredientPortion(name: ingredient, gramsG: each));
      }
    } else if (portions.isEmpty && ai.ingredients.length == 1) {
      final grams = parseGrams(query) ?? (ai.referenceAmount > 0 ? ai.referenceAmount : 100);
      portions.add(FoodIngredientPortion(name: ai.ingredients.first, gramsG: grams));
    }

    final totalGrams = parseGrams(query);
    if (portions.length == 1 && totalGrams != null && totalGrams > 0) {
      portions[0] = FoodIngredientPortion(name: portions[0].name, gramsG: totalGrams);
    }

    if (portions.isEmpty) return ai;

    var sumGrams = portions.fold<double>(0, (sum, p) => sum + p.gramsG);
    final targetTotal = totalGrams ?? (ai.referenceAmount > 0 ? ai.referenceAmount : sumGrams);

    if (userPortions.isNotEmpty && sumGrams > 0 && targetTotal > sumGrams * 1.05) {
      final unspecified = portions.where((p) {
        return !userPortions.any((u) => _namesOverlap(u.name, p.name));
      }).toList();
      if (unspecified.isEmpty && ai.ingredients.length > portions.length) {
        final remaining = targetTotal - sumGrams;
        final missing = ai.ingredients.where(
          (name) => !portions.any((p) => _namesOverlap(p.name, name)),
        );
        final each = remaining / missing.length;
        for (final name in missing) {
          portions.add(FoodIngredientPortion(name: name, gramsG: each));
        }
      } else if (unspecified.isNotEmpty) {
        final remaining = (targetTotal - sumGrams).clamp(0, double.infinity);
        final each = remaining / unspecified.length;
        for (var i = 0; i < portions.length; i++) {
          if (userPortions.any((u) => _namesOverlap(u.name, portions[i].name))) continue;
          portions[i] = FoodIngredientPortion(
            name: portions[i].name,
            gramsG: portions[i].gramsG + each,
          );
        }
      }
      sumGrams = portions.fold<double>(0, (sum, p) => sum + p.gramsG);
    }

    if ((sumGrams - targetTotal).abs() > 1 && sumGrams > 0 && userPortions.isEmpty) {
      final factor = targetTotal / sumGrams;
      for (var i = 0; i < portions.length; i++) {
        portions[i] = portions[i].scaledBy(factor);
      }
      sumGrams = targetTotal;
    }

    final referenceAmount = sumGrams > 0 ? sumGrams : ai.referenceAmount;

    return ai.copyWith(
      ingredientPortions: portions,
      ingredients: portions.map((p) => p.name).toList(),
      referenceAmount: referenceAmount,
      amountUnit: 'g',
      servingDescription: FoodServingParser.formatAmount(referenceAmount, 'g'),
    );
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
    'arroz': (kcal: 130, protein: 2.7, carbs: 28.0, fat: 0.3, fiber: 0.4),
    // Proteínas y platos comunes (valores típicos cocidos / listos para comer).
    'pechuga de pollo': (kcal: 165, protein: 31.0, carbs: 0.0, fat: 3.6, fiber: 0.0),
    'pollo a la plancha': (kcal: 165, protein: 31.0, carbs: 0.0, fat: 3.6, fiber: 0.0),
    'pollo asado': (kcal: 190, protein: 27.0, carbs: 0.0, fat: 8.0, fiber: 0.0),
    'pollo': (kcal: 165, protein: 31.0, carbs: 0.0, fat: 3.6, fiber: 0.0),
    'chicken breast': (kcal: 165, protein: 31.0, carbs: 0.0, fat: 3.6, fiber: 0.0),
    'chicken': (kcal: 165, protein: 31.0, carbs: 0.0, fat: 3.6, fiber: 0.0),
    'carne de res': (kcal: 250, protein: 26.0, carbs: 0.0, fat: 15.0, fiber: 0.0),
    'bistec': (kcal: 271, protein: 25.0, carbs: 0.0, fat: 19.0, fiber: 0.0),
    'res': (kcal: 250, protein: 26.0, carbs: 0.0, fat: 15.0, fiber: 0.0),
    'carne de cerdo': (kcal: 242, protein: 27.0, carbs: 0.0, fat: 14.0, fiber: 0.0),
    'cerdo': (kcal: 242, protein: 27.0, carbs: 0.0, fat: 14.0, fiber: 0.0),
    'salmón': (kcal: 208, protein: 20.0, carbs: 0.0, fat: 13.0, fiber: 0.0),
    'salmon': (kcal: 208, protein: 20.0, carbs: 0.0, fat: 13.0, fiber: 0.0),
    'atún': (kcal: 132, protein: 28.0, carbs: 0.0, fat: 1.0, fiber: 0.0),
    'atun': (kcal: 132, protein: 28.0, carbs: 0.0, fat: 1.0, fiber: 0.0),
    'huevos estrellados': (kcal: 196, protein: 13.6, carbs: 0.8, fat: 15.0, fiber: 0.0),
    'huevo estrellado': (kcal: 196, protein: 13.6, carbs: 0.8, fat: 15.0, fiber: 0.0),
    'huevos': (kcal: 155, protein: 13.0, carbs: 1.1, fat: 11.0, fiber: 0.0),
    'huevo': (kcal: 155, protein: 13.0, carbs: 1.1, fat: 11.0, fiber: 0.0),
    'egg': (kcal: 155, protein: 13.0, carbs: 1.1, fat: 11.0, fiber: 0.0),
    'tortilla de maíz': (kcal: 218, protein: 5.7, carbs: 44.0, fat: 2.9, fiber: 6.3),
    'tortilla de maiz': (kcal: 218, protein: 5.7, carbs: 44.0, fat: 2.9, fiber: 6.3),
    'tortilla de harina': (kcal: 312, protein: 8.0, carbs: 51.0, fat: 8.0, fiber: 3.0),
    'tortillas': (kcal: 218, protein: 5.7, carbs: 44.0, fat: 2.9, fiber: 6.3),
    'tortilla': (kcal: 218, protein: 5.7, carbs: 44.0, fat: 2.9, fiber: 6.3),
    'frijoles negros': (kcal: 132, protein: 8.9, carbs: 23.7, fat: 0.5, fiber: 8.7),
    'frijoles': (kcal: 127, protein: 8.7, carbs: 22.8, fat: 0.5, fiber: 7.6),
    'beans': (kcal: 127, protein: 8.7, carbs: 22.8, fat: 0.5, fiber: 7.6),
    'brócoli': (kcal: 35, protein: 2.4, carbs: 7.0, fat: 0.4, fiber: 2.6),
    'brocoli': (kcal: 35, protein: 2.4, carbs: 7.0, fat: 0.4, fiber: 2.6),
    'broccoli': (kcal: 35, protein: 2.4, carbs: 7.0, fat: 0.4, fiber: 2.6),
    'aguacate': (kcal: 160, protein: 2.0, carbs: 8.5, fat: 15.0, fiber: 6.7),
    'avocado': (kcal: 160, protein: 2.0, carbs: 8.5, fat: 15.0, fiber: 6.7),
    'papa cocida': (kcal: 87, protein: 1.9, carbs: 20.0, fat: 0.1, fiber: 1.8),
    'papas': (kcal: 87, protein: 1.9, carbs: 20.0, fat: 0.1, fiber: 1.8),
    'papa': (kcal: 87, protein: 1.9, carbs: 20.0, fat: 0.1, fiber: 1.8),
    'pan de caja': (kcal: 265, protein: 9.0, carbs: 49.0, fat: 3.2, fiber: 2.7),
    'pan': (kcal: 265, protein: 9.0, carbs: 49.0, fat: 3.2, fiber: 2.7),
    'queso': (kcal: 350, protein: 22.0, carbs: 2.4, fat: 28.0, fiber: 0.0),
  };

  static ({int kcal, double protein, double carbs, double fat, double fiber})? _lookupAnchor(
    String rawName,
  ) {
    final lower = rawName.toLowerCase().trim();
    if (lower.isEmpty) return null;
    final sortedKeys = _anchorPer100g.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final token in sortedKeys) {
      if (lower.contains(token)) return _anchorPer100g[token];
    }
    return null;
  }

  /// Atwater: 4 kcal/g proteína + 4 kcal/g carbs + 9 kcal/g grasa.
  static int kcalFromMacros({
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) {
    return ((proteinG * 4) + (carbsG * 4) + (fatG * 9)).round().clamp(0, 9999);
  }

  /// Estima nutrición sumando anclas por [ingredientPortions] (o ingredients + total).
  static FoodNutritionEstimate? estimateFromIngredientAnchors(FoodNutritionEstimate ai) {
    final portions = ai.ingredientPortions.isNotEmpty
        ? ai.ingredientPortions
        : (ai.ingredients.length == 1 && ai.referenceAmount > 0
            ? [FoodIngredientPortion(name: ai.ingredients.first, gramsG: ai.referenceAmount)]
            : const <FoodIngredientPortion>[]);

    if (portions.isEmpty) {
      final fromName = _lookupAnchor(ai.name);
      if (fromName == null || ai.referenceAmount <= 0) return null;
      final factor = ai.referenceAmount / 100;
      return ai.copyWith(
        caloriesKcal: (fromName.kcal * factor).round().clamp(0, 9999),
        proteinG: double.parse((fromName.protein * factor).toStringAsFixed(1)),
        carbsG: double.parse((fromName.carbs * factor).toStringAsFixed(1)),
        fatG: double.parse((fromName.fat * factor).toStringAsFixed(1)),
        fiberG: double.parse((fromName.fiber * factor).toStringAsFixed(1)),
      );
    }

    var totalKcal = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    var fiber = 0.0;
    var matchedGrams = 0.0;
    for (final portion in portions) {
      final anchor = _lookupAnchor(portion.name);
      if (anchor == null || portion.gramsG <= 0) continue;
      final factor = portion.gramsG / 100;
      totalKcal += anchor.kcal * factor;
      protein += anchor.protein * factor;
      carbs += anchor.carbs * factor;
      fat += anchor.fat * factor;
      fiber += anchor.fiber * factor;
      matchedGrams += portion.gramsG;
    }

    if (matchedGrams <= 0 || totalKcal < 1) return null;

    // Si faltan ingredientes sin ancla, escala el total al peso de referencia.
    final targetGrams = ai.referenceAmount > 0
        ? ai.referenceAmount
        : portions.fold<double>(0, (sum, p) => sum + p.gramsG);
    if (targetGrams > matchedGrams * 1.15) {
      final scale = targetGrams / matchedGrams;
      totalKcal *= scale;
      protein *= scale;
      carbs *= scale;
      fat *= scale;
      fiber *= scale;
    }

    return ai.copyWith(
      caloriesKcal: totalKcal.round().clamp(0, 9999),
      proteinG: double.parse(protein.toStringAsFixed(1)),
      carbsG: double.parse(carbs.toStringAsFixed(1)),
      fatG: double.parse(fat.toStringAsFixed(1)),
      fiberG: double.parse(fiber.toStringAsFixed(1)),
    );
  }

  /// Recupera kcal cuando la IA deja 0 (o macros incoherentes) pese a gramos/macros.
  /// Pensado sobre todo para estimación por foto, donde no hay texto del usuario.
  static FoodNutritionEstimate ensurePlausibleCalories(FoodNutritionEstimate ai) {
    final macroKcal = kcalFromMacros(
      proteinG: ai.proteinG,
      carbsG: ai.carbsG,
      fatG: ai.fatG,
    );

    if (ai.caloriesKcal > 0) {
      // Macros rellenos pero kcal muy por debajo de Atwater → confía en macros.
      if (macroKcal >= 40 && ai.caloriesKcal < (macroKcal * 0.5).round()) {
        return ai.copyWith(caloriesKcal: macroKcal);
      }
      return ai;
    }

    if (macroKcal >= 20) {
      return ai.copyWith(caloriesKcal: macroKcal);
    }

    final fromAnchors = estimateFromIngredientAnchors(ai);
    if (fromAnchors != null && fromAnchors.caloriesKcal > 0) {
      return fromAnchors;
    }

    return ai;
  }

  /// Post-proceso para estimaciones por foto (sin query de texto del usuario).
  static FoodNutritionEstimate reconcilePhotoEstimate(FoodNutritionEstimate ai) {
    var result = ai;
    if (result.ingredientPortions.isEmpty && result.ingredients.length > 1) {
      result = ensureIngredientPortions(result.name, result);
    }
    return ensurePlausibleCalories(result);
  }

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
        ingredients: ai.ingredients.isNotEmpty ? ai.ingredients : [token],
        ingredientPortions: [FoodIngredientPortion(name: token, gramsG: grams)],
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
      return ensurePlausibleCalories(ensureIngredientPortions(query, gramCorrected));
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

    if (kcal <= 0) {
      return ensurePlausibleCalories(ensureIngredientPortions(query, gramCorrected));
    }

    final floor = (kcal * 0.95).round();
    if (gramCorrected.caloriesKcal >= floor) {
      return ensurePlausibleCalories(ensureIngredientPortions(query, gramCorrected));
    }

    return ensurePlausibleCalories(
      ensureIngredientPortions(
        query,
        FoodNutritionEstimate(
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
        ),
      ),
    );
  }
}

extension _IterableLastOrNull<E> on Iterable<E> {
  E? get lastOrNull => isEmpty ? null : last;
}
