import 'package:flutter/material.dart';

import 'app_accent.dart';
import 'app_colors.dart';

/// Decoraciones reutilizables de la línea gráfica premium FitForge.
abstract final class AppDecorations {
  static LinearGradient heroGradient(AppAccent accent) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: accent.heroGradientColors,
        stops: const [0.0, 0.35, 0.72, 1.0],
      );

  static List<BoxShadow> heroGlow(Color accent, Color accentDark) => [
        BoxShadow(
          color: accent.withValues(alpha: 0.3),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: accentDark.withValues(alpha: 0.18),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static BoxDecoration heroCard(AppAccent accent, {double radius = 20}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: heroGradient(accent),
        boxShadow: heroGlow(accent.primary, accent.dark),
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

  static BoxDecoration authBackdropGlow(AppAccent accent) => BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.55),
          radius: 1.1,
          colors: [
            accent.primary.withValues(alpha: 0.14),
            AppColors.surface.withValues(alpha: 0),
          ],
        ),
      );
}
