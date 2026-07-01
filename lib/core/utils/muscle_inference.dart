import '../../data/supplemental_exercises.dart';
import '../../models/exercise.dart';
import 'exercise_logging_resolver.dart';

/// Infiere grupos musculares para recuperación a partir del catálogo o del nombre.
abstract final class MuscleInference {
  /// Peso de fatiga para músculos secundarios (no estabilizadores).
  static const double secondaryImpactWeight = 0.35;

  /// Impacto mínimo para mostrar el grupo en listas y maniquí.
  static const double minVisibleImpact = 0.25;

  /// Resuelve músculos con impacto relevante en recuperación.
  static List<String> resolve({
    required String exerciseName,
    String? exerciseId,
    List<Exercise>? catalog,
  }) {
    return resolveImpacts(
      exerciseName: exerciseName,
      exerciseId: exerciseId,
      catalog: catalog,
    )
        .entries
        .where((entry) => entry.value >= minVisibleImpact)
        .map((entry) => entry.key)
        .toList();
  }

  /// Grupos musculares con peso de fatiga (1.0 = primario, ~0.35 = secundario).
  static Map<String, double> resolveImpacts({
    required String exerciseName,
    String? exerciseId,
    List<Exercise>? catalog,
  }) {
    final fromCatalog = _findCatalogExercise(
      exerciseName: exerciseName,
      exerciseId: exerciseId,
      catalog: catalog,
    );
    if (fromCatalog != null) {
      return _finalizeImpacts(
        exerciseName,
        impactsFromExerciseMuscles(fromCatalog.muscles, fromCatalog.category),
      );
    }

    for (final extra in SupplementalExercises.all()) {
      if (_matchesExercise(extra, exerciseId: exerciseId, exerciseName: exerciseName)) {
        return _finalizeImpacts(
          exerciseName,
          impactsFromExerciseMuscles(extra.muscles, extra.category),
        );
      }
    }

    return _finalizeImpacts(
      exerciseName,
      _impactsFromExerciseName(exerciseName),
    );
  }

  static Map<String, double> _impactsFromExerciseName(String exerciseName) {
    final impacts = <String, double>{};
    for (final group in fromExerciseName(exerciseName)) {
      impacts[group] = 1.0;
    }
    return impacts;
  }

  static Map<String, double> _finalizeImpacts(
    String exerciseName,
    Map<String, double> impacts,
  ) {
    return _resolveArmAntagonistImpactsByName(exerciseName, impacts);
  }

  static Map<String, double> _resolveArmAntagonistImpactsByName(
    String name,
    Map<String, double> impacts,
  ) {
    if (!impacts.containsKey('Bíceps') || !impacts.containsKey('Tríceps')) {
      return impacts;
    }

    final muscles = impacts.keys.toSet();
    final resolved = _resolveArmAntagonistConflictByName(name, muscles);
    final next = <String, double>{};
    for (final group in resolved) {
      next[group] = impacts[group] ?? 1.0;
    }
    return next;
  }

  static List<String> _resolveArmAntagonistConflictByName(
    String name,
    Set<String> muscles,
  ) {
    if (!muscles.contains('Bíceps') || !muscles.contains('Tríceps')) {
      return muscles.toList();
    }

    final n = _normalize(name);
    if (_isMuscleUpExercise(n)) {
      return muscles.toList();
    }

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

  static Exercise? _findCatalogExercise({
    required String exerciseName,
    String? exerciseId,
    List<Exercise>? catalog,
  }) {
    if (catalog == null || catalog.isEmpty) return null;

    for (final exercise in catalog) {
      if (_matchesExercise(exercise, exerciseId: exerciseId, exerciseName: exerciseName)) {
        return exercise;
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

  /// Mapea músculos del catálogo a grupos con peso (primario vs secundario).
  static Map<String, double> impactsFromExerciseMuscles(
    List<String> muscles,
    String category,
  ) {
    final impacts = <String, double>{};
    if (muscles.isEmpty) {
      final fromCategory = _mapCategoryToRecoveryGroup(category);
      if (fromCategory != null) impacts[fromCategory] = 1.0;
      return impacts;
    }

    for (var i = 0; i < muscles.length; i++) {
      final group = _mapToRecoveryGroup(muscles[i]);
      if (group == null) continue;
      final weight = i == 0 ? 1.0 : secondaryImpactWeight;
      impacts[group] = _maxImpact(impacts[group], weight);
    }

    if (impacts.isEmpty) {
      final fromCategory = _mapCategoryToRecoveryGroup(category);
      if (fromCategory != null) impacts[fromCategory] = 1.0;
    }

    return impacts;
  }

  static double _maxImpact(double? current, double next) {
    if (current == null) return next;
    return current > next ? current : next;
  }

  /// Mapea músculos del catálogo a los grupos de recuperación de la app.
  static List<String> fromExerciseMuscles(List<String> muscles, String category) {
    return impactsFromExerciseMuscles(muscles, category)
        .entries
        .where((entry) => entry.value >= minVisibleImpact)
        .map((entry) => entry.key)
        .toList();
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
    if (_isStabilizerMuscle(m)) return null;

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
    if (_isBurpeeExercise(name)) {
      muscles.add('Piernas');
      muscles.add('Pecho');
      muscles.add('Abdominales');
    }
    if (_isBoxJumpExercise(name)) {
      muscles.add('Piernas');
      muscles.add('Glúteos');
    }
    if (_isBoxStepOverExercise(name)) {
      muscles.add('Piernas');
      muscles.add('Glúteos');
    }
    if (_isWallBallExercise(name)) {
      muscles.add('Piernas');
      muscles.add('Hombros');
      muscles.add('Glúteos');
    }
    if (_isThrusterExercise(name)) {
      muscles.add('Piernas');
      muscles.add('Hombros');
      muscles.add('Glúteos');
    }
    if (_isPowerCleanExercise(name)) {
      muscles.add('Piernas');
      muscles.add('Espalda');
      muscles.add('Glúteos');
    }
    if (_isCleanAndJerkExercise(name)) {
      muscles.add('Piernas');
      muscles.add('Espalda');
      muscles.add('Hombros');
      muscles.add('Glúteos');
    }
    if (_isPowerSnatchExercise(name)) {
      muscles.add('Piernas');
      muscles.add('Espalda');
      muscles.add('Hombros');
      muscles.add('Glúteos');
    }
    if (_isSnatchDeadliftExercise(name)) {
      muscles.add('Espalda');
      muscles.add('Piernas');
      muscles.add('Glúteos');
    }
    if (_isSumoDeadliftExercise(name)) {
      muscles.add('Piernas');
      muscles.add('Glúteos');
    }
    if (_isOverheadSquatExercise(name)) {
      muscles.add('Piernas');
      muscles.add('Hombros');
      muscles.add('Glúteos');
      muscles.add('Abdominales');
    }
    if (_isKettlebellSwingExercise(name)) {
      muscles.add('Glúteos');
      muscles.add('Piernas');
      muscles.add('Abdominales');
    }
    if (_isKettlebellSnatchExercise(name)) {
      muscles.add('Hombros');
      muscles.add('Glúteos');
      muscles.add('Piernas');
      muscles.add('Espalda');
    }
    if (_isKettlebellCleanAndPressExercise(name)) {
      muscles.add('Hombros');
      muscles.add('Piernas');
      muscles.add('Glúteos');
    }
    if (_isFarmersWalkExercise(name)) {
      muscles.add('Piernas');
      muscles.add('Glúteos');
      muscles.add('Antebrazos');
      muscles.add('Abdominales');
    }
    if (_isKippingPullUpExercise(name)) {
      muscles.add('Espalda');
      muscles.add('Bíceps');
      muscles.add('Abdominales');
    }
    if (_isMuscleUpExercise(name)) {
      muscles.add('Espalda');
      muscles.add('Bíceps');
      muscles.add('Tríceps');
      muscles.add('Hombros');
      muscles.add('Abdominales');
    }
    if (_isBarPulloverExercise(name)) {
      muscles.add('Espalda');
      muscles.add('Bíceps');
      muscles.add('Abdominales');
    }
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

    if (_isSumoDeadliftExercise(name)) return false;

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

    if (_hasWord(name, 'jalon')) {
      if (_hasAny(name, ['tricep', 'triceps', 'pushdown'])) {
        return false;
      }
      return true;
    }

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

  static bool _isBarPulloverExercise(String name) {
    if (_hasPhrase(name, 'bar pullover') ||
        _hasPhrase(name, 'bar pull over') ||
        _hasPhrase(name, 'pullover en barra') ||
        _hasPhrase(name, 'pull over en barra')) {
      return true;
    }
    if (_hasAny(name, [
      'dumbbell',
      'mancuerna',
      'barbell',
      'cable',
      'polea',
      'machine',
      'maquina',
      'lever',
      'ez bar',
    ])) {
      return false;
    }
    return _hasPhrase(name, 'pull over') ||
        (_hasWord(name, 'pullover') && _hasAny(name, ['barra', 'bar', 'gymnastic', 'calistenia']));
  }

  static bool _isMuscleUpExercise(String name) {
    return _hasPhrase(name, 'muscle up') ||
        _hasPhrase(name, 'muscle-up') ||
        _hasWord(name, 'muscleup');
  }

  static bool _isKippingPullUpExercise(String name) {
    return _hasPhrase(name, 'kipping pull up') ||
        _hasPhrase(name, 'kipping pull-up') ||
        _hasPhrase(name, 'dominada kipping') ||
        _hasPhrase(name, 'pull up kipping') ||
        _hasPhrase(name, 'kipping pu');
  }

  static bool _isFarmersWalkExercise(String name) {
    return _hasPhrase(name, 'farmers walk') ||
        _hasPhrase(name, 'farmer walk') ||
        _hasPhrase(name, "farmer's walk") ||
        _hasPhrase(name, 'farmer carry') ||
        _hasPhrase(name, 'caminata del granjero') ||
        _hasPhrase(name, 'caminata de granjero');
  }

  static bool _isKettlebellCleanAndPressExercise(String name) {
    return _hasPhrase(name, 'kettlebell clean and press') ||
        _hasPhrase(name, 'clean and press con kettlebell') ||
        _hasPhrase(name, 'cargada y press con kettlebell') ||
        _hasPhrase(name, 'kb clean and press');
  }

  static bool _isKettlebellSnatchExercise(String name) {
    return _hasPhrase(name, 'kettlebell snatch') ||
        _hasPhrase(name, 'snatch con kettlebell') ||
        _hasPhrase(name, 'kb snatch') ||
        _hasPhrase(name, 'arrancada con kettlebell');
  }

  static bool _isKettlebellSwingExercise(String name) {
    return _hasPhrase(name, 'kettlebell swing') ||
        _hasPhrase(name, 'swing con kettlebell') ||
        _hasPhrase(name, 'kb swing') ||
        _hasPhrase(name, 'swing ruso');
  }

  static bool _isOverheadSquatExercise(String name) {
    if (_hasPhrase(name, 'front squat')) return false;
    return _hasPhrase(name, 'overhead squat') ||
        _hasPhrase(name, 'sentadilla overhead') ||
        _hasWord(name, 'ohs');
  }

  static bool _isSnatchDeadliftExercise(String name) {
    return _hasPhrase(name, 'snatch deadlift') ||
        _hasPhrase(name, 'snatch dl') ||
        _hasPhrase(name, 'peso muerto snatch') ||
        _hasPhrase(name, 'snatch-grip deadlift');
  }

  static bool _isSumoDeadliftExercise(String name) {
    return _hasPhrase(name, 'sumo deadlift') ||
        _hasPhrase(name, 'peso muerto sumo') ||
        _hasPhrase(name, 'deadlift sumo');
  }

  static bool _isPowerSnatchExercise(String name) {
    if (_hasPhrase(name, 'snatch pull')) return false;
    return _hasPhrase(name, 'power snatch') ||
        _hasPhrase(name, 'arrancada de potencia') ||
        _hasPhrase(name, 'snatch de potencia');
  }

  static bool _isCleanAndJerkExercise(String name) {
    return _hasPhrase(name, 'clean and jerk') ||
        _hasPhrase(name, 'clean & jerk') ||
        _hasPhrase(name, 'cargada y envion') ||
        _hasPhrase(name, 'cargada y envión');
  }

  static bool _isPowerCleanExercise(String name) {
    return _hasPhrase(name, 'hang power clean') ||
        _hasPhrase(name, 'cargada colgada de potencia') ||
        _hasPhrase(name, 'cargada hang') ||
        _hasPhrase(name, 'power clean') ||
        _hasPhrase(name, 'cargada de potencia');
  }

  static bool _isThrusterExercise(String name) {
    return _hasWord(name, 'thruster');
  }

  static bool _isWallBallExercise(String name) {
    return _hasPhrase(name, 'wall ball') ||
        _hasPhrase(name, 'wallball') ||
        _hasPhrase(name, 'lanzamiento al muro');
  }

  static bool _isBoxStepOverExercise(String name) {
    return _hasPhrase(name, 'step over') ||
        _hasPhrase(name, 'step-over') ||
        _hasPhrase(name, 'stepover') ||
        _hasPhrase(name, 'paso sobre el cajon') ||
        _hasPhrase(name, 'step over en cajon');
  }

  static bool _isBoxJumpExercise(String name) {
    return _hasPhrase(name, 'box jump') ||
        _hasPhrase(name, 'salto al cajon') ||
        _hasPhrase(name, 'salto al box');
  }

  static bool _isBurpeeExercise(String name) {
    return _hasWord(name, 'burpee');
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

  static bool _isStabilizerMuscle(String normalizedMuscle) {
    return normalizedMuscle.contains('stabiliz');
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
