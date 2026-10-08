import '../../models/exercise.dart';

/// Músculo principal concreto del catálogo (pecho inferior, deltoides lateral…).
///
/// «Pecho inferior» y «Lower chest» son la misma subcategoría. «Pecho» no.
abstract final class MuscleSubcategory {
  static String? keyOf(Exercise? exercise) {
    if (exercise == null) return null;
    if (exercise.muscles.isNotEmpty) return canonical(exercise.muscles.first);
    if (exercise.category.trim().isNotEmpty) return canonical(exercise.category);
    return null;
  }

  static bool samePrimary(Exercise exercise, String key) {
    final candidate = keyOf(exercise);
    return candidate != null && candidate == key;
  }

  static String? canonical(String raw) {
    final normalized = _normalize(raw);
    if (normalized.isEmpty) return null;
    return _aliases[normalized] ?? normalized;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const _aliases = <String, String>{
    'pecho superior': 'pecho_superior',
    'upper chest': 'pecho_superior',
    'pecho inferior': 'pecho_inferior',
    'lower chest': 'pecho_inferior',
    'pecho': 'pecho',
    'chest': 'pecho',
    'pectoral': 'pecho',
    'pectorals': 'pecho',
    'pecs': 'pecho',
    'espalda alta': 'espalda_alta',
    'upper back': 'espalda_alta',
    'espalda baja': 'espalda_baja',
    'lower back': 'espalda_baja',
    'dorsales': 'dorsales',
    'lats': 'dorsales',
    'latissimus dorsi': 'dorsales',
    'espalda': 'espalda',
    'back': 'espalda',
    'deltoides anterior': 'deltoides_anterior',
    'front delts': 'deltoides_anterior',
    'front deltoid': 'deltoides_anterior',
    'anterior deltoid': 'deltoides_anterior',
    'deltoides lateral': 'deltoides_lateral',
    'side delts': 'deltoides_lateral',
    'lateral deltoid': 'deltoides_lateral',
    'deltoides posterior': 'deltoides_posterior',
    'rear delts': 'deltoides_posterior',
    'rear deltoid': 'deltoides_posterior',
    'posterior deltoid': 'deltoides_posterior',
    'deltoides': 'hombros',
    'delts': 'hombros',
    'hombros': 'hombros',
    'shoulders': 'hombros',
    'biceps': 'biceps',
    'braquial': 'braquial',
    'brachialis': 'braquial',
    'triceps': 'triceps',
    'antebrazos': 'antebrazos',
    'forearms': 'antebrazos',
    'cuadriceps': 'cuadriceps',
    'quads': 'cuadriceps',
    'quadriceps': 'cuadriceps',
    'isquios': 'isquios',
    'hamstrings': 'isquios',
    'isquiotibiales': 'isquios',
    'gluteo medio': 'gluteo_medio',
    'glute medius': 'gluteo_medio',
    'gluteus medius': 'gluteo_medio',
    'gluteos': 'gluteos',
    'glutes': 'gluteos',
    'aductores': 'aductores',
    'adductors': 'aductores',
    'pantorrillas': 'pantorrillas',
    'calves': 'pantorrillas',
    'abdominales': 'abdominales',
    'abs': 'abdominales',
    'trapecio inferior': 'trapecio_inferior',
    'lower traps': 'trapecio_inferior',
  };
}
