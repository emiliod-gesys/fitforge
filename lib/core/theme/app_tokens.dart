import 'package:flutter/material.dart';

/// Escala de diseño FitForge — usar en lugar de números mágicos.
abstract final class AppTokens {
  // Spacing
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space28 = 28;
  static const double space32 = 32;
  static const double space40 = 40;

  // Radii
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 22;
  static const double radiusFull = 999;

  // Component heights
  static const double buttonHeight = 52;
  static const double buttonHeightSm = 44;
  static const double navBarHeight = 72;
  static const double listRowMinHeight = 56;

  // Borders
  static const double borderHairline = 1;
  static const double borderAccent = 1.5;

  // Page insets
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 16, 20, 24);
  static const EdgeInsets pagePaddingCompact = EdgeInsets.fromLTRB(16, 12, 16, 20);

  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
}
