/// Modo calórico según objetivo fitness (déficit, superávit o mantenimiento).
enum CalorieGoalMode { deficit, surplus, maintenance }

/// Validación y rangos para el editor de presupuesto calórico.
abstract final class CalorieBudgetAdjustment {
  static CalorieGoalMode goalMode(String? goal) {
    final g = (goal ?? '').toLowerCase();
    if (g.contains('pérdida') ||
        g.contains('perdida') ||
        g.contains('fat') ||
        g.contains('grasa')) {
      return CalorieGoalMode.deficit;
    }
    if (g.contains('hipertrofia') ||
        g.contains('hypertrophy') ||
        g.contains('fuerza') ||
        g.contains('strength')) {
      return CalorieGoalMode.surplus;
    }
    return CalorieGoalMode.maintenance;
  }

  static int defaultPercent(String? goal) => switch (goalMode(goal)) {
        CalorieGoalMode.deficit => -15,
        CalorieGoalMode.surplus => 8,
        CalorieGoalMode.maintenance => 0,
      };

  /// Intensidad mostrada en UI (siempre positiva en déficit/superávit).
  static int displayIntensity(String? goal, int adjustmentPct) => switch (goalMode(goal)) {
        CalorieGoalMode.deficit => adjustmentPct.abs(),
        CalorieGoalMode.surplus => adjustmentPct.clamp(0, 99),
        CalorieGoalMode.maintenance => adjustmentPct,
      };

  static int adjustmentFromDisplay(String? goal, int display) => switch (goalMode(goal)) {
        CalorieGoalMode.deficit => -display.clamp(5, 25),
        CalorieGoalMode.surplus => display.clamp(3, 15),
        CalorieGoalMode.maintenance => display.clamp(-5, 5),
      };

  static ({int min, int max, int divisions}) displaySliderSpec(String? goal) =>
      switch (goalMode(goal)) {
        CalorieGoalMode.deficit => (min: 5, max: 25, divisions: 20),
        CalorieGoalMode.surplus => (min: 3, max: 15, divisions: 12),
        CalorieGoalMode.maintenance => (min: -5, max: 5, divisions: 10),
      };

  /// @deprecated Use displaySliderSpec — signed pct kept for storage compat.
  static ({int min, int max, int divisions}) sliderSpec(String? goal) =>
      switch (goalMode(goal)) {
        CalorieGoalMode.deficit => (min: -25, max: -5, divisions: 20),
        CalorieGoalMode.surplus => (min: 3, max: 15, divisions: 12),
        CalorieGoalMode.maintenance => (min: -5, max: 5, divisions: 10),
      };

  static int resolvedPercent(String? goal, int? storedPct) =>
      storedPct ?? defaultPercent(goal);

  static int goalFromTdee(int tdee, int adjustmentPct) =>
      (tdee * (1 + adjustmentPct / 100)).round().clamp(1200, 6000);

  static int absoluteKcal(int tdee, int adjustmentPct) =>
      (tdee * adjustmentPct.abs() / 100).round();

  /// Retorna clave l10n del aviso o null si el ajuste es razonable.
  static CalorieBudgetWarning? evaluate({
    required String? goal,
    required int tdee,
    required int adjustmentPct,
  }) {
    final mode = goalMode(goal);
    final absKcal = absoluteKcal(tdee, adjustmentPct);

    if (mode == CalorieGoalMode.deficit) {
      if (adjustmentPct >= 0) return CalorieBudgetWarning.wrongDirectionDeficit;
      if (absKcal < 100) return CalorieBudgetWarning.deficitTooSmall;
      if (adjustmentPct <= -25) return CalorieBudgetWarning.deficitTooAggressive;
      return null;
    }

    if (mode == CalorieGoalMode.surplus) {
      if (adjustmentPct <= 0) return CalorieBudgetWarning.wrongDirectionSurplus;
      if (absKcal < 100) return CalorieBudgetWarning.surplusTooSmall;
      if (adjustmentPct >= 15) return CalorieBudgetWarning.surplusTooHigh;
      return null;
    }

    if (adjustmentPct.abs() >= 5) return CalorieBudgetWarning.maintenanceDrift;
    return null;
  }
}

enum CalorieBudgetWarning {
  wrongDirectionDeficit,
  deficitTooSmall,
  deficitTooAggressive,
  wrongDirectionSurplus,
  surplusTooSmall,
  surplusTooHigh,
  maintenanceDrift,
}
