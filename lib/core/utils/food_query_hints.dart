import '../../models/food_entry.dart';

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

  /// Ajusta la estimación de IA si el usuario dio calorías explícitas o cantidades claras.
  static FoodNutritionEstimate reconcile(String query, FoodNutritionEstimate ai) {
    final labeledKcal = labeledKcalTotal(query);
    final eggs = eggCount(query);

    if (labeledKcal == 0 && eggs == 0) return ai;

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

    if (kcal <= 0) return ai;

    final floor = (kcal * 0.95).round();
    if (ai.caloriesKcal >= floor) return ai;

    return FoodNutritionEstimate(
      name: ai.name,
      brand: ai.brand,
      caloriesKcal: kcal.round(),
      proteinG: double.parse(protein.toStringAsFixed(1)),
      carbsG: double.parse(carbs.toStringAsFixed(1)),
      fatG: double.parse(fat.toStringAsFixed(1)),
      fiberG: ai.fiberG,
      servingDescription: ai.servingDescription,
      ingredients: ai.ingredients,
      referenceAmount: ai.referenceAmount > 0 ? ai.referenceAmount : 180,
      amountUnit: ai.amountUnit,
    );
  }
}

extension _IterableLastOrNull<E> on Iterable<E> {
  E? get lastOrNull => isEmpty ? null : last;
}
