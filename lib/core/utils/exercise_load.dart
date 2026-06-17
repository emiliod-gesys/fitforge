import '../../models/workout.dart';

/// Cómo interpretar el peso registrado en una serie (total vs. por brazo).
abstract final class ExerciseLoad {
  /// Muestra la etiqueta «(por brazo)» en la UI de series.
  static bool isPerArmWeight(String exerciseName) {
    final n = _normalize(exerciseName);
    if (!_usesDumbbell(n)) return false;
    if (_singleDumbbellBothHands(n)) return false;
    return true;
  }

  /// Multiplicador de volumen: 2× para mancuernas bilaterales simultáneas.
  static double volumeMultiplier(String exerciseName) {
    if (!isPerArmWeight(exerciseName)) return 1;
    if (_isUnilateral(n: _normalize(exerciseName))) return 1;
    return 2;
  }

  static double setVolumeKg(WorkoutSet set, {required String exerciseName}) {
    if (!set.completed || set.weight == null || set.weight! <= 0) return 0;
    return set.weight! * set.reps * volumeMultiplier(exerciseName);
  }

  static String weightLabel(String unitLabel, String exerciseName) {
    if (isPerArmWeight(exerciseName)) {
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
