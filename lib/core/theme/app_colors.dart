import 'package:flutter/material.dart';

/// Paleta premium FitForge — negro carbón + oro champán.
abstract final class AppColors {
  static const black = Color(0xFF000000);
  static const slate = Color(0xFF2C2D31);
  static const slateLight = Color(0xFF3A3B40);
  static const gold = Color(0xFFC6A46B);
  static const goldDark = Color(0xFF8A6A3D);
  static const surface = Color(0xFF000000);
  static const card = Color(0xFF1A1B1E);
  static const cardElevated = Color(0xFF242528);
  static const border = Color(0xFF2C2D31);
  static const textPrimary = Color(0xFFF4F3EF);
  static const textMuted = Color(0xFF9FA3A8);
  static const error = Color(0xFFE85D5D);

  /// Acento principal de la UI (alias histórico `orange`).
  static const orange = gold;
  static const orangeDark = goldDark;

  static const logoFit = gold;
  static const logoForge = textPrimary;

  /// Fondo claro para ilustraciones wger (siluetas negras sobre PNG transparente).
  static const exerciseIllustrationBackground = Color(0xFFFFFFFF);
}
