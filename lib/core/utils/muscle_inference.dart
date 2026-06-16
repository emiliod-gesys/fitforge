/// Infiere grupos musculares a partir del nombre del ejercicio.
abstract final class MuscleInference {
  static List<String> fromExerciseName(String exerciseName) {
    final name = _normalize(exerciseName);
    if (name.isEmpty) return [];

    final muscles = <String>{};

    if (_matches(name, [
      'tricep',
      'triceps',
      'trícep',
      'pushdown',
      'push down',
      'skull',
      'patada',
      'kickback',
    ])) {
      muscles.add('Tríceps');
    }

    if (_matches(name, ['curl', 'bicep', 'bícep', 'martillo', 'hammer'])) {
      muscles.add('Bíceps');
    }

    if (_matches(name, [
      'hombro',
      'shoulder',
      'lateral',
      'front raise',
      'elevacion frontal',
      'elevación frontal',
      'arnold',
      'militar',
      'overhead',
      'face pull',
    ])) {
      muscles.add('Hombros');
    }

    if (_matches(name, [
      'pecho',
      'chest',
      'bench',
      'pectoral',
      'apertura',
      'fly',
      'push up',
      'push-up',
      'flexion',
      'flexión',
      'fondos',
      'dip',
    ])) {
      muscles.add('Pecho');
    }

    if (_matches(name, ['press', 'press de', 'press con']) &&
        !_matches(name, ['pierna', 'leg', 'prensa de pierna'])) {
      if (_matches(name, ['militar', 'hombro', 'shoulder', 'overhead', 'arnold'])) {
        muscles.add('Hombros');
        muscles.add('Tríceps');
      } else if (_matches(name, ['inclinado', 'declinado', 'banca', 'bench', 'pecho', 'chest'])) {
        muscles.add('Pecho');
        muscles.add('Tríceps');
        if (name.contains('inclinado')) muscles.add('Hombros');
      } else if (!muscles.contains('Pecho') && !muscles.contains('Hombros')) {
        muscles.add('Pecho');
        muscles.add('Tríceps');
      }
    }

    if (_matches(name, [
      'espalda',
      'back',
      'remo',
      'row',
      'pull',
      'jalon',
      'jalón',
      'lat',
      'dominada',
      'pulldown',
      'peso muerto',
      'deadlift',
    ])) {
      muscles.add('Espalda');
    }

    if (_matches(name, [
      'sentadilla',
      'squat',
      'pierna',
      'leg press',
      'extension de cuadriceps',
      'extensión de cuádriceps',
      'curl femoral',
      'zancada',
      'lunge',
      'prensa',
    ]) &&
        !_matches(name, ['prensa de hombro', 'militar'])) {
      muscles.add('Piernas');
    }

    if (_matches(name, ['gluteo', 'glúteo', 'hip thrust', 'puente'])) {
      muscles.add('Glúteos');
    }

    if (_matches(name, ['abdominal', 'core', 'crunch', 'plancha'])) {
      muscles.add('Abdominales');
    }

    return muscles.toList();
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .trim();
  }

  static bool _matches(String name, List<String> terms) {
    for (final term in terms) {
      if (name.contains(_normalize(term))) return true;
    }
    return false;
  }
}
