import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Decoraciones reutilizables de la línea gráfica premium FitForge.
abstract final class AppDecorations {
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD4B87A),
      Color(0xFFC6A46B),
      Color(0xFF8A6A3D),
      Color(0xFF5C4528),
    ],
    stops: [0.0, 0.35, 0.72, 1.0],
  );

  static const heroSubtitleColor = Color(0xFFF0E6D2);

  static List<BoxShadow> get heroGlow => [
        BoxShadow(
          color: AppColors.gold.withValues(alpha: 0.3),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: AppColors.goldDark.withValues(alpha: 0.18),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static BoxDecoration heroCard({double radius = 20}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: heroGradient,
        boxShadow: heroGlow,
      );

  static BoxDecoration authCard({double radius = 16}) => BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.1),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration authBackdropGlow() => BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.55),
          radius: 1.1,
          colors: [
            AppColors.gold.withValues(alpha: 0.14),
            AppColors.surface.withValues(alpha: 0),
          ],
        ),
      );
}
