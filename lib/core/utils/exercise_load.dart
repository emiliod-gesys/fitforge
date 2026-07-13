import '../../models/exercise.dart';
import '../../models/exercise_logging.dart';
import '../../models/workout.dart';

/// Cómo interpretar el peso registrado en una serie (total vs. por brazo).
abstract final class ExerciseLoad {
  static Exercise? _findInCatalog(String exerciseId, Iterable<Exercise> catalog) {
    for (final exercise in catalog) {
      if (exercise.id == exerciseId) return exercise;
    }
    return null;
  }

  /// Override explícito desde catálogo o ejercicio personalizado (`null` = inferir del nombre).
  static bool? perArmWeightOverride(Exercise? exercise) {
    if (exercise == null) return null;
    if (exercise.isBundled || exercise.isUserCustom) return exercise.perArmWeight;
    return null;
  }

  static bool? perArmWeightForExerciseId(String exerciseId, Iterable<Exercise> catalog) {
    return perArmWeightOverride(_findInCatalog(exerciseId, catalog));
  }

  static bool? unilateralForExerciseId(String exerciseId, Iterable<Exercise> catalog) {
    final exercise = _findInCatalog(exerciseId, catalog);
    if (exercise == null) return null;
    if (exercise.isBundled || exercise.isUserCustom) return exercise.unilateral;
    return null;
  }

  static bool? weightOptionalForExerciseId(
    String exerciseId,
    Iterable<Exercise> catalog, {
    String? exerciseName,
  }) {
    final exercise = _findInCatalog(exerciseId, catalog);
    if (exercise != null && (exercise.isBundled || exercise.isUserCustom)) {
      return exercise.weightOptional || exercise.loadMode.weightOptional;
    }
    final name = exerciseName ?? exercise?.name ?? exerciseId;
    if (_inferBodyweightByName(name)) return true;
    return null;
  }

  static ExerciseLoadMode? loadModeForExerciseId(
    String exerciseId,
    Iterable<Exercise> catalog, {
    String? exerciseName,
  }) {
    final exercise = _findInCatalog(exerciseId, catalog);
    if (exercise != null && (exercise.isBundled || exercise.isUserCustom)) {
      return exercise.loadMode;
    }
    return _inferLoadModeByName(exerciseName ?? exercise?.name ?? exerciseId);
  }

  /// Ejercicios donde el usuario puede alternar peso por brazo vs. conjunto en la sesión.
  static bool supportsPerArmToggle(
    String exerciseId,
    Iterable<Exercise> catalog,
    String exerciseName,
  ) {
    final exercise = _findInCatalog(exerciseId, catalog);

    if (exercise != null) {
      if (exercise.isCardio ||
          exercise.loadMode == ExerciseLoadMode.cardioMachine ||
          exercise.loadMode == ExerciseLoadMode.cardioOutdoor) {
        return false;
      }
    }

    if (exercise != null && (exercise.isBundled || exercise.isUserCustom)) {
      if (exercise.loadMode == ExerciseLoadMode.machineStack ||
          exercise.loadMode == ExerciseLoadMode.dualLoad) {
        return true;
      }
      if (exercise.perArmWeight) return true;
    }

    if (exercise != null && exercise.equipment.any(_isMachineEquipment)) {
      return true;
    }

    if (_inferMachineByName(exerciseName)) return true;

    final n = _normalize(exerciseName);
    if (_usesDumbbell(n) && !_singleDumbbellBothHands(n)) return true;
    if (_isPerArmCable(n)) return true;
    return false;
  }

  static bool resolvePerArmWeight({
    required String exerciseId,
    required Iterable<Exercise> catalog,
    required String exerciseName,
    bool? sessionOverride,
  }) {
    if (sessionOverride != null) return sessionOverride;
    return isPerArmWeight(
      exerciseName,
      perArmWeight: perArmWeightForExerciseId(exerciseId, catalog),
    );
  }

  static bool isLoadedDistance(
    String exerciseId,
    Iterable<Exercise> catalog, {
    String? exerciseName,
  }) {
    final mode = loadModeForExerciseId(
      exerciseId,
      catalog,
      exerciseName: exerciseName,
    );
    if (mode == ExerciseLoadMode.loadedDistance) return true;
    return _inferLoadedDistanceByName(exerciseName ?? exerciseId);
  }

  /// Unidades de volumen: reps normales o metros (1 m = 1 rep de volumen).
  static int volumeUnitsForSet(
    WorkoutSet set, {
    required String exerciseName,
    ExerciseLoadMode? loadMode,
  }) {
    final mode = loadMode ?? _inferLoadModeByName(exerciseName);
    if (mode == ExerciseLoadMode.loadedDistance || _inferLoadedDistanceByName(exerciseName)) {
      final meters = set.distanceMeters;
      if (meters == null || meters <= 0) return 0;
      return meters.round();
    }
    return set.reps;
  }

  static bool isBodyweightLoad(
    String exerciseId,
    Iterable<Exercise> catalog,
    String exerciseName,
  ) {
    final mode = loadModeForExerciseId(
      exerciseId,
      catalog,
      exerciseName: exerciseName,
    );
    if (mode == ExerciseLoadMode.bodyweight) return true;
    if (mode == ExerciseLoadMode.assistedBodyweight) return true;
    return _inferBodyweightByName(exerciseName);
  }

  /// Peso adicional registrado (0 si vacío en ejercicios de peso corporal).
  static double additionalWeightKg(WorkoutSet set) {
    return set.weight ?? 0;
  }

  /// Peso efectivo para volumen y récords: corporal + adicional en bodyweight.
  static double? effectiveWeightKg(
    WorkoutSet set, {
    required String exerciseName,
    ExerciseLoadMode? loadMode,
    double? bodyWeightKg,
  }) {
    if (set.isCardio) return null;
    if (isAssistedExercise(exerciseName, loadMode: loadMode)) return null;

    final additional = additionalWeightKg(set);
    final mode = loadMode ?? _inferLoadModeByName(exerciseName);

    if (mode == ExerciseLoadMode.bodyweight) {
      final base = (bodyWeightKg ?? 0) * bodyweightFractionForExercise(exerciseName);
      if (base <= 0 && additional <= 0) return null;
      return base + additional;
    }

    if (additional <= 0) return null;
    return additional;
  }

  /// En ejercicios asistidos el peso registrado es contrapeso a favor, no carga levantada.
  static bool isAssistedExercise(
    String exerciseName, {
    ExerciseLoadMode? loadMode,
  }) {
    if (loadMode == ExerciseLoadMode.assistedBodyweight) return true;
    final n = _normalize(exerciseName);
    return n.contains('assisted') || n.contains('asistid');
  }

  /// Muestra la etiqueta «(por brazo)» en la UI de series.
  static bool isPerArmWeight(String exerciseName, {bool? perArmWeight}) {
    if (perArmWeight == true) return true;
    if (perArmWeight == false) return false;

    final n = _normalize(exerciseName);
    if (_singleDumbbellBothHands(n)) return false;
    if (_usesDumbbell(n)) return true;
    if (_isPerArmCable(n)) return true;
    return false;
  }

  /// Multiplicador de volumen respecto al peso registrado por serie.
  static double volumeMultiplier(
    String exerciseName, {
    bool? perArmWeight,
    bool? unilateral,
  }) {
    final n = _normalize(exerciseName);
    if (unilateral == true) return 1;

    if (perArmWeight == true) {
      if (_isUnilateral(n: n)) return 1;
      return 2;
    }
    if (perArmWeight == false) return 1;

    if (!isPerArmWeight(exerciseName)) return 1;
    if (_isUnilateral(n: n)) return 1;
    if (_usesDumbbell(n)) return 2;
    if (_usesCable(n) && _cableBilateralSimultaneous(n)) return 2;
    return 1;
  }

  static double setVolumeKg(
    WorkoutSet set, {
    required String exerciseName,
    bool? perArmWeight,
    bool? unilateral,
    ExerciseLoadMode? loadMode,
    double? bodyWeightKg,
  }) {
    if (set.isCardio) return 0;
    if (isAssistedExercise(exerciseName, loadMode: loadMode)) return 0;

    final effective = effectiveWeightKg(
      set,
      exerciseName: exerciseName,
      loadMode: loadMode,
      bodyWeightKg: bodyWeightKg,
    );
    final units = volumeUnitsForSet(
      set,
      exerciseName: exerciseName,
      loadMode: loadMode,
    );
    if (effective == null || effective <= 0 || !set.completed || units <= 0) return 0;

    return effective *
        units *
        volumeMultiplier(
          exerciseName,
          perArmWeight: perArmWeight,
          unilateral: unilateral,
        );
  }

  static double exerciseTotalVolumeKg(
    WorkoutExercise exercise, {
    required Iterable<Exercise> catalog,
    Map<String, bool>? perArmOverrides,
    double? bodyWeightKg,
  }) {
    final loadMode = loadModeForExerciseId(
      exercise.exerciseId,
      catalog,
      exerciseName: exercise.exerciseName,
    );
    final perArm = resolvePerArmWeight(
      exerciseId: exercise.exerciseId,
      catalog: catalog,
      exerciseName: exercise.exerciseName,
      sessionOverride: perArmOverrides?[exercise.exerciseId],
    );
    final unilateral = unilateralForExerciseId(exercise.exerciseId, catalog);

    return exercise.sets.fold<double>(
      0,
      (sum, set) =>
          sum +
          setVolumeKg(
            set,
            exerciseName: exercise.exerciseName,
            perArmWeight: perArm,
            unilateral: unilateral,
            loadMode: loadMode,
            bodyWeightKg: bodyWeightKg,
          ),
    );
  }

  static String weightLabel(
    String unitLabel,
    String exerciseName, {
    bool? perArmWeight,
    bool? weightOptional,
    ExerciseLoadMode? loadMode,
    String additionalSuffix = '(+ extra)',
    String perArmSuffix = '(por brazo)',
  }) {
    final isBw = weightOptional == true ||
        loadMode == ExerciseLoadMode.bodyweight ||
        loadMode == ExerciseLoadMode.assistedBodyweight ||
        _inferBodyweightByName(exerciseName);
    if (isBw) {
      return '$unitLabel $additionalSuffix';
    }
    if (isPerArmWeight(exerciseName, perArmWeight: perArmWeight)) {
      return '$unitLabel $perArmSuffix';
    }
    return unitLabel;
  }

  /// Fracción del peso corporal que cuenta como carga en ejercicios de peso corporal.
  /// Abdominales/crunch: solo el torso que se flexiona (~30–42 %). Dominadas/fondos: ~100 %.
  static double bodyweightFractionForExercise(String exerciseName) {
    final n = _normalize(exerciseName);
    if (_isPartialTorsoCoreExercise(n)) {
      if (n.contains('declin')) return 0.42;
      return 0.32;
    }
    if (_hasAny(n, [
      'push up',
      'push-up',
      'pushup',
      'flexion de brazos',
      'flexiones',
    ])) {
      return 0.65;
    }
    return 1.0;
  }

  static bool _isPartialTorsoCoreExercise(String n) {
    if (_hasAny(n, ['machine', 'maquina', 'polea', 'cable', 'barbell', 'barra'])) {
      return false;
    }
    const patterns = [
      'crunch',
      'sit-up',
      'sit up',
      'situp',
      'abdominal',
      'bicicleta',
      'bicycle crunch',
      'leg raise',
      'elevacion de piernas',
      'dead bug',
      'v-up',
      'jackknife',
      'russian twist',
    ];
    return patterns.any((p) => n.contains(_normalize(p)));
  }

  static ExerciseLoadMode? _inferLoadModeByName(String name) {
    if (_inferLoadedDistanceByName(name)) return ExerciseLoadMode.loadedDistance;
    if (_inferBodyweightByName(name)) return ExerciseLoadMode.bodyweight;
    if (isAssistedExercise(name)) return ExerciseLoadMode.assistedBodyweight;
    return null;
  }

  static bool _inferLoadedDistanceByName(String name) {
    final n = _normalize(name);
    return n.contains('farmer') ||
        n.contains('granjero') ||
        n.contains('farmers walk') ||
        n.contains('farmers carry') ||
        n.contains('farmer carry') ||
        n.contains('farmer walk');
  }

  static bool _inferMachineByName(String name) {
    final n = _normalize(name);
    return n.contains('maquina') || _hasWord(n, 'machine');
  }

  static bool _isMachineEquipment(String equipment) {
    final n = _normalize(equipment);
    return n.contains('maquina') || n == 'machine';
  }

  static bool _inferBodyweightByName(String name) {
    final n = _normalize(name);
    if (isAssistedExercise(n)) return true;
    return _hasAny(n, [
      'pull up',
      'pull-up',
      'pullup',
      'chin up',
      'chin-up',
      'chinup',
      'dominada',
      'muscle up',
      'muscle-up',
      'parallel bar dip',
      'fondos en paralela',
      'fondos en paralelas',
      'bench dip',
      'fondos en banco',
      'push up',
      'push-up',
      'pushup',
      'flexion',
      'flexión',
      'plancha',
      'plank',
      'l-sit',
      'hanging leg raise',
      'inverted row',
      'remo invertido',
      'australian pull',
    ]) ||
        (_hasWord(n, 'dip') && !_hasAny(n, ['machine', 'maquina', 'máquina', 'cable', 'polea'])) ||
        (_hasWord(n, 'fondos') && !_hasAny(n, ['maquina', 'máquina', 'machine']));
  }

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

  static bool _hasWord(String name, String word) {
    final w = _normalize(word);
    if (w.isEmpty) return false;
    return RegExp(r'(^|[^a-z])' + RegExp.escape(w) + r'([^a-z]|$)').hasMatch(name);
  }

  static String _normalize(String name) {
    return name
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  static bool _usesDumbbell(String n) {
    return n.contains('mancuerna') ||
        n.contains('dumbbell') ||
        n.contains('kettlebell') ||
        n.contains('pesa rusa');
  }

  static bool _usesCable(String n) {
    return n.contains('polea') ||
        n.contains('poleas') ||
        n.contains('cable') ||
        n.contains('pulley');
  }

  static bool _isPerArmCable(String n) {
    if (!_usesCable(n)) return false;
    if (_cableUsesTotalWeight(n)) return false;
    return _cableArmIsolation(n);
  }

  /// Polea con peso total de la pila (no por brazo): jalones, remos, pushdown con barra/cuerda, etc.
  static bool _cableUsesTotalWeight(String n) {
    if (_isUnilateral(n: n)) return false;

    if (_usesCable(n) &&
        (n.contains('triceps') || n.contains('tricep')) &&
        (n.contains('extension') || n.contains('pushdown') || n.contains('press down'))) {
      return true;
    }

    const patterns = [
      'jalon',
      'pulldown',
      'lat pull',
      'remo sentado',
      'seated row',
      'remo bajo',
      'low row',
      'remo alto',
      'high row',
      'face pull',
      'traccion al pecho',
      'dominada asistida',
      'assisted pull',
      'woodchop',
      'pallof',
      'crunch',
      'abdominal',
      'pushdown',
      'press down',
      'encogimiento',
      'shrug',
      'remo en polea baja',
      'remo en polea',
      'pull through',
    ];
    return patterns.any(n.contains);
  }

  /// Aislamiento de brazos/hombros con polea: elevaciones, curls, extensiones unilaterales, etc.
  static bool _cableArmIsolation(String n) {
    const patterns = [
      'lateral',
      'frontal',
      'front raise',
      'elevacion',
      'raise',
      'curl',
      'biceps',
      'bicep',
      'triceps',
      'tricep',
      'extension',
      'fly',
      'apertura',
      'cruce',
      'crossover',
      'kickback',
      'patada',
      'reverse fly',
      'pajarita',
      'pull over',
      'pullover',
      'external rotation',
      'rotacion externa',
      'internal rotation',
      'rotacion interna',
    ];
    return patterns.any(n.contains);
  }

  static bool _cableBilateralSimultaneous(String n) {
    const patterns = [
      'cruce',
      'crossover',
      'iron cross',
      'apertura en polea',
      'fly en polea',
    ];
    return patterns.any(n.contains);
  }

  static bool _singleDumbbellBothHands(String n) {
    const patterns = [
      'goblet',
      'copa',
      'pullover',
      'thruster',
      'swing',
      'sumo',
      'romanian',
      'rumano',
      'stiff',
    ];
    return patterns.any(n.contains);
  }

  static bool _isUnilateral({required String n}) {
    const patterns = [
      'unilateral',
      'un brazo',
      'one arm',
      'single arm',
      'single-arm',
      'concentrado',
      'concentration',
      'martillo altern',
      'alternating',
      'alternado',
    ];
    return patterns.any(n.contains);
  }
}
