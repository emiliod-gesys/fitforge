import 'package:flutter/material.dart';
import 'package:flutter_body_heatmap/flutter_body_heatmap.dart';

/// Resuelve categoría/músculos del ejercicio a un mapa muscular para el maniquí.
abstract final class ExerciseCategoryIllustration {
  static const highlightColors = [
    Color(0xFF5C2028),
    Color(0xFF9B2D2D),
    Color(0xFFD32F2F),
    Color(0xFFE82E45),
  ];

  static const _fullIntensity = MuscleData(intensity: 1.0);

  static IllustrationConfig? resolve({
    String? category,
    List<String> muscles = const [],
  }) {
    final key = _resolveKey(category, muscles);
    if (key == null) return null;
    return _configs[key];
  }

  static String? _resolveKey(String? category, List<String> muscles) {
    final muscleKeys = muscles.map(_norm).where((m) => m.isNotEmpty).toList();

    for (final m in muscleKeys) {
      final fromMuscle = _muscleKey(m);
      if (fromMuscle != null) return fromMuscle;
    }

    final cat = _norm(category ?? '');
    if (cat.isEmpty) return null;

    const catMap = {
      'abdominales': 'abs',
      'abs': 'abs',
      'abdomen': 'abs',
      'core': 'abs',
      'pecho': 'chest',
      'chest': 'chest',
      'espalda': 'back',
      'back': 'back',
      'hombros': 'shoulders',
      'shoulders': 'shoulders',
      'hombro': 'shoulders',
      'biceps': 'biceps',
      'bíceps': 'biceps',
      'triceps': 'triceps',
      'tríceps': 'triceps',
      'piernas': 'legs',
      'legs': 'legs',
      'pantorrillas': 'calves',
      'calves': 'calves',
      'pantorrilla': 'calves',
      'gluteos': 'glutes',
      'glúteos': 'glutes',
      'glutes': 'glutes',
      'gluteo': 'glutes',
      'glúteo': 'glutes',
      'trapecios': 'traps',
      'trapecio': 'traps',
      'traps': 'traps',
      'trap': 'traps',
      'antebrazos': 'forearms',
      'antebrazo': 'forearms',
      'forearms': 'forearms',
      'forearm': 'forearms',
      'brazos': 'arms',
      'arms': 'arms',
      'cardio': 'cardio',
    };

    final fromCat = catMap[cat];
    if (fromCat == 'arms') {
      return _resolveArmsCategory(muscleKeys);
    }
    return fromCat;
  }

  static String? _muscleKey(String normalized) {
    if (normalized.contains('bicep')) return 'biceps';
    if (normalized.contains('tricep')) return 'triceps';
    if (normalized.contains('antebraz') || normalized.contains('forearm')) {
      return 'forearms';
    }
    if (normalized.contains('trapec') || normalized.contains('trap')) {
      return 'traps';
    }
    if (normalized.contains('pantorr') || normalized.contains('calf') ||
        normalized.contains('gemelo')) {
      return 'calves';
    }
    if (normalized.contains('glute')) return 'glutes';
    if (normalized.contains('abdom') || normalized.contains('oblic') ||
        normalized.contains('core')) {
      return 'abs';
    }
    if (normalized.contains('pecho') || normalized.contains('pectoral') ||
        normalized.contains('chest')) {
      return 'chest';
    }
    if (normalized.contains('espalda') || normalized.contains('dorsal') ||
        normalized.contains('lumbar') || normalized.contains('back')) {
      return 'back';
    }
    if (normalized.contains('hombro') || normalized.contains('deltoid') ||
        normalized.contains('shoulder')) {
      return 'shoulders';
    }
    if (normalized.contains('cuadricep') || normalized.contains('isquio') ||
        normalized.contains('hamstring') || normalized.contains('femoral')) {
      return 'legs';
    }
    if (normalized.contains('pierna') || normalized.contains('leg')) {
      return 'legs';
    }
    return null;
  }

  static String _resolveArmsCategory(List<String> muscleKeys) {
    for (final m in muscleKeys) {
      final key = _muscleKey(m);
      if (key == 'biceps' || key == 'triceps' || key == 'forearms') {
        return key!;
      }
    }
    return 'biceps';
  }

  static String _norm(String input) {
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

  static Map<Muscle, MuscleData> _dataFor(Iterable<Muscle> muscles) {
    return {for (final m in muscles) m: _fullIntensity};
  }

  static final _configs = <String, IllustrationConfig>{
    'abs': IllustrationConfig(
      side: BodySide.front,
      data: _dataFor([Muscle.abs, Muscle.obliques]),
    ),
    'chest': IllustrationConfig(
      side: BodySide.front,
      data: _dataFor([Muscle.chest]),
    ),
    'shoulders': IllustrationConfig(
      side: BodySide.front,
      data: _dataFor([Muscle.deltoids]),
    ),
    'biceps': IllustrationConfig(
      side: BodySide.front,
      data: _dataFor([Muscle.biceps]),
    ),
    'triceps': IllustrationConfig(
      side: BodySide.back,
      data: _dataFor([Muscle.triceps]),
    ),
    'forearms': IllustrationConfig(
      side: BodySide.front,
      data: _dataFor([Muscle.forearm]),
    ),
    'back': IllustrationConfig(
      side: BodySide.back,
      data: _dataFor([Muscle.upperBack, Muscle.lowerBack]),
    ),
    'traps': IllustrationConfig(
      side: BodySide.back,
      data: _dataFor([Muscle.trapezius]),
    ),
    'legs': IllustrationConfig(
      side: BodySide.front,
      data: _dataFor([Muscle.quadriceps, Muscle.hamstring]),
    ),
    'calves': IllustrationConfig(
      side: BodySide.back,
      data: _dataFor([Muscle.calves]),
    ),
    'glutes': IllustrationConfig(
      side: BodySide.back,
      data: _dataFor([Muscle.gluteal]),
    ),
    'cardio': IllustrationConfig(
      side: BodySide.front,
      data: _dataFor([Muscle.chest, Muscle.quadriceps]),
    ),
  };
}

class IllustrationConfig {
  final BodySide side;
  final Map<Muscle, MuscleData> data;

  const IllustrationConfig({required this.side, required this.data});
}
