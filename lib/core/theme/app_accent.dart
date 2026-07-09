import 'package:flutter/material.dart';

/// Paletas de acento personalizables (dorado = default de marca).
enum AppAccent {
  gold,
  orange,
  cobalt,
  violet,
  emerald,
  rose,
  crimson;

  static const defaultAccent = AppAccent.gold;

  static AppAccent fromCode(String? code) {
    if (code == null) return defaultAccent;
    for (final accent in AppAccent.values) {
      if (accent.name == code) return accent;
    }
    return defaultAccent;
  }

  Color get primary => switch (this) {
        AppAccent.gold => const Color(0xFFC6A46B),
        AppAccent.orange => const Color(0xFFFF6622),
        AppAccent.cobalt => const Color(0xFF4A9EFF),
        AppAccent.violet => const Color(0xFF9B6DFF),
        AppAccent.emerald => const Color(0xFF3DD68C),
        AppAccent.rose => const Color(0xFFFF6B9D),
        AppAccent.crimson => const Color(0xFFE82E45),
      };

  Color get dark => switch (this) {
        AppAccent.gold => const Color(0xFF8A6A3D),
        AppAccent.orange => const Color(0xFFE05518),
        AppAccent.cobalt => const Color(0xFF2B6DB8),
        AppAccent.violet => const Color(0xFF6B42C4),
        AppAccent.emerald => const Color(0xFF24965F),
        AppAccent.rose => const Color(0xFFC44575),
        AppAccent.crimson => const Color(0xFFA81E30),
      };

  Color get subtitleOnHero => switch (this) {
        AppAccent.gold => const Color(0xFFF0E6D2),
        AppAccent.orange => const Color(0xFFFFE8DC),
        AppAccent.cobalt => const Color(0xFFD6EBFF),
        AppAccent.violet => const Color(0xFFE8DEFF),
        AppAccent.emerald => const Color(0xFFD4F8E8),
        AppAccent.rose => const Color(0xFFFFE0EC),
        AppAccent.crimson => const Color(0xFFFFD6DC),
      };

  List<Color> get heroGradientColors => switch (this) {
        AppAccent.gold => const [
            Color(0xFFD4B87A),
            Color(0xFFC6A46B),
            Color(0xFF8A6A3D),
            Color(0xFF5C4528),
          ],
        AppAccent.orange => const [
            Color(0xFFFF8844),
            Color(0xFFFF6622),
            Color(0xFFE05518),
            Color(0xFF9A3810),
          ],
        AppAccent.cobalt => const [
            Color(0xFF7BB8FF),
            Color(0xFF4A9EFF),
            Color(0xFF2B6DB8),
            Color(0xFF1A4578),
          ],
        AppAccent.violet => const [
            Color(0xFFB894FF),
            Color(0xFF9B6DFF),
            Color(0xFF6B42C4),
            Color(0xFF452A82),
          ],
        AppAccent.emerald => const [
            Color(0xFF6AE8AE),
            Color(0xFF3DD68C),
            Color(0xFF24965F),
            Color(0xFF165C3A),
          ],
        AppAccent.rose => const [
            Color(0xFFFF94B8),
            Color(0xFFFF6B9D),
            Color(0xFFC44575),
            Color(0xFF7A2B48),
          ],
        AppAccent.crimson => const [
            Color(0xFFFF5570),
            Color(0xFFE82E45),
            Color(0xFFA81E30),
            Color(0xFF6B121E),
          ],
      };
}

/// Extensión de tema con el acento activo del usuario.
@immutable
class FitForgeAccent extends ThemeExtension<FitForgeAccent> {
  final AppAccent accent;
  final Color accentColor;
  final Color accentDark;
  final Color subtitleOnHero;

  const FitForgeAccent({
    required this.accent,
    required this.accentColor,
    required this.accentDark,
    required this.subtitleOnHero,
  });

  factory FitForgeAccent.fromAccent(AppAccent accent) {
    return FitForgeAccent(
      accent: accent,
      accentColor: accent.primary,
      accentDark: accent.dark,
      subtitleOnHero: accent.subtitleOnHero,
    );
  }

  static const gold = FitForgeAccent(
    accent: AppAccent.gold,
    accentColor: Color(0xFFC6A46B),
    accentDark: Color(0xFF8A6A3D),
    subtitleOnHero: Color(0xFFF0E6D2),
  );

  @override
  FitForgeAccent copyWith({
    AppAccent? accent,
    Color? accentColor,
    Color? accentDark,
    Color? subtitleOnHero,
  }) {
    return FitForgeAccent(
      accent: accent ?? this.accent,
      accentColor: accentColor ?? this.accentColor,
      accentDark: accentDark ?? this.accentDark,
      subtitleOnHero: subtitleOnHero ?? this.subtitleOnHero,
    );
  }

  @override
  FitForgeAccent lerp(ThemeExtension<FitForgeAccent>? other, double t) {
    if (other is! FitForgeAccent) return this;
    return FitForgeAccent(
      accent: t < 0.5 ? accent : other.accent,
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      subtitleOnHero: Color.lerp(subtitleOnHero, other.subtitleOnHero, t)!,
    );
  }
}

extension FitForgeAccentContext on BuildContext {
  FitForgeAccent get fitForgeAccent =>
      Theme.of(this).extension<FitForgeAccent>() ?? FitForgeAccent.gold;

  Color get accentColor => fitForgeAccent.accentColor;

  Color get accentDark => fitForgeAccent.accentDark;

  AppAccent get appAccent => fitForgeAccent.accent;
}
