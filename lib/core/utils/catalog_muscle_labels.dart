import 'dart:convert';

/// Normaliza etiquetas de músculos/categorías del catálogo cloud (español canónico + mojibake).
abstract final class CatalogMuscleLabels {
  static String fixUtf8Mojibake(String input) {
    if (!input.contains('Ã') && !input.contains('â')) return input;
    try {
      return utf8.decode(latin1.encode(input), allowMalformed: true);
    } catch (_) {
      return input;
    }
  }

  static String canonicalMuscleKey(String raw) {
    final fixed = fixUtf8Mojibake(raw.trim());
    if (fixed.isEmpty) return fixed;

    final lower = fixed.toLowerCase();
    const aliases = {
      'pecho': 'Pecho',
      'pectorals': 'Pecho',
      'pecs': 'Pecho',
      'chest': 'Pecho',
      'pechos': 'Pecho',
      'espalda': 'Espalda',
      'back': 'Espalda',
      'lats': 'Dorsales',
      'latissimus dorsi': 'Dorsales',
      'dorsales': 'Dorsales',
      'espalda alta': 'Espalda alta',
      'upper back': 'Espalda alta',
      'espalda baja': 'Espalda baja',
      'lower back': 'Espalda baja',
      'hombros': 'Hombros',
      'shoulders': 'Hombros',
      'delts': 'Hombros',
      'deltoids': 'Hombros',
      'bíceps': 'Bíceps',
      'biceps': 'Bíceps',
      'tríceps': 'Tríceps',
      'triceps': 'Tríceps',
      'piernas': 'Piernas',
      'legs': 'Piernas',
      'cuádriceps': 'Cuádriceps',
      'quadriceps': 'Cuádriceps',
      'quads': 'Cuádriceps',
      'isquios': 'Isquios',
      'hamstrings': 'Isquios',
      'glúteos': 'Glúteos',
      'glutes': 'Glúteos',
      'gluteus': 'Glúteos',
      'abdominales': 'Abdominales',
      'abs': 'Abdominales',
      'core': 'Abdominales',
      'pantorrillas': 'Pantorrillas',
      'calves': 'Pantorrillas',
      'antebrazos': 'Antebrazos',
      'forearms': 'Antebrazos',
      'trapecios': 'Trapecios',
      'traps': 'Trapecios',
      'aductores': 'Aductores',
      'cardio': 'Cardio',
      'cardiovascular': 'Cardio',
      'brazos': 'Brazos',
      'arms': 'Brazos',
    };

    return aliases[lower] ?? fixed;
  }

  static String canonicalCategoryKey(String raw) =>
      canonicalMuscleKey(raw.isEmpty ? 'Otros' : raw);

  static List<String> canonicalizeMuscles(Iterable<String> muscles) {
    final seen = <String>{};
    final out = <String>[];
    for (final muscle in muscles) {
      final key = canonicalMuscleKey(muscle);
      if (key.isEmpty || !seen.add(key)) continue;
      out.add(key);
    }
    return out;
  }

  static String englishCategoryLabel(String canonicalEs) {
    return switch (canonicalEs) {
      'Pecho' => 'Chest',
      'Espalda' => 'Back',
      'Hombros' => 'Shoulders',
      'Bíceps' => 'Biceps',
      'Tríceps' => 'Triceps',
      'Piernas' => 'Legs',
      'Glúteos' => 'Glutes',
      'Abdominales' => 'Abs',
      'Antebrazos' => 'Forearms',
      'Pantorrillas' => 'Calves',
      'Cardio' => 'Cardio',
      'Brazos' => 'Arms',
      'Dorsales' => 'Lats',
      'Cuádriceps' => 'Quadriceps',
      'Isquios' => 'Hamstrings',
      'Trapecios' => 'Traps',
      'Espalda alta' => 'Upper back',
      'Espalda baja' => 'Lower back',
      'Aductores' => 'Adductors',
      'Otros' => 'Other',
      _ => canonicalEs,
    };
  }

  static String englishMuscleLabel(String canonicalEs) {
    return switch (canonicalEs) {
      'Pecho' => 'Chest',
      'Espalda' => 'Back',
      'Hombros' => 'Shoulders',
      'Bíceps' => 'Biceps',
      'Tríceps' => 'Triceps',
      'Piernas' => 'Legs',
      'Glúteos' => 'Glutes',
      'Abdominales' => 'Abs',
      'Antebrazos' => 'Forearms',
      'Pantorrillas' => 'Calves',
      'Cardio' => 'Cardio',
      'Dorsales' => 'Lats',
      'Cuádriceps' => 'Quadriceps',
      'Isquios' => 'Hamstrings',
      'Trapecios' => 'Traps',
      'Espalda alta' => 'Upper back',
      'Espalda baja' => 'Lower back',
      'Aductores' => 'Adductors',
      'Brazos' => 'Arms',
      _ => canonicalEs,
    };
  }
}
