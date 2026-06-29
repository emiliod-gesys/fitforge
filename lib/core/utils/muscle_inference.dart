import '../../data/supplemental_exercises.dart';
import '../../models/exercise.dart';
import 'exercise_logging_resolver.dart';

/// Infiere grupos musculares para recuperación a partir del catálogo o del nombre.
abstract final class MuscleInference {
  /// Resuelve músculos: catálogo (wger/suplementarios) primero, heurística como respaldo.
  static List<String> resolve({
    required String exerciseName,
    String? exerciseId,
    List<Exercise>? catalog,
  }) {
    final inferred = fromExerciseName(exerciseName);

    final fromCatalog = _lookupCatalog(
      exerciseName: exerciseName,
      exerciseId: exerciseId,
      catalog: catalog,
    );
    if (fromCatalog != null) {
      return _uniqueGroups(
        _mergeCatalogWithInferred(exerciseName, fromCatalog, inferred),
      );
    }

    for (final extra in SupplementalExercises.all()) {
      if (_matchesExercise(extra, exerciseId: exerciseId, exerciseName: exerciseName)) {
        return _uniqueGroups(
          _mergeCatalogWithInferred(
            exerciseName,
            fromExerciseMuscles(extra.muscles, extra.category),
            inferred,
          ),
        );
      }
    }

    return inferred;
  }

  static List<String> _uniqueGroups(Iterable<String> groups) {
    return groups.toSet().toList();
  }

  static List<String> _mergeCatalogWithInferred(
    String exerciseName,
    List<String> catalog,
    List<String> inferred,
  ) {
    final merged = <String>{...catalog};
    final catalogBiceps = catalog.contains('Bíceps');
    final catalogTriceps = catalog.contains('Tríceps');

    for (final group in inferred) {
      if (catalogTriceps && !catalogBiceps && group == 'Bíceps') continue;
      if (catalogBiceps && !catalogTriceps && group == 'Tríceps') continue;
      merged.add(group);
    }

    return _resolveArmAntagonistConflictByName(exerciseName, merged);
  }

  static List<String> _resolveArmAntagonistConflictByName(
    String name,
    Set<String> muscles,
  ) {
    if (!muscles.contains('Bíceps') || !muscles.contains('Tríceps')) {
      return muscles.toList();
    }

    final n = _normalize(name);
    final tricepsNamed = _hasAny(n, ['tricep', 'triceps', 'trícep', 'tríceps']);
    final bicepsNamed = _hasAny(n, ['bicep', 'biceps', 'bícep', 'bíceps']);

    if (tricepsNamed && !bicepsNamed) {
      muscles.remove('Bíceps');
    } else if (bicepsNamed && !tricepsNamed) {
      muscles.remove('Tríceps');
    } else if (_hasWord(n, 'curl') && !tricepsNamed) {
      muscles.remove('Tríceps');
    } else if (tricepsNamed) {
      muscles.remove('Bíceps');
    } else {
      muscles.remove('Tríceps');
    }

    return muscles.toList();
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

  /// Indica si un ejercicio pertenece a un grupo muscular de la app (p. ej. Glúteos).
  static bool matchesMuscleGroup({
    required Exercise exercise,
    required String muscleGroup,
  }) {
    if (muscleGroup == 'Cardio') {
      return exercise.isCardio ||
          exercise.category.toLowerCase().contains('cardio') ||
          ExerciseLoggingResolver.inferFromName(exercise.name);
    }

    if (muscleGroup == 'Abdominales') {
      final categoryGroup = _mapCategoryToRecoveryGroup(exercise.category);
      if (categoryGroup == 'Abdominales') return true;

      if (exercise.muscles.isNotEmpty) {
        final primaryGroup = _mapToRecoveryGroup(exercise.muscles.first);
        if (primaryGroup == 'Abdominales') return true;
      }

      return _isDedicatedAbsExerciseName(exercise.name);
    }

    final fromMeta = fromExerciseMuscles(exercise.muscles, exercise.category);
    if (fromMeta.contains(muscleGroup)) return true;
    return fromExerciseName(exercise.name).contains(muscleGroup);
  }

  static String? _mapToRecoveryGroup(String muscle) {
    final m = _normalize(muscle);
    if (m.isEmpty) return null;

    // Nombres latinos de pierna/pantorrilla (p. ej. bíceps femoral, tríceps sural).
    if (_containsAny(m, ['biceps femoris', 'triceps surae'])) return 'Piernas';
    if (_hasMuscleToken(m, 'surae')) return 'Piernas';
    if (_hasMuscleToken(m, 'femoris') && _hasMuscleToken(m, 'biceps')) return 'Piernas';

    if (_hasMuscleToken(m, 'triceps') || _hasMuscleToken(m, 'tríceps')) return 'Tríceps';
    if (_hasMuscleToken(m, 'biceps') ||
        _hasMuscleToken(m, 'bíceps') ||
        _hasMuscleToken(m, 'bicep') ||
        _hasMuscleToken(m, 'brachialis')) {
      return 'Bíceps';
    }
    if (_containsAny(m, ['pecho', 'chest', 'pectoral', 'dorsales', 'lats'])) {
      if (_containsAny(m, ['dorsales', 'lats', 'espalda', 'back'])) return 'Espalda';
      return 'Pecho';
    }
    if (_containsAny(m, ['espalda', 'back', 'latissimus', 'dorsal', 'trapecio', 'romboid', 'romboides'])) {
      return 'Espalda';
    }
    if (_containsAny(m, ['hombro', 'shoulder', 'deltoid', 'deltoides'])) return 'Hombros';
    if (_containsAny(m, [
      'pierna',
      'leg',
      'cuadriceps',
      'cuádriceps',
      'quadriceps',
      'quads',
      'isquio',
      'hamstring',
      'hamstrings',
      'pantorrilla',
      'calf',
      'gemelo',
      'gastrocnemius',
      'gastrocnemio',
      'soleus',
      'soleo',
      'sóleo',
      'adductor',
    ])) {
      return 'Piernas';
    }
    if (_containsAny(m, ['gluteo', 'glúteo', 'glute'])) return 'Glúteos';
    if (_containsAny(m, ['abdominal', 'abs', 'oblicuo'])) return 'Abdominales';
    if (_containsAny(m, ['cardio'])) return 'Cardio';
    if (_containsAny(m, [
      'antebrazo',
      'forearm',
      'brachioradialis',
      'flexor carpi',
      'extensor carpi',
      'wrist',
      'muneca',
    ])) {
      return 'Antebrazos';
    }

    return null;
  }

  static String? _mapCategoryToRecoveryGroup(String category) {
    final c = _normalize(category);
    if (_containsAny(c, ['pecho', 'chest'])) return 'Pecho';
    if (_containsAny(c, ['espalda', 'back'])) return 'Espalda';
    if (_containsAny(c, ['hombro', 'shoulder'])) return 'Hombros';
    if (_containsAny(c, ['pierna', 'leg', 'pantorrilla', 'calf', 'gemelo', 'calves'])) return 'Piernas';
    if (_containsAny(c, ['gluteo', 'glúteo', 'glute'])) return 'Glúteos';
    if (_containsAny(c, ['abdominal', 'abs'])) return 'Abdominales';
    if (_containsAny(c, ['biceps', 'bíceps', 'bicep'])) return 'Bíceps';
    if (_containsAny(c, ['triceps', 'tríceps'])) return 'Tríceps';
    if (_containsAny(c, ['antebrazo', 'forearm'])) return 'Antebrazos';
    if (_containsAny(c, ['cardio'])) return 'Cardio';
    if (_containsAny(c, ['brazo', 'arm'])) return null;
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

    return _resolveArmAntagonistConflictByName(exerciseName, muscles);
  }

  static bool _isTricepsExercise(String name) {
    if (_hasAny(name, ['gluteo', 'glúteo', 'gluteo', 'glute', 'cadera', 'hip']) &&
        _hasWord(name, 'kickback')) {
      return false;
    }

    return _hasAny(name, [
      'tricep',
      'triceps',
      'trícep',
      'tríceps',
      'pushdown',
      'push down',
      'skull crusher',
      'rompecraneos',
      'rompecráneos',
      'patada de tricep',
      'extension de tricep',
      'extensión de tríceps',
      'fondos de tricep',
    ]) ||
        (_hasWord(name, 'skull') && _hasWord(name, 'crusher')) ||
        (_hasWord(name, 'kickback') &&
            _hasAny(name, ['tricep', 'triceps', 'trícep', 'tríceps']));
  }

  static bool _isBicepsExercise(String name) {
    if (_isLegCurl(name)) return false;
    if (_hasAny(name, ['tricep', 'triceps', 'trícep', 'tríceps'])) return false;

    return _hasAny(name, [
      'curl',
      'bicep',
      'bícep',
      'martillo',
      'hammer curl',
      'predicador',
      'preacher',
      'scott',
      'concentrado',
      'concentration',
      'spider curl',
      'drag curl',
      'curl de biceps',
      'curl de bíceps',
      'chin-up',
      'chin up',
      'chinup',
      'dominada supina',
    ]);
  }

  static bool _isLegCurl(String name) {
    return _hasAny(name, [
      'leg curl',
      'curl femoral',
      'curl de pierna',
      'hamstring curl',
      'femoral sentado',
      'femoral acostado',
    ]);
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
    if (_isChestSupportedBackExercise(name)) return false;

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
    if (_isChestSupportedBackExercise(name)) return;
    if (!_hasWord(name, 'press') && !_hasPhrase(name, 'press de') && !_hasPhrase(name, 'press con')) {
      return;
    }
    if (_hasAny(name, ['pierna', 'leg', 'prensa de pierna', 'leg press'])) return;
    if (_hasWord(name, 'curl') &&
        _hasAny(name, ['bicep', 'biceps', 'bícep', 'bíceps', 'martillo', 'hammer'])) {
      return;
    }

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

  /// "Chest supported row" apoya el pecho en el banco, pero es ejercicio de espalda.
  static bool _isChestSupportedBackExercise(String name) {
    if (_hasAny(name, ['row', 'remo']) &&
        _hasAny(name, [
          'chest supported',
          'pecho apoyado',
          'supported row',
          'remo con pecho apoyado',
          'remo con mancuernas pecho apoyado',
          'pec deck invertido',
          'reverse pec deck',
        ])) {
      return true;
    }
    return _hasPhrase(name, 'chest supported') || _hasPhrase(name, 'pecho apoyado');
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
    return _hasAny(name, [
      'gluteo',
      'glúteo',
      'hip thrust',
      'empuje de cadera',
      'puente de gluteo',
      'glute bridge',
      'belt squat',
      'hack squat',
      'romanian deadlift',
      'peso muerto rumano',
      'rdl',
      'reverse hyper',
      'glute drive',
      'cable kickback',
      'kickback en polea',
      'good morning',
      'buenos dias',
      'bulgarian split',
      'split squat',
      'sentadilla bulgara',
      'step up',
      'step-up',
      'subida al cajon',
    ]) ||
        (_hasWord(name, 'lunge') || _hasWord(name, 'zancada')) ||
        (_hasWord(name, 'kickback') &&
            _hasAny(name, ['glute', 'gluteo', 'glúteo', 'cadera', 'hip', 'polea', 'cable']));
  }

  static bool _isDedicatedAbsExerciseName(String name) {
    final n = _normalize(name);
    if (_isLegExercise(n) || _isChestExercise(n) || _isBackExercise(n)) return false;

    return _hasAny(n, [
      'crunch',
      'plancha',
      'plank',
      'leg raise',
      'elevacion de piernas',
      'elevación de piernas',
      'russian twist',
      'giros rusos',
      'dead bug',
      'rollout',
      'rollerout',
      'ab wheel',
      'rueda abdominal',
      'mountain climber',
      'escalador',
      'sit-up',
      'sit up',
      'situp',
      'bicycle crunch',
      'crunch bicicleta',
      'abdominal',
      'v-up',
      'v up',
      'leñador',
      'wood chop',
      'woodchop',
      'flexion lateral',
      'side bend',
      'silla romana',
      'captain',
    ]);
  }

  static bool _isCoreExercise(String name) {
    return _hasAny(name, ['abdominal', 'core', 'crunch', 'plancha', 'plank']);
  }

  static bool _isForearmExercise(String name) {
    if (_hasAny(name, ['leg extension', 'extension de cuadriceps', 'extensión de cuádriceps'])) {
      return false;
    }

    return _hasAny(name, [
      'antebrazo',
      'forearm',
      'wrist curl',
      'curl de muneca',
      'curl de muñeca',
      'muñeca',
      'muneca',
      'hand grip',
      'agarre de mano',
      'pinch',
      'pinza',
      'farmer walk',
      'farmer s walk',
      'caminata del granjero',
      'wrist roller',
      'extensor de muneca',
      'extensor de muñeca',
      'flexor de muneca',
      'flexor de muñeca',
      'reverse curl',
      'curl inverso',
      'curl de predicador inverso',
    ]);
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

  static bool _hasMuscleToken(String value, String token) {
    final t = _normalize(token);
    if (t.isEmpty) return false;
    return RegExp(r'(^|[^a-z])' + RegExp.escape(t) + r'([^a-z]|$)').hasMatch(value);
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
