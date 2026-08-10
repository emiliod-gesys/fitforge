import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// Tokens para el look “liquid glass” sutil de FORGEN.
///
/// Diseñado para gama baja: blur bajo y relleno translúcido
/// que ya se siente premium sin saturar BackdropFilter.
abstract final class AppGlass {
  /// Sigma bajo: se ve fancy sin matar GPU en mid/low-end.
  static const double blurSigma = 10;

  /// Relleno sobre el blur / o solo tint si blur está off.
  static Color fill([double opacity = 0.55]) =>
      AppColors.card.withValues(alpha: opacity);

  static Color tintHighlight([double opacity = 0.08]) =>
      Colors.white.withValues(alpha: opacity);

  static Color border([double opacity = 0.14]) =>
      Colors.white.withValues(alpha: opacity);

  static Color rimBottom([double opacity = 0.35]) =>
      AppColors.border.withValues(alpha: opacity);

  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(AppTokens.radiusXl),
  );
}
