import '../../models/exercise.dart';
import '../../models/workout.dart';

/// Cómo interpretar el peso registrado en una serie (total vs. por brazo).
abstract final class ExerciseLoad {
  /// Override explícito desde ejercicio personalizado (`null` = inferir del nombre).
  static bool? perArmWeightOverride(Exercise? exercise) {
    if (exercise == null || !exercise.isUserCustom) return null;
    return exercise.perArmWeight;
  }

  static bool? perArmWeightForExerciseId(String exerciseId, Iterable<Exercise> catalog) {
    for (final exercise in catalog) {
      if (exercise.id == exerciseId) return perArmWeightOverride(exercise);
    }
    return null;
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
  static double volumeMultiplier(String exerciseName, {bool? perArmWeight}) {
    final n = _normalize(exerciseName);
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
  }) {
    if (set.isCardio) return 0;
    if (!set.completed || set.weight == null || set.weight! <= 0) return 0;
    return set.weight! * set.reps * volumeMultiplier(exerciseName, perArmWeight: perArmWeight);
  }

  static String weightLabel(String unitLabel, String exerciseName, {bool? perArmWeight}) {
    if (isPerArmWeight(exerciseName, perArmWeight: perArmWeight)) {
      return '$unitLabel (por brazo)';
    }
    return unitLabel;
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
