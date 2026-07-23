enum FitnessDailyTipKind { tip, myth }

/// Definición de un tip del día (texto localizado vía l10n).
class FitnessDailyTip {
  final String id;
  final FitnessDailyTipKind kind;
  /// Objetivo canónico en español (`Hipertrofia`, `Fuerza`, …) o null = general.
  final String? goal;

  const FitnessDailyTip({
    required this.id,
    required this.kind,
    this.goal,
  });
}

abstract final class FitnessDailyTips {
  static const catalog = <FitnessDailyTip>[
    // —— Generales (25) ——
    FitnessDailyTip(id: 'general_doms', kind: FitnessDailyTipKind.tip),
    FitnessDailyTip(id: 'general_sweat', kind: FitnessDailyTipKind.myth),
    FitnessDailyTip(id: 'general_sleep', kind: FitnessDailyTipKind.tip),
    FitnessDailyTip(id: 'general_spot', kind: FitnessDailyTipKind.myth),
    FitnessDailyTip(id: 'general_progressive', kind: FitnessDailyTipKind.tip),
    FitnessDailyTip(id: 'general_bulky', kind: FitnessDailyTipKind.myth),
    FitnessDailyTip(id: 'general_warmup', kind: FitnessDailyTipKind.tip),
    FitnessDailyTip(id: 'general_carbs_night', kind: FitnessDailyTipKind.myth),
    FitnessDailyTip(id: 'general_hydration', kind: FitnessDailyTipKind.tip),
    FitnessDailyTip(id: 'general_stretch_cold', kind: FitnessDailyTipKind.myth),
    FitnessDailyTip(id: 'general_scale_daily', kind: FitnessDailyTipKind.tip),
    FitnessDailyTip(id: 'general_meal_timing', kind: FitnessDailyTipKind.myth),
    FitnessDailyTip(id: 'general_detox', kind: FitnessDailyTipKind.myth),
    FitnessDailyTip(id: 'general_rest_days', kind: FitnessDailyTipKind.tip),
    FitnessDailyTip(id: 'general_form_first', kind: FitnessDailyTipKind.tip),
    FitnessDailyTip(id: 'general_steps', kind: FitnessDailyTipKind.tip),
    FitnessDailyTip(id: 'general_fasted_cardio', kind: FitnessDailyTipKind.myth),
    FitnessDailyTip(id: 'general_bcaa', kind: FitnessDailyTipKind.myth),
    FitnessDailyTip(id: 'general_creatine', kind: FitnessDailyTipKind.tip),
    FitnessDailyTip(id: 'general_pain_vs_soreness', kind: FitnessDailyTipKind.tip),
    FitnessDailyTip(id: 'general_consistency', kind: FitnessDailyTipKind.tip),
    FitnessDailyTip(id: 'general_track_progress', kind: FitnessDailyTipKind.tip),
    FitnessDailyTip(id: 'general_fiber', kind: FitnessDailyTipKind.tip),
    FitnessDailyTip(id: 'general_toning_machines', kind: FitnessDailyTipKind.myth),
    FitnessDailyTip(id: 'general_sweat_detox', kind: FitnessDailyTipKind.myth),

    // —— Hipertrofia (12) ——
    FitnessDailyTip(id: 'hypertrophy_failure', kind: FitnessDailyTipKind.tip, goal: 'Hipertrofia'),
    FitnessDailyTip(id: 'hypertrophy_confusion', kind: FitnessDailyTipKind.myth, goal: 'Hipertrofia'),
    FitnessDailyTip(id: 'hypertrophy_protein', kind: FitnessDailyTipKind.tip, goal: 'Hipertrofia'),
    FitnessDailyTip(id: 'hypertrophy_compounds', kind: FitnessDailyTipKind.tip, goal: 'Hipertrofia'),
    FitnessDailyTip(id: 'hypertrophy_volume', kind: FitnessDailyTipKind.tip, goal: 'Hipertrofia'),
    FitnessDailyTip(id: 'hypertrophy_tempo', kind: FitnessDailyTipKind.myth, goal: 'Hipertrofia'),
    FitnessDailyTip(id: 'hypertrophy_pump', kind: FitnessDailyTipKind.myth, goal: 'Hipertrofia'),
    FitnessDailyTip(id: 'hypertrophy_frequency', kind: FitnessDailyTipKind.tip, goal: 'Hipertrofia'),
    FitnessDailyTip(id: 'hypertrophy_eccentric', kind: FitnessDailyTipKind.tip, goal: 'Hipertrofia'),
    FitnessDailyTip(id: 'hypertrophy_mind_muscle', kind: FitnessDailyTipKind.myth, goal: 'Hipertrofia'),
    FitnessDailyTip(id: 'hypertrophy_deload', kind: FitnessDailyTipKind.tip, goal: 'Hipertrofia'),
    FitnessDailyTip(id: 'hypertrophy_sleep_growth', kind: FitnessDailyTipKind.tip, goal: 'Hipertrofia'),

    // —— Fuerza (12) ——
    FitnessDailyTip(id: 'strength_rest', kind: FitnessDailyTipKind.tip, goal: 'Fuerza'),
    FitnessDailyTip(id: 'strength_failure', kind: FitnessDailyTipKind.myth, goal: 'Fuerza'),
    FitnessDailyTip(id: 'strength_technique', kind: FitnessDailyTipKind.tip, goal: 'Fuerza'),
    FitnessDailyTip(id: 'strength_specificity', kind: FitnessDailyTipKind.tip, goal: 'Fuerza'),
    FitnessDailyTip(id: 'strength_belt', kind: FitnessDailyTipKind.tip, goal: 'Fuerza'),
    FitnessDailyTip(id: 'strength_warmup_sets', kind: FitnessDailyTipKind.tip, goal: 'Fuerza'),
    FitnessDailyTip(id: 'strength_cns', kind: FitnessDailyTipKind.tip, goal: 'Fuerza'),
    FitnessDailyTip(id: 'strength_accessories', kind: FitnessDailyTipKind.tip, goal: 'Fuerza'),
    FitnessDailyTip(id: 'strength_1rm_test', kind: FitnessDailyTipKind.myth, goal: 'Fuerza'),
    FitnessDailyTip(id: 'strength_grip', kind: FitnessDailyTipKind.tip, goal: 'Fuerza'),
    FitnessDailyTip(id: 'strength_leg_drive', kind: FitnessDailyTipKind.tip, goal: 'Fuerza'),
    FitnessDailyTip(id: 'strength_program_hopping', kind: FitnessDailyTipKind.myth, goal: 'Fuerza'),

    // —— Pérdida de grasa (12) ——
    FitnessDailyTip(id: 'fatloss_cardio', kind: FitnessDailyTipKind.myth, goal: 'Pérdida de grasa'),
    FitnessDailyTip(id: 'fatloss_strength', kind: FitnessDailyTipKind.tip, goal: 'Pérdida de grasa'),
    FitnessDailyTip(id: 'fatloss_starve', kind: FitnessDailyTipKind.myth, goal: 'Pérdida de grasa'),
    FitnessDailyTip(id: 'fatloss_scale', kind: FitnessDailyTipKind.tip, goal: 'Pérdida de grasa'),
    FitnessDailyTip(id: 'fatloss_cheat_meal', kind: FitnessDailyTipKind.myth, goal: 'Pérdida de grasa'),
    FitnessDailyTip(id: 'fatloss_protein', kind: FitnessDailyTipKind.tip, goal: 'Pérdida de grasa'),
    FitnessDailyTip(id: 'fatloss_neat', kind: FitnessDailyTipKind.tip, goal: 'Pérdida de grasa'),
    FitnessDailyTip(id: 'fatloss_fat_burn_zone', kind: FitnessDailyTipKind.myth, goal: 'Pérdida de grasa'),
    FitnessDailyTip(id: 'fatloss_slow_cut', kind: FitnessDailyTipKind.tip, goal: 'Pérdida de grasa'),
    FitnessDailyTip(id: 'fatloss_liquids', kind: FitnessDailyTipKind.tip, goal: 'Pérdida de grasa'),
    FitnessDailyTip(id: 'fatloss_steps', kind: FitnessDailyTipKind.tip, goal: 'Pérdida de grasa'),
    FitnessDailyTip(id: 'fatloss_sleep', kind: FitnessDailyTipKind.tip, goal: 'Pérdida de grasa'),

    // —— Resistencia (10) ——
    FitnessDailyTip(id: 'endurance_easy', kind: FitnessDailyTipKind.tip, goal: 'Resistencia'),
    FitnessDailyTip(id: 'endurance_more', kind: FitnessDailyTipKind.myth, goal: 'Resistencia'),
    FitnessDailyTip(id: 'endurance_8020', kind: FitnessDailyTipKind.tip, goal: 'Resistencia'),
    FitnessDailyTip(id: 'endurance_strength', kind: FitnessDailyTipKind.tip, goal: 'Resistencia'),
    FitnessDailyTip(id: 'endurance_shoes', kind: FitnessDailyTipKind.tip, goal: 'Resistencia'),
    FitnessDailyTip(id: 'endurance_hydration', kind: FitnessDailyTipKind.tip, goal: 'Resistencia'),
    FitnessDailyTip(id: 'endurance_intervals', kind: FitnessDailyTipKind.tip, goal: 'Resistencia'),
    FitnessDailyTip(id: 'endurance_recovery', kind: FitnessDailyTipKind.tip, goal: 'Resistencia'),
    FitnessDailyTip(id: 'endurance_taper', kind: FitnessDailyTipKind.tip, goal: 'Resistencia'),
    FitnessDailyTip(id: 'endurance_only_cardio', kind: FitnessDailyTipKind.myth, goal: 'Resistencia'),

    // —— Mantenimiento (10) ——
    FitnessDailyTip(id: 'maintenance_consistency', kind: FitnessDailyTipKind.tip, goal: 'Mantenimiento'),
    FitnessDailyTip(id: 'maintenance_deload', kind: FitnessDailyTipKind.tip, goal: 'Mantenimiento'),
    FitnessDailyTip(id: 'maintenance_variety', kind: FitnessDailyTipKind.tip, goal: 'Mantenimiento'),
    FitnessDailyTip(id: 'maintenance_microcycles', kind: FitnessDailyTipKind.tip, goal: 'Mantenimiento'),
    FitnessDailyTip(id: 'maintenance_mobility', kind: FitnessDailyTipKind.tip, goal: 'Mantenimiento'),
    FitnessDailyTip(id: 'maintenance_perfect_week', kind: FitnessDailyTipKind.myth, goal: 'Mantenimiento'),
    FitnessDailyTip(id: 'maintenance_habits', kind: FitnessDailyTipKind.tip, goal: 'Mantenimiento'),
    FitnessDailyTip(id: 'maintenance_social', kind: FitnessDailyTipKind.tip, goal: 'Mantenimiento'),
    FitnessDailyTip(id: 'maintenance_health', kind: FitnessDailyTipKind.tip, goal: 'Mantenimiento'),
    FitnessDailyTip(id: 'maintenance_enjoy', kind: FitnessDailyTipKind.tip, goal: 'Mantenimiento'),
  ];

  /// Elige un tip estable para el usuario en ese día (mismo tip todo el día).
  static FitnessDailyTip pickFor({
    required DateTime date,
    required String userId,
    String? fitnessGoal,
  }) {
    final goal = fitnessGoal?.trim();
    var pool = catalog
        .where((tip) => tip.goal == null || (goal != null && tip.goal == goal))
        .toList();
    if (pool.isEmpty) {
      pool = catalog.where((tip) => tip.goal == null).toList();
    }

    final dayOfYear = date.difference(DateTime(date.year)).inDays;
    final seed = userId.hashCode ^ (date.year * 1000 + dayOfYear);
    return pool[seed.abs() % pool.length];
  }
}
