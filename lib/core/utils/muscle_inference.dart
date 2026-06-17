import '../../data/supplemental_exercises.dart';
import '../../models/exercise.dart';

/// Infiere grupos musculares para recuperación a partir del catálogo o del nombre.
abstract final class MuscleInference {
  /// Resuelve músculos: catálogo (wger/suplementarios) primero, heurística como respaldo.
  static List<String> resolve({
    required String exerciseName,
    String? exerciseId,
    List<Exercise>? catalog,
  }) {
    final fromCatalog = _lookupCatalog(
      exerciseName: exerciseName,
      exerciseId: exerciseId,
      catalog: catalog,
    );
    if (fromCatalog != null && fromCatalog.isNotEmpty) {
      return fromCatalog;
    }

    for (final extra in SupplementalExercises.all()) {
      if (_matchesExercise(extra, exerciseId: exerciseId, exerciseName: exerciseName)) {
        return fromExerciseMuscles(extra.muscles, extra.category);
      }
    }

    return fromExerciseName(exerciseName);
  }

  static List<String>? _lookupCatalog({
    required String exerciseName,
    String? exerciseId,
    List<Exercise>? catalog,
  }) {
    if (catalog == null || catalog.isEmpty) return null;

    for (final exercise in catalog) {
      if (_matchesExercise(exercise, exerciseId: exerciseId, exerciseName: exerciseName)) {
        return fromExerciseMuscles(exercise.muscles, exercise.category);
      }
    }
    return null;
  }

  static bool _matchesExercise(
    Exercise exercise, {
    String? exerciseId,
    required String exerciseName,
  }) {
    if (exerciseId != null && exerciseId.isNotEmpty) {
      if (exercise.id == exerciseId) return true;
      if (exercise.wgerId?.toString() == exerciseId) return true;
    }
    return exercise.matchesName(exerciseName);
  }

  /// Mapea músculos del catálogo a los grupos de recuperación de la app.
  static List<String> fromExerciseMuscles(List<String> muscles, String category) {
    final groups = <String>{};
    for (final muscle in muscles) {
      final group = _mapToRecoveryGroup(muscle);
      if (group != null) groups.add(group);
    }

    if (groups.isEmpty) {
      final fromCategory = _mapCategoryToRecoveryGroup(category);
      if (fromCategory != null) groups.add(fromCategory);
    }

    return groups.toList();
  }

  static String? _mapToRecoveryGroup(String muscle) {
    final m = _normalize(muscle);
    if (m.isEmpty) return null;

    if (_containsAny(m, ['biceps', 'bíceps'])) return 'Bíceps';
    if (_containsAny(m, ['triceps', 'tríceps'])) return 'Tríceps';
    if (_containsAny(m, ['pecho', 'chest', 'pectoral'])) return 'Pecho';
    if (_containsAny(m, ['espalda', 'back', 'latissimus', 'dorsal', 'trapecio', 'romboid'])) {
      return 'Espalda';
    }
    if (_containsAny(m, ['hombro', 'shoulder', 'deltoid', 'deltoides'])) return 'Hombros';
    if (_containsAny(m, [
      'pierna',
      'leg',
      'cuadriceps',
      'cuádriceps',
      'quadriceps',
      'isquio',
      'hamstring',
      'pantorrilla',
      'calf',
      'gemelo',
    ])) {
      return 'Piernas';
    }
    if (_containsAny(m, ['gluteo', 'glúteo', 'glute'])) return 'Glúteos';
    if (_containsAny(m, ['abdominal', 'abs', 'core', 'oblicuo'])) return 'Abdominales';
    if (_containsAny(m, ['antebrazo', 'forearm'])) return 'Antebrazos';

    return null;
  }

  static String? _mapCategoryToRecoveryGroup(String category) {
    final c = _normalize(category);
    if (_containsAny(c, ['pecho', 'chest'])) return 'Pecho';
    if (_containsAny(c, ['espalda', 'back'])) return 'Espalda';
    if (_containsAny(c, ['hombro', 'shoulder'])) return 'Hombros';
    if (_containsAny(c, ['pierna', 'leg', 'pantorrilla', 'calf'])) return 'Piernas';
    if (_containsAny(c, ['gluteo', 'glúteo', 'glute'])) return 'Glúteos';
    if (_containsAny(c, ['abdominal', 'abs'])) return 'Abdominales';
    if (_containsAny(c, ['brazo', 'arm'])) return null;
    if (_containsAny(c, ['cardio'])) return null;
    return null;
  }

  static List<String> fromExerciseName(String exerciseName) {
    final name = _normalize(exerciseName);
    if (name.isEmpty) return [];

    final muscles = <String>{};

    if (_isTricepsExercise(name)) muscles.add('Tríceps');
    if (_isBicepsExercise(name)) muscles.add('Bíceps');
    if (_isShoulderExercise(name)) muscles.add('Hombros');
    if (_isChestExercise(name)) muscles.add('Pecho');
    _applyPressHeuristics(name, muscles);
    if (_isBackExercise(name)) muscles.add('Espalda');
    if (_isLegExercise(name)) muscles.add('Piernas');
    if (_isGluteExercise(name)) muscles.add('Glúteos');
    if (_isCoreExercise(name)) muscles.add('Abdominales');
    if (_isForearmExercise(name)) muscles.add('Antebrazos');

    return muscles.toList();
  }

  static bool _isTricepsExercise(String name) {
    return _hasAny(name, [
      'tricep',
      'triceps',
      'trícep',
      'pushdown',
      'push down',
      'skull crusher',
      'skull',
      'patada de tricep',
      'kickback',
      'extension de tricep',
      'extensión de tríceps',
    ]);
  }

  static bool _isBicepsExercise(String name) {
    return _hasAny(name, ['curl', 'bicep', 'bícep', 'martillo', 'hammer curl']);
  }

  static bool _isShoulderExercise(String name) {
    if (_hasPhrase(name, 'face pull')) return true;
    if (_hasWord(name, 'lateral') || _hasWord(name, 'laterales')) {
      return !_hasWord(name, 'pulldown');
    }
    return _hasAny(name, [
      'hombro',
      'shoulder',
      'lateral raise',
      'elevacion lateral',
      'elevaciones laterales',
      'front raise',
      'elevacion frontal',
      'elevación frontal',
      'arnold',
      'militar',
      'overhead press',
      'press militar',
    ]);
  }

  static bool _isChestExercise(String name) {
    if (_isBackPullToChest(name)) return false;

    return _hasAny(name, [
      'pecho',
      'chest',
      'bench press',
      'bench',
      'banca',
      'pectoral',
      'apertura',
      'aperturas',
      'fly',
      'push up',
      'push-up',
      'flexion',
      'flexión',
      'fondos en paralela',
      'parallel bar dip',
      'cable crossover',
      'crossover',
    ]) ||
        (_hasWord(name, 'dip') && !_hasPhrase(name, 'hip dip'));
  }

  static void _applyPressHeuristics(String name, Set<String> muscles) {
    if (!_hasWord(name, 'press') && !_hasPhrase(name, 'press de') && !_hasPhrase(name, 'press con')) {
      return;
    }
    if (_hasAny(name, ['pierna', 'leg', 'prensa de pierna', 'leg press'])) return;

    if (_hasAny(name, ['militar', 'hombro', 'shoulder', 'overhead', 'arnold'])) {
      muscles.add('Hombros');
      muscles.add('Tríceps');
      return;
    }

    if (_hasAny(name, ['inclinado', 'declinado', 'banca', 'bench', 'pecho', 'chest'])) {
      muscles.add('Pecho');
      muscles.add('Tríceps');
      if (name.contains('inclinado') || name.contains('incline')) {
        muscles.add('Hombros');
      }
      return;
    }

    if (!muscles.contains('Pecho') && !muscles.contains('Hombros')) {
      muscles.add('Pecho');
      muscles.add('Tríceps');
    }
  }

  static bool _isBackExercise(String name) {
    if (_hasPhrase(name, 'back squat') || _hasPhrase(name, 'sentadilla trasera')) {
      return false;
    }

    if (_isBackPullToChest(name)) return true;

    if (_hasAny(name, [
      'espalda',
      'remo',
      'dominada',
      'dominadas',
      'pull-up',
      'pull up',
      'pullup',
      'chin-up',
      'chin up',
      'peso muerto',
      'deadlift',
      'pullover',
      'pull over',
      'shrug',
      'encogimiento',
    ])) {
      return true;
    }

    if (_hasPhrase(name, 'face pull')) return true;

    if (_hasWord(name, 'row') && !_hasWord(name, 'narrow') && !_hasWord(name, 'barbell bench')) {
      return true;
    }

    if (_hasWord(name, 'pull') &&
        !_hasPhrase(name, 'push') &&
        !_hasWord(name, 'pullover') &&
        (_hasPhrase(name, 'pull down') ||
            _hasWord(name, 'pulldown') ||
            _hasWord(name, 'pullup') ||
            _hasPhrase(name, 'pull up'))) {
      return true;
    }

    if (_hasWord(name, 'lat') || _hasWord(name, 'lats')) {
      if (_hasWord(name, 'lateral')) return false;
      if (_hasWord(name, 'plate') && !_hasWord(name, 'latissimus')) return false;
      return true;
    }

    if (_hasWord(name, 'back')) {
      return !_hasPhrase(name, 'back squat') && !_hasPhrase(name, 'feedback');
    }

    if (_hasWord(name, 'jalon') || _hasWord(name, 'jalón')) return true;

    return false;
  }

  static bool _isBackPullToChest(String name) {
    return _hasAny(name, [
      'jalon al pecho',
      'jalón al pecho',
      'lat pulldown',
      'pulldown al pecho',
      'pulldown to chest',
    ]);
  }

  static bool _isLegExercise(String name) {
    if (_hasAny(name, ['prensa de hombro', 'militar', 'overhead'])) return false;

    return _hasAny(name, [
      'sentadilla',
      'squat',
      'pierna',
      'leg press',
      'extension de cuadriceps',
      'extensión de cuádriceps',
      'curl femoral',
      'zancada',
      'lunge',
      'prensa de pierna',
      'leg extension',
      'leg curl',
      'calf raise',
      'gemelo',
      'pantorrilla',
    ]) ||
        (_hasWord(name, 'prensa') && !_hasPhrase(name, 'prensa de hombro'));
  }

  static bool _isGluteExercise(String name) {
    return _hasAny(name, ['gluteo', 'glúteo', 'hip thrust', 'puente de gluteo', 'glute bridge']);
  }

  static bool _isCoreExercise(String name) {
    return _hasAny(name, ['abdominal', 'core', 'crunch', 'plancha', 'plank']);
  }

  static bool _isForearmExercise(String name) {
    return _hasAny(name, ['antebrazo', 'forearm', 'wrist curl']);
  }

  static bool _hasWord(String name, String word) {
    final w = _normalize(word);
    if (w.isEmpty) return false;
    return RegExp(r'(^|[^a-z])' + RegExp.escape(w) + r'([^a-z]|$)').hasMatch(name);
  }

  static bool _hasPhrase(String name, String phrase) => name.contains(_normalize(phrase));

  static bool _hasAny(String name, List<String> terms) {
    for (final term in terms) {
      final t = _normalize(term);
      if (t.contains(' ')) {
        if (name.contains(t)) return true;
      } else if (_hasWord(name, t)) {
        return true;
      }
    }
    return false;
  }

  static bool _containsAny(String value, List<String> terms) {
    for (final term in terms) {
      if (value.contains(_normalize(term))) return true;
    }
    return false;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }
}
