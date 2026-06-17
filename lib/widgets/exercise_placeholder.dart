import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum _ExerciseVisualGroup {
  chest,
  back,
  legs,
  shoulders,
  arms,
  core,
  glutes,
  cardio,
  other,
}

class ExercisePlaceholderStyle {
  final List<Color> backgroundColors;
  final Color borderColor;
  final Color iconColor;
  final IconData icon;

  const ExercisePlaceholderStyle({
    required this.backgroundColors,
    required this.borderColor,
    required this.iconColor,
    required this.icon,
  });

  static ExercisePlaceholderStyle resolve({
    String? category,
    List<String> muscles = const [],
  }) {
    return _styles[_groupFor(category: category, muscles: muscles)]!;
  }

  static _ExerciseVisualGroup _groupFor({
    String? category,
    List<String> muscles = const [],
  }) {
    for (final muscle in muscles) {
      final fromMuscle = _muscleGroup(muscle);
      if (fromMuscle != null) return fromMuscle;
    }
    return _categoryGroup(category ?? 'Otros');
  }

  static _ExerciseVisualGroup? _muscleGroup(String muscle) {
    final m = muscle.toLowerCase();
    if (m.contains('pecho') || m.contains('pectoral')) return _ExerciseVisualGroup.chest;
    if (m.contains('espalda') || m.contains('dorsal') || m.contains('trapecio')) {
      return _ExerciseVisualGroup.back;
    }
    if (m.contains('glúteo') || m.contains('gluteo')) return _ExerciseVisualGroup.glutes;
    if (m.contains('cuádriceps') ||
        m.contains('cuadriceps') ||
        m.contains('isquio') ||
        m.contains('pantorrilla') ||
        m.contains('gemelo')) {
      return _ExerciseVisualGroup.legs;
    }
    if (m.contains('hombro') || m.contains('deltoid')) return _ExerciseVisualGroup.shoulders;
    if (m.contains('bíceps') ||
        m.contains('biceps') ||
        m.contains('tríceps') ||
        m.contains('triceps') ||
        m.contains('antebrazo')) {
      return _ExerciseVisualGroup.arms;
    }
    if (m.contains('abdominal') || m.contains('core') || m.contains('oblicuo')) {
      return _ExerciseVisualGroup.core;
    }
    return null;
  }

  static _ExerciseVisualGroup _categoryGroup(String category) {
    switch (category) {
      case 'Pecho':
        return _ExerciseVisualGroup.chest;
      case 'Espalda':
        return _ExerciseVisualGroup.back;
      case 'Piernas':
      case 'Pantorrillas':
        return _ExerciseVisualGroup.legs;
      case 'Glúteos':
        return _ExerciseVisualGroup.glutes;
      case 'Hombros':
        return _ExerciseVisualGroup.shoulders;
      case 'Brazos':
        return _ExerciseVisualGroup.arms;
      case 'Abdominales':
        return _ExerciseVisualGroup.core;
      case 'Cardio':
        return _ExerciseVisualGroup.cardio;
      default:
        return _ExerciseVisualGroup.other;
    }
  }

  static const _styles = {
    _ExerciseVisualGroup.chest: ExercisePlaceholderStyle(
      backgroundColors: [Color(0xFF3A2520), Color(0xFF2A1A16)],
      borderColor: Color(0xFF5A3530),
      iconColor: Color(0xFFFF8866),
      icon: Icons.favorite_border,
    ),
    _ExerciseVisualGroup.back: ExercisePlaceholderStyle(
      backgroundColors: [Color(0xFF1A2535), Color(0xFF121C28)],
      borderColor: Color(0xFF2A3D55),
      iconColor: Color(0xFF77AAFF),
      icon: Icons.linear_scale,
    ),
    _ExerciseVisualGroup.legs: ExercisePlaceholderStyle(
      backgroundColors: [Color(0xFF1A2E22), Color(0xFF122018)],
      borderColor: Color(0xFF2A4A38),
      iconColor: Color(0xFF66CC88),
      icon: Icons.directions_run,
    ),
    _ExerciseVisualGroup.shoulders: ExercisePlaceholderStyle(
      backgroundColors: [Color(0xFF2E2A18), Color(0xFF201C10)],
      borderColor: Color(0xFF4A4228),
      iconColor: Color(0xFFFFCC55),
      icon: Icons.arrow_upward_rounded,
    ),
    _ExerciseVisualGroup.arms: ExercisePlaceholderStyle(
      backgroundColors: [Color(0xFF261A35), Color(0xFF1A1224)],
      borderColor: Color(0xFF3D2A55),
      iconColor: Color(0xFFBB88FF),
      icon: Icons.fitness_center,
    ),
    _ExerciseVisualGroup.core: ExercisePlaceholderStyle(
      backgroundColors: [Color(0xFF351A1A), Color(0xFF241212)],
      borderColor: Color(0xFF552A2A),
      iconColor: Color(0xFFFF7777),
      icon: Icons.crop_square_rounded,
    ),
    _ExerciseVisualGroup.glutes: ExercisePlaceholderStyle(
      backgroundColors: [Color(0xFF2A2235), Color(0xFF1C1624)],
      borderColor: Color(0xFF443855),
      iconColor: Color(0xFFCC99FF),
      icon: Icons.accessibility_new,
    ),
    _ExerciseVisualGroup.cardio: ExercisePlaceholderStyle(
      backgroundColors: [Color(0xFF1A2E35), Color(0xFF122028)],
      borderColor: Color(0xFF2A4A55),
      iconColor: Color(0xFF55DDFF),
      icon: Icons.favorite,
    ),
    _ExerciseVisualGroup.other: ExercisePlaceholderStyle(
      backgroundColors: [AppColors.cardElevated, AppColors.card],
      borderColor: AppColors.border,
      iconColor: AppColors.textMuted,
      icon: Icons.fitness_center,
    ),
  };
}

/// Placeholder visual cuando no hay imagen de ejercicio (color + icono por grupo muscular).
class ExercisePlaceholder extends StatelessWidget {
  final String? category;
  final List<String> muscles;
  final double? width;
  final double height;
  final BorderRadius borderRadius;
  final bool fullWidth;
  final bool loading;
  final double iconSize;

  const ExercisePlaceholder({
    super.key,
    this.category,
    this.muscles = const [],
    this.width = 56,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.fullWidth = false,
    this.loading = false,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final style = ExercisePlaceholderStyle.resolve(category: category, muscles: muscles);

    return Container(
      width: fullWidth ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.backgroundColors,
        ),
        borderRadius: borderRadius,
        border: Border.all(color: style.borderColor),
      ),
      child: loading
          ? Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: style.iconColor),
              ),
            )
          : Icon(style.icon, color: style.iconColor, size: iconSize),
    );
  }
}
