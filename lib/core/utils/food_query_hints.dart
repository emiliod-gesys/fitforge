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
    final totalPlate = parseTotalPlateGrams(query);
    if (totalPlate != null) {
      return compositePortionsFromQuery(
        query,
        totalPlate.grams,
        totalPlate.name,
      );
    }

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

  /// Peso total del plato cuando el usuario escribe "315g de tacos con queso".
  static ({double grams, String name})? parseTotalPlateGrams(String query) {
    final trimmed = query.trim();
    final gramMatches = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*g(?:ramos?)?\b',
      caseSensitive: false,
    ).allMatches(trimmed);
    if (gramMatches.length != 1) return null;

    final match = RegExp(
      r'^(\d+(?:[.,]\d+)?)\s*g(?:ramos?)?\s+de\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match == null) return null;

    final grams = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    final name = match.group(2)!.trim();
    if (grams == null || grams <= 0 || name.isEmpty) return null;
    return (grams: grams, name: name);
  }

  /// Reparte el peso total entre plato principal y complementos ("con …").
  static List<FoodIngredientPortion> compositePortionsFromQuery(
    String query,
    double totalGrams,
    String fullName,
  ) {
    final parts = RegExp(r'\s+con\s+', caseSensitive: false).split(fullName);
    final mainName = _cleanIngredientName(parts.first);
    if (parts.length <= 1) {
      return [FoodIngredientPortion(name: mainName, gramsG: totalGrams)];
    }

    final addonText = parts.sublist(1).join(' con ').toLowerCase();
    final cheeseAddon = RegExp(
      r'costra de queso|queso fundido|gratinado|cheese crust',
      caseSensitive: false,
    ).hasMatch(addonText);

    if (cheeseAddon) {
      const cheeseShare = 0.12;
      final cheeseGrams = totalGrams * cheeseShare;
      return [
        FoodIngredientPortion(name: mainName, gramsG: totalGrams - cheeseGrams),
        FoodIngredientPortion(name: 'costra de queso', gramsG: cheeseGrams),
      ];
    }

    const addonShare = 0.15;
    final addonGrams = totalGrams * addonShare;
    return [
      FoodIngredientPortion(name: mainName, gramsG: totalGrams - addonGrams),
      FoodIngredientPortion(
        name: _cleanIngredientName(parts.sublist(1).join(' con ')),
        gramsG: addonGrams,
      ),
    ];
  }

  static String _primaryQueryText(String query) {
    final totalPlate = parseTotalPlateGrams(query);
    if (totalPlate != null) {
      return RegExp(r'\s+con\s+', caseSensitive: false)
          .split(totalPlate.name)
          .first
          .trim();
    }
    final conMatch = RegExp(r'\s+con\s+', caseSensitive: false).firstMatch(query);
    if (conMatch != null) return query.substring(0, conMatch.start);
    return query;
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
    'arroz integral cocido': (kcal: 112, protein: 2.3, carbs: 24.0, fat: 0.8, fiber: 1.8),
    'arroz cocido': (kcal: 130, protein: 2.7, carbs: 28.0, fat: 0.3, fiber: 0.4),
    'arroz blanco': (kcal: 130, protein: 2.7, carbs: 28.0, fat: 0.3, fiber: 0.4),
    'arroz integral': (kcal: 112, protein: 2.3, carbs: 24.0, fat: 0.8, fiber: 1.8),
    'white rice': (kcal: 130, protein: 2.7, carbs: 28.0, fat: 0.3, fiber: 0.4),
    'brown rice': (kcal: 112, protein: 2.3, carbs: 24.0, fat: 0.8, fiber: 1.8),
    'arroz': (kcal: 130, protein: 2.7, carbs: 28.0, fat: 0.3, fiber: 0.4),
    // Proteínas comunes (cocidas / a la plancha).
    'pechuga de pollo': (kcal: 165, protein: 31.0, carbs: 0.0, fat: 3.6, fiber: 0.0),
    'pollo a la plancha': (kcal: 165, protein: 31.0, carbs: 0.0, fat: 3.6, fiber: 0.0),
    'pollo asado': (kcal: 167, protein: 25.0, carbs: 0.0, fat: 6.6, fiber: 0.0),
    'chicken breast': (kcal: 165, protein: 31.0, carbs: 0.0, fat: 3.6, fiber: 0.0),
    'pollo': (kcal: 165, protein: 31.0, carbs: 0.0, fat: 3.6, fiber: 0.0),
    'chicken': (kcal: 165, protein: 31.0, carbs: 0.0, fat: 3.6, fiber: 0.0),
    'carne de res': (kcal: 217, protein: 26.0, carbs: 0.0, fat: 12.0, fiber: 0.0),
    'bistec': (kcal: 217, protein: 26.0, carbs: 0.0, fat: 12.0, fiber: 0.0),
    'res': (kcal: 217, protein: 26.0, carbs: 0.0, fat: 12.0, fiber: 0.0),
    'beef': (kcal: 217, protein: 26.0, carbs: 0.0, fat: 12.0, fiber: 0.0),
    'carne de cerdo': (kcal: 196, protein: 27.0, carbs: 0.0, fat: 9.0, fiber: 0.0),
    'cerdo': (kcal: 196, protein: 27.0, carbs: 0.0, fat: 9.0, fiber: 0.0),
    'pork': (kcal: 196, protein: 27.0, carbs: 0.0, fat: 9.0, fiber: 0.0),
    'salmón': (kcal: 208, protein: 20.0, carbs: 0.0, fat: 13.0, fiber: 0.0),
    'salmon': (kcal: 208, protein: 20.0, carbs: 0.0, fat: 13.0, fiber: 0.0),
    'atún': (kcal: 132, protein: 28.0, carbs: 0.0, fat: 1.3, fiber: 0.0),
    'atun': (kcal: 132, protein: 28.0, carbs: 0.0, fat: 1.3, fiber: 0.0),
    'tuna': (kcal: 132, protein: 28.0, carbs: 0.0, fat: 1.3, fiber: 0.0),
    'pescado': (kcal: 130, protein: 25.0, carbs: 0.0, fat: 3.0, fiber: 0.0),
    'fish': (kcal: 130, protein: 25.0, carbs: 0.0, fat: 3.0, fiber: 0.0),
    'huevos': (kcal: 155, protein: 13.0, carbs: 1.1, fat: 11.0, fiber: 0.0),
    'huevo': (kcal: 155, protein: 13.0, carbs: 1.1, fat: 11.0, fiber: 0.0),
    'egg': (kcal: 155, protein: 13.0, carbs: 1.1, fat: 11.0, fiber: 0.0),
    'tofu': (kcal: 76, protein: 8.0, carbs: 1.9, fat: 4.8, fiber: 0.3),
    // Guarniciones / verduras.
    'brócoli': (kcal: 35, protein: 2.8, carbs: 7.0, fat: 0.4, fiber: 2.6),
    'brocoli': (kcal: 35, protein: 2.8, carbs: 7.0, fat: 0.4, fiber: 2.6),
    'broccoli': (kcal: 35, protein: 2.8, carbs: 7.0, fat: 0.4, fiber: 2.6),
    'lechuga': (kcal: 15, protein: 1.4, carbs: 2.9, fat: 0.2, fiber: 1.3),
    'lettuce': (kcal: 15, protein: 1.4, carbs: 2.9, fat: 0.2, fiber: 1.3),
    'tomate': (kcal: 18, protein: 0.9, carbs: 3.9, fat: 0.2, fiber: 1.2),
    'tomato': (kcal: 18, protein: 0.9, carbs: 3.9, fat: 0.2, fiber: 1.2),
    'pepino': (kcal: 15, protein: 0.7, carbs: 3.6, fat: 0.1, fiber: 0.5),
    'cucumber': (kcal: 15, protein: 0.7, carbs: 3.6, fat: 0.1, fiber: 0.5),
    'zanahoria': (kcal: 41, protein: 0.9, carbs: 10.0, fat: 0.2, fiber: 2.8),
    'carrot': (kcal: 41, protein: 0.9, carbs: 10.0, fat: 0.2, fiber: 2.8),
    'papa': (kcal: 87, protein: 1.9, carbs: 20.0, fat: 0.1, fiber: 1.8),
    'patata': (kcal: 87, protein: 1.9, carbs: 20.0, fat: 0.1, fiber: 1.8),
    'potato': (kcal: 87, protein: 1.9, carbs: 20.0, fat: 0.1, fiber: 1.8),
    'camote': (kcal: 86, protein: 1.6, carbs: 20.0, fat: 0.1, fiber: 3.0),
    'batata': (kcal: 86, protein: 1.6, carbs: 20.0, fat: 0.1, fiber: 3.0),
    'sweet potato': (kcal: 86, protein: 1.6, carbs: 20.0, fat: 0.1, fiber: 3.0),
    'frijoles': (kcal: 127, protein: 8.7, carbs: 23.0, fat: 0.5, fiber: 6.4),
    'beans': (kcal: 127, protein: 8.7, carbs: 23.0, fat: 0.5, fiber: 6.4),
    'lentejas': (kcal: 116, protein: 9.0, carbs: 20.0, fat: 0.4, fiber: 7.9),
    'lentils': (kcal: 116, protein: 9.0, carbs: 20.0, fat: 0.4, fiber: 7.9),
    'aguacate': (kcal: 160, protein: 2.0, carbs: 8.5, fat: 15.0, fiber: 6.7),
    'avocado': (kcal: 160, protein: 2.0, carbs: 8.5, fat: 15.0, fiber: 6.7),
    'tortilla de maíz': (kcal: 218, protein: 5.7, carbs: 45.0, fat: 2.9, fiber: 6.3),
    'tortilla de maiz': (kcal: 218, protein: 5.7, carbs: 45.0, fat: 2.9, fiber: 6.3),
    'tortilla de harina': (kcal: 312, protein: 8.0, carbs: 51.0, fat: 8.0, fiber: 2.0),
    'tortilla': (kcal: 218, protein: 5.7, carbs: 45.0, fat: 2.9, fiber: 6.3),
    'tacos al pastor': (kcal: 230, protein: 12.0, carbs: 18.0, fat: 13.0, fiber: 1.5),
    'taco al pastor': (kcal: 230, protein: 12.0, carbs: 18.0, fat: 13.0, fiber: 1.5),
    'tacos': (kcal: 210, protein: 10.0, carbs: 20.0, fat: 11.0, fiber: 1.5),
    'taco': (kcal: 210, protein: 10.0, carbs: 20.0, fat: 11.0, fiber: 1.5),
    'costra de queso': (kcal: 350, protein: 18.0, carbs: 2.0, fat: 28.0, fiber: 0.0),
    'pan': (kcal: 265, protein: 9.0, carbs: 49.0, fat: 3.2, fiber: 2.7),
    'bread': (kcal: 265, protein: 9.0, carbs: 49.0, fat: 3.2, fiber: 2.7),
    'queso': (kcal: 350, protein: 25.0, carbs: 2.0, fat: 27.0, fiber: 0.0),
    'cheese': (kcal: 350, protein: 25.0, carbs: 2.0, fat: 27.0, fiber: 0.0),
    'aceite de oliva': (kcal: 884, protein: 0.0, carbs: 0.0, fat: 100.0, fiber: 0.0),
    'olive oil': (kcal: 884, protein: 0.0, carbs: 0.0, fat: 100.0, fiber: 0.0),
    'aceite': (kcal: 884, protein: 0.0, carbs: 0.0, fat: 100.0, fiber: 0.0),
  };

  static ({int kcal, double protein, double carbs, double fat, double fiber})?
      _lookupAnchor(String ingredientName) {
    final lower = ingredientName.toLowerCase().trim();
    if (lower.isEmpty) return null;
    final sortedKeys = _anchorPer100g.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final token in sortedKeys) {
      if (lower.contains(token)) return _anchorPer100g[token];
    }
    return null;
  }

  /// Estima macros sumando densidades conocidas de `ingredient_portions`.
  static FoodNutritionEstimate? estimateFromIngredientPortions(FoodNutritionEstimate ai) {
    if (ai.ingredientPortions.isEmpty) return null;

    var totalKcal = 0.0;
    var totalProtein = 0.0;
    var totalCarbs = 0.0;
    var totalFat = 0.0;
    var totalFiber = 0.0;
    var matchedGrams = 0.0;
    var totalGrams = 0.0;

    for (final portion in ai.ingredientPortions) {
      if (portion.gramsG <= 0) continue;
      totalGrams += portion.gramsG;
      final anchor = _lookupAnchor(portion.name);
      if (anchor == null) continue;
      final factor = portion.gramsG / 100;
      matchedGrams += portion.gramsG;
      totalKcal += anchor.kcal * factor;
      totalProtein += anchor.protein * factor;
      totalCarbs += anchor.carbs * factor;
      totalFat += anchor.fat * factor;
      totalFiber += anchor.fiber * factor;
    }

    if (totalKcal <= 0) return null;
    // Exigir cobertura razonable para no inventar el plato entero con 1 ancla.
    if (matchedGrams < 40 && matchedGrams < totalGrams * 0.35) return null;

    final referenceAmount = totalGrams > 0
        ? totalGrams
        : (ai.referenceAmount > 0 ? ai.referenceAmount : matchedGrams);

    return ai.copyWith(
      caloriesKcal: totalKcal.round().clamp(0, 9999),
      proteinG: double.parse(totalProtein.toStringAsFixed(1)),
      carbsG: double.parse(totalCarbs.toStringAsFixed(1)),
      fatG: double.parse(totalFat.toStringAsFixed(1)),
      fiberG: double.parse(totalFiber.toStringAsFixed(1)),
      referenceAmount: referenceAmount,
      amountUnit: 'g',
      servingDescription: FoodServingParser.formatAmount(referenceAmount, 'g'),
      ingredients: ai.ingredientPortions.map((p) => p.name).toList(),
    );
  }

  /// Corrige estimaciones de foto cuando la IA deja kcal en 0 pero sí da gramos.
  static FoodNutritionEstimate reconcilePhotoEstimate(FoodNutritionEstimate ai) {
    var result = ai;
    if (ai.ingredientPortions.isNotEmpty) {
      final sumGrams =
          ai.ingredientPortions.fold<double>(0, (sum, p) => sum + p.gramsG);
      if (sumGrams > 0) {
        result = ai.copyWith(
          referenceAmount: sumGrams,
          amountUnit: 'g',
          servingDescription: ai.servingDescription?.trim().isNotEmpty == true
              ? ai.servingDescription
              : FoodServingParser.formatAmount(sumGrams, 'g'),
          ingredients: ai.ingredientPortions.map((p) => p.name).toList(),
        );
      }
    }

    final fromPortions = estimateFromIngredientPortions(result);
    if (fromPortions != null) {
      if (result.caloriesKcal <= 0) return fromPortions;
      final dens = result.referenceAmount > 0
          ? result.caloriesKcal / result.referenceAmount
          : 0.0;
      // Densidad absurda (<0.3 kcal/g ≈ <30 kcal/100g) en plato mixto → reemplazar.
      if (dens < 0.3 && fromPortions.caloriesKcal > result.caloriesKcal) {
        return fromPortions;
      }
    }

    if (result.caloriesKcal <= 0 && result.referenceAmount > 0) {
      final query = '${result.name} ${result.referenceAmount.round()}g';
      final anchored = anchoredEstimateForQuery(query, result);
      if (anchored != null) {
        return anchored.copyWith(
          ingredientPortions: result.ingredientPortions.isNotEmpty
              ? result.ingredientPortions
              : anchored.ingredientPortions,
          ingredients: result.ingredients.isNotEmpty
              ? result.ingredients
              : anchored.ingredients,
        );
      }
    }

    return result;
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
    final totalPlate = parseTotalPlateGrams(query);
    if (totalPlate != null) {
      final portions = compositePortionsFromQuery(
        query,
        totalPlate.grams,
        totalPlate.name,
      );
      final fromPortions = estimateFromIngredientPortions(
        ai.copyWith(
          name: ai.name.trim().isNotEmpty ? ai.name : totalPlate.name,
          ingredientPortions: portions,
          ingredients: portions.map((p) => p.name).toList(),
          referenceAmount: totalPlate.grams,
          amountUnit: 'g',
          servingDescription: FoodServingParser.formatAmount(totalPlate.grams, 'g'),
        ),
      );
      if (fromPortions != null) return fromPortions;
    }

    final grams = parseGrams(query);
    if (grams == null || grams <= 0) return null;

    final primaryText = _primaryQueryText(query).toLowerCase();
    final sortedKeys = _anchorPer100g.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final token in sortedKeys) {
      if (!primaryText.contains(token)) continue;
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
      return _finalizePortionEstimate(query, ensureIngredientPortions(query, gramCorrected));
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
      return _finalizePortionEstimate(query, ensureIngredientPortions(query, gramCorrected));
    }

    final floor = (kcal * 0.95).round();
    if (gramCorrected.caloriesKcal >= floor) {
      return _finalizePortionEstimate(query, ensureIngredientPortions(query, gramCorrected));
    }

    return _finalizePortionEstimate(
      query,
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

  static FoodNutritionEstimate _finalizePortionEstimate(
    String query,
    FoodNutritionEstimate estimate,
  ) {
    final fromPortions = estimateFromIngredientPortions(estimate);
    if (fromPortions == null) return estimate;

    if (estimate.ingredientPortions.length >= 2) return fromPortions;

    if (parseTotalPlateGrams(query) != null) {
      final solo = estimate.ingredientPortions.length == 1
          ? estimate.ingredientPortions.first.name.toLowerCase()
          : '';
      if (solo.contains('queso') && !solo.contains('taco')) {
        return fromPortions;
      }
      if (estimate.ingredientPortions.length >= 2) return fromPortions;
    }

    if (estimate.caloriesKcal <= 0) return fromPortions;

    final kcalPerG = estimate.referenceAmount > 0
        ? estimate.caloriesKcal / estimate.referenceAmount
        : 0.0;
    if (kcalPerG > 3.2 && fromPortions.caloriesKcal < estimate.caloriesKcal) {
      return fromPortions;
    }

    return estimate;
  }
}

extension _IterableLastOrNull<E> on Iterable<E> {
  E? get lastOrNull => isEmpty ? null : last;
}
