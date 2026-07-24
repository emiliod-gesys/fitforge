import 'package:flutter/material.dart';
import '../core/theme/app_accent.dart';
import '../core/utils/connection_error.dart';
import '../core/utils/catalog_muscle_labels.dart';
import '../core/utils/feed_personal_record.dart';
import '../core/utils/milestones.dart';
import '../core/utils/player_level_badge.dart';
import '../models/profile.dart';
import '../models/routine.dart';
import '../models/food_entry.dart';
import '../models/rest_timer_alert_mode.dart';
import '../models/social.dart';
import '../core/hyrox/hyrox_standards.dart';
import '../core/runner/runner_standards.dart';
import 'app_localizations.dart';
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension ProfileL10n on AppLocalizations {
  String genderLabel(Gender? gender) {
    return switch (gender) {
      Gender.male => genderMale,
      Gender.female => genderFemale,
      Gender.nonBinary => genderNonBinary,
      Gender.preferNotToSay => genderPreferNotSay,
      null => notDefined,
    };
  }

  String goalLabel(String? goal) {
    return switch (goal) {
      'Hipertrofia' || 'Hypertrophy' => goalHypertrophy,
      'Fuerza' || 'Strength' => goalStrength,
      'Pérdida de grasa' || 'Fat loss' => goalFatLoss,
      'Resistencia' || 'Endurance' => goalEndurance,
      'Mantenimiento' || 'Maintenance' => goalMaintenance,
      _ => goal ?? notDefined,
    };
  }

  String experienceLabel(String? level) {
    return switch (level) {
      'principiante' || 'beginner' => expBeginner,
      'intermedio' || 'intermediate' => expIntermediate,
      'avanzado' || 'advanced' => expAdvanced,
      _ => level ?? expIntermediate,
    };
  }

  String? subscriptionTierLabel(SubscriptionTier tier) {
    return switch (tier) {
      SubscriptionTier.gymrat => subscriptionTierGymrat,
      SubscriptionTier.gymratPro => subscriptionTierGymratPro,
      SubscriptionTier.free => null,
    };
  }

  String languageLabel(String code) => code == 'en' ? languageEn : languageEs;

  String accentLabel(AppAccent accent) {
    return switch (accent) {
      AppAccent.gold => accentGold,
      AppAccent.orange => accentOrange,
      AppAccent.cobalt => accentCobalt,
      AppAccent.violet => accentViolet,
      AppAccent.emerald => accentEmerald,
      AppAccent.rose => accentRose,
      AppAccent.crimson => accentCrimson,
    };
  }

  String muscleLabel(String muscle) {
    final key = CatalogMuscleLabels.canonicalMuscleKey(muscle);
    final core = switch (key) {
      'Pecho' => muscleChest,
      'Espalda' => muscleBack,
      'Hombros' => muscleShoulders,
      'Bíceps' => muscleBiceps,
      'Tríceps' => muscleTriceps,
      'Piernas' => muscleLegs,
      'Glúteos' => muscleGlutes,
      'Abdominales' => muscleAbs,
      'Antebrazos' => muscleForearms,
      'Cardio' => muscleCardio,
      'Pantorrillas' => muscleCalves,
      _ => null,
    };
    if (core != null) return core;
    if (localeName.startsWith('en')) {
      return CatalogMuscleLabels.englishMuscleLabel(key);
    }
    return key;
  }

  String exerciseCategoryLabel(String category) {
    final key = CatalogMuscleLabels.canonicalCategoryKey(category);
    final core = switch (key) {
      'Pecho' => muscleChest,
      'Espalda' => muscleBack,
      'Hombros' => muscleShoulders,
      'Bíceps' => muscleBiceps,
      'Tríceps' => muscleTriceps,
      'Piernas' => muscleLegs,
      'Glúteos' => muscleGlutes,
      'Abdominales' => muscleAbs,
      'Antebrazos' => muscleForearms,
      'Cardio' => muscleCardio,
      'Pantorrillas' => muscleCalves,
      _ => null,
    };
    if (core != null) return core;
    if (localeName.startsWith('en')) {
      return CatalogMuscleLabels.englishCategoryLabel(key);
    }
    return key;
  }

  String bodyMetricLabel(String key) {
    return switch (key) {
      'weight' => metricWeight,
      'bmi' => metricBmi,
      'body_fat' => metricBodyFat,
      'skeletal_muscle' => metricSkeletalMuscle,
      'fat_free_mass' => metricFatFreeMass,
      'subcutaneous_fat' => metricSubcutaneousFat,
      'visceral_fat' => metricVisceralFat,
      'body_water' => metricBodyWater,
      'muscle_mass' => metricMuscleMass,
      'bone_mass' => metricBoneMass,
      'protein' => metricProtein,
      'bmr' => metricBmr,
      'metabolic_age' => metricMetabolicAge,
      _ => key,
    };
  }

  /// Valor canónico en español para guardar en BD.
  String canonicalGoal(String localizedGoal) {
    if (localizedGoal == goalHypertrophy) return 'Hipertrofia';
    if (localizedGoal == goalStrength) return 'Fuerza';
    if (localizedGoal == goalFatLoss) return 'Pérdida de grasa';
    if (localizedGoal == goalEndurance) return 'Resistencia';
    if (localizedGoal == goalMaintenance) return 'Mantenimiento';
    return localizedGoal;
  }

  String canonicalExperience(String localized) {
    if (localized == expBeginner) return 'principiante';
    if (localized == expIntermediate) return 'intermedio';
    if (localized == expAdvanced) return 'avanzado';
    return localized;
  }

  List<String> get fitnessGoals => [
        goalHypertrophy,
        goalStrength,
        goalFatLoss,
        goalEndurance,
        goalMaintenance,
      ];

  String fitnessGoalTrainingDescription(String localizedGoal) {
    if (localizedGoal == goalHypertrophy) return goalHypertrophyTraining;
    if (localizedGoal == goalStrength) return goalStrengthTraining;
    if (localizedGoal == goalFatLoss) return goalFatLossTraining;
    if (localizedGoal == goalEndurance) return goalEnduranceTraining;
    if (localizedGoal == goalMaintenance) return goalMaintenanceTraining;
    return '';
  }

  String fitnessGoalDietDescription(String localizedGoal) {
    if (localizedGoal == goalHypertrophy) return goalHypertrophyDiet;
    if (localizedGoal == goalStrength) return goalStrengthDiet;
    if (localizedGoal == goalFatLoss) return goalFatLossDiet;
    if (localizedGoal == goalEndurance) return goalEnduranceDiet;
    if (localizedGoal == goalMaintenance) return goalMaintenanceDiet;
    return '';
  }

  String fitnessGoalCalorieModeLabel(String localizedGoal) {
    if (localizedGoal == goalFatLoss) return fitnessGoalCalorieDeficit;
    if (localizedGoal == goalEndurance || localizedGoal == goalMaintenance) {
      return fitnessGoalCalorieMaintenance;
    }
    return fitnessGoalCalorieSurplus;
  }

  List<String> get experienceLevels => [expBeginner, expIntermediate, expAdvanced];

  String activityLevelLabel(DailyActivityLevel level) {
    return switch (level) {
      DailyActivityLevel.sedentary => activitySedentary,
      DailyActivityLevel.moderate => activityModerate,
      DailyActivityLevel.high => activityHigh,
    };
  }

  String activityLevelDescription(DailyActivityLevel level) {
    return switch (level) {
      DailyActivityLevel.sedentary => activitySedentaryDescription,
      DailyActivityLevel.moderate => activityModerateDescription,
      DailyActivityLevel.high => activityHighDescription,
    };
  }

  List<DailyActivityLevel> get activityLevels => DailyActivityLevel.values;

  String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return timeNow;
    if (diff.inHours < 1) return timeMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return timeDaysAgo(diff.inDays);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  List<String> get coachSuggestions => [
        coachSuggestion1,
        coachSuggestion2,
        coachSuggestion3,
        coachSuggestion4,
      ];

  String streakWeeksLabel(int weeks) {
    if (weeks == 0) return streakWeeks0;
    if (weeks == 1) return streakWeeks1;
    return streakWeeksMany(weeks);
  }

  String workoutDisplayName(String name) {
    if (name == 'Entrenamiento' || name == 'Workout') return defaultWorkoutName;
    if (name == 'Entrenamiento libre' || name == 'Free workout') return freeWorkout;
    if (_isRunnerOutdoorName(name)) return runnerStartOutdoor;
    if (_isRunnerTreadmillName(name)) return runnerStartTreadmill;
    if (_isHyroxPrepName(name)) return hyroxRoutinePrepName;
    if (_isHyroxBuildName(name)) return hyroxRoutineBuildName;
    if (_isHyroxRaceName(name)) return hyroxRoutineRaceName;
    return name;
  }

  String routineDisplayName(Routine routine) {
    if (routine.isRunnerSystem && routine.runnerType != null) {
      return switch (routine.runnerType!) {
        RunnerType.outdoor => runnerStartOutdoor,
        RunnerType.treadmill => runnerStartTreadmill,
      };
    }
    if (routine.isHyroxSystem && routine.hyroxLevel != null) {
      return switch (routine.hyroxLevel!) {
        HyroxLevel.prep => hyroxRoutinePrepName,
        HyroxLevel.build => hyroxRoutineBuildName,
        HyroxLevel.race => hyroxRoutineRaceName,
      };
    }
    return workoutDisplayName(routine.name);
  }

  String? routineDisplaySubtitle(Routine routine) {
    if (routine.isRunnerSystem && routine.runnerType != null) {
      return switch (routine.runnerType!) {
        RunnerType.outdoor => runnerRoutineOutdoorSubtitle,
        RunnerType.treadmill => runnerRoutineTreadmillSubtitle,
      };
    }
    if (routine.isHyroxSystem && routine.hyroxLevel != null) {
      return switch (routine.hyroxLevel!) {
        HyroxLevel.prep => hyroxRoutinePrepSubtitle,
        HyroxLevel.build => hyroxRoutineBuildSubtitle,
        HyroxLevel.race => hyroxRoutineRaceSubtitle,
      };
    }
    return routine.description?.split('\n').first;
  }

  bool _isRunnerOutdoorName(String name) =>
      name == 'Salir a correr' || name == 'Go for a run';

  bool _isRunnerTreadmillName(String name) =>
      name == 'Correr en cinta' || name == 'Treadmill run';

  bool _isHyroxPrepName(String name) =>
      name == 'Hyrox 1 · Prep' || name == 'Hyrox 1 · Preparación';

  bool _isHyroxBuildName(String name) =>
      name == 'Hyrox 2 · Build' || name == 'Hyrox 2 · Progresión';

  bool _isHyroxRaceName(String name) =>
      name == 'Hyrox 3 · Race Day' || name == 'Hyrox 3 · Día de carrera';

  List<String> brokenRecordLabels({
    required bool isVolumeRecord,
    required bool isRepsRecord,
    required bool isMaxWeightRecord,
  }) {
    final records = <String>[];
    if (isVolumeRecord) records.add(recordVolume);
    if (isRepsRecord) records.add(recordReps);
    if (isMaxWeightRecord) records.add(recordMaxWeight);
    return records;
  }

  String restTimerAlertModeLabel(RestTimerAlertMode mode) {
    return switch (mode) {
      RestTimerAlertMode.sound => restTimerAlertSound,
      RestTimerAlertMode.vibration => restTimerAlertVibration,
      RestTimerAlertMode.both => restTimerAlertBoth,
    };
  }

  String mealLabel(MealType meal) {
    return switch (meal) {
      MealType.breakfast => mealBreakfast,
      MealType.lunch => mealLunch,
      MealType.dinner => mealDinner,
      MealType.snack => mealSnack,
    };
  }

  String milestoneTierName(int tier) {
    return switch (tier.clamp(1, 8)) {
      1 => milestoneTierBronze,
      2 => milestoneTierSilver,
      3 => milestoneTierGold,
      4 => milestoneTierPlatinum,
      5 => milestoneTierDiamond,
      6 => milestoneTierMaster,
      7 => milestoneTierGrandmaster,
      8 => milestoneTierLegend,
      _ => milestoneTierBronze,
    };
  }

  String playerLevelBadgeName(int level) {
    return switch (PlayerLevelBadge.tierIndexForLevel(level)) {
      1 => milestoneTierBronze,
      2 => milestoneTierSilver,
      3 => milestoneTierGold,
      4 => milestoneTierPlatinum,
      5 => milestoneTierDiamond,
      6 => milestoneTierMaster,
      7 => milestoneTierGrandmaster,
      8 => milestoneTierLegend,
      9 => playerLevelTierMythic,
      10 => playerLevelTierImmortal,
      _ => milestoneTierBronze,
    };
  }

  /// Rango + nivel numérico, alineado con el emblema mostrado.
  String playerLevelRankSummary(int level) {
    return '${playerLevelBadgeName(level)} · ${playerLevelTitle(level)}';
  }

  String milestoneCategoryLabel(MilestoneCategory category) {
    return switch (category) {
      MilestoneCategory.reps => milestoneCategoryReps,
      MilestoneCategory.volume => milestoneCategoryVolume,
      MilestoneCategory.distance => milestoneCategoryDistance,
      MilestoneCategory.calories => milestoneCategoryCalories,
      MilestoneCategory.workouts => milestoneCategoryWorkouts,
    };
  }

  String feedItemMessage(
    SocialNotification item, {
    String unitSystem = 'kg',
    String? currentUserId,
  }) {
    final isSelf = item.isOwnPost(currentUserId);
    final name = item.actor?.label ?? user;

    if (item.isMilestoneUnlock) {
      final category = item.milestoneCategory;
      final tier = item.milestoneTier ?? 1;
      if (category != null) {
        final categoryLabel = milestoneCategoryLabel(category);
        final tierLabel = milestoneTierName(tier);
        if (isSelf) {
          return feedMilestoneUnlockSelf(categoryLabel, tierLabel);
        }
        return feedMilestoneUnlock(name, categoryLabel, tierLabel);
      }
    }
    if (item.isLevelUp) {
      final level = item.levelReached ?? item.actor?.level ?? 1;
      if (isSelf) return feedLevelUpSelf(level);
      return feedLevelUp(name, level);
    }
    if (item.isPrUnlock) {
      final pr = item.feedPersonalRecord;
      if (pr != null) {
        final value = FeedPersonalRecord.formatValue(pr, unitSystem);
        if (isSelf) return feedPrUnlockSelf(pr.exerciseName, value);
        return feedPrUnlock(name, pr.exerciseName, value);
      }
    }
    if (item.isWorkoutCompleted && isSelf) {
      final workoutName = item.feedWorkoutName ?? item.message;
      return feedWorkoutCompletedSelf(workoutName);
    }
    if (item.isUserPost) {
      final text = item.feedPostText;
      if (text != null && text.isNotEmpty) {
        if (isSelf) return feedUserPostSelf(text);
        return feedUserPost(name, text);
      }
      if (isSelf) return feedUserPostMediaSelf;
      return feedUserPostMedia(name);
    }
    return item.message;
  }

  String friendlyAiError(Object error) {
    if (isConnectionError(error)) return aiConnectionError;
    return errorGeneric('$error');
  }

  String dailyTipBody(String tipId) {
    return _dailyTipLookup[tipId]?.call(this) ?? tipId;
  }

  static final Map<String, String Function(AppLocalizations)> _dailyTipLookup = {
    'general_doms': (l10n) => l10n.dailyTip_general_doms,
    'general_sweat': (l10n) => l10n.dailyTip_general_sweat,
    'general_sleep': (l10n) => l10n.dailyTip_general_sleep,
    'general_spot': (l10n) => l10n.dailyTip_general_spot,
    'general_progressive': (l10n) => l10n.dailyTip_general_progressive,
    'general_bulky': (l10n) => l10n.dailyTip_general_bulky,
    'general_warmup': (l10n) => l10n.dailyTip_general_warmup,
    'general_carbs_night': (l10n) => l10n.dailyTip_general_carbs_night,
    'general_hydration': (l10n) => l10n.dailyTip_general_hydration,
    'general_stretch_cold': (l10n) => l10n.dailyTip_general_stretch_cold,
    'general_scale_daily': (l10n) => l10n.dailyTip_general_scale_daily,
    'general_meal_timing': (l10n) => l10n.dailyTip_general_meal_timing,
    'general_detox': (l10n) => l10n.dailyTip_general_detox,
    'general_rest_days': (l10n) => l10n.dailyTip_general_rest_days,
    'general_form_first': (l10n) => l10n.dailyTip_general_form_first,
    'general_steps': (l10n) => l10n.dailyTip_general_steps,
    'general_fasted_cardio': (l10n) => l10n.dailyTip_general_fasted_cardio,
    'general_bcaa': (l10n) => l10n.dailyTip_general_bcaa,
    'general_creatine': (l10n) => l10n.dailyTip_general_creatine,
    'general_pain_vs_soreness': (l10n) => l10n.dailyTip_general_pain_vs_soreness,
    'general_consistency': (l10n) => l10n.dailyTip_general_consistency,
    'general_track_progress': (l10n) => l10n.dailyTip_general_track_progress,
    'general_fiber': (l10n) => l10n.dailyTip_general_fiber,
    'general_toning_machines': (l10n) => l10n.dailyTip_general_toning_machines,
    'general_sweat_detox': (l10n) => l10n.dailyTip_general_sweat_detox,
    'hypertrophy_failure': (l10n) => l10n.dailyTip_hypertrophy_failure,
    'hypertrophy_confusion': (l10n) => l10n.dailyTip_hypertrophy_confusion,
    'hypertrophy_protein': (l10n) => l10n.dailyTip_hypertrophy_protein,
    'hypertrophy_compounds': (l10n) => l10n.dailyTip_hypertrophy_compounds,
    'hypertrophy_volume': (l10n) => l10n.dailyTip_hypertrophy_volume,
    'hypertrophy_tempo': (l10n) => l10n.dailyTip_hypertrophy_tempo,
    'hypertrophy_pump': (l10n) => l10n.dailyTip_hypertrophy_pump,
    'hypertrophy_frequency': (l10n) => l10n.dailyTip_hypertrophy_frequency,
    'hypertrophy_eccentric': (l10n) => l10n.dailyTip_hypertrophy_eccentric,
    'hypertrophy_mind_muscle': (l10n) => l10n.dailyTip_hypertrophy_mind_muscle,
    'hypertrophy_deload': (l10n) => l10n.dailyTip_hypertrophy_deload,
    'hypertrophy_sleep_growth': (l10n) => l10n.dailyTip_hypertrophy_sleep_growth,
    'strength_rest': (l10n) => l10n.dailyTip_strength_rest,
    'strength_failure': (l10n) => l10n.dailyTip_strength_failure,
    'strength_technique': (l10n) => l10n.dailyTip_strength_technique,
    'strength_specificity': (l10n) => l10n.dailyTip_strength_specificity,
    'strength_belt': (l10n) => l10n.dailyTip_strength_belt,
    'strength_warmup_sets': (l10n) => l10n.dailyTip_strength_warmup_sets,
    'strength_cns': (l10n) => l10n.dailyTip_strength_cns,
    'strength_accessories': (l10n) => l10n.dailyTip_strength_accessories,
    'strength_1rm_test': (l10n) => l10n.dailyTip_strength_1rm_test,
    'strength_grip': (l10n) => l10n.dailyTip_strength_grip,
    'strength_leg_drive': (l10n) => l10n.dailyTip_strength_leg_drive,
    'strength_program_hopping': (l10n) => l10n.dailyTip_strength_program_hopping,
    'fatloss_cardio': (l10n) => l10n.dailyTip_fatloss_cardio,
    'fatloss_strength': (l10n) => l10n.dailyTip_fatloss_strength,
    'fatloss_starve': (l10n) => l10n.dailyTip_fatloss_starve,
    'fatloss_scale': (l10n) => l10n.dailyTip_fatloss_scale,
    'fatloss_cheat_meal': (l10n) => l10n.dailyTip_fatloss_cheat_meal,
    'fatloss_protein': (l10n) => l10n.dailyTip_fatloss_protein,
    'fatloss_neat': (l10n) => l10n.dailyTip_fatloss_neat,
    'fatloss_fat_burn_zone': (l10n) => l10n.dailyTip_fatloss_fat_burn_zone,
    'fatloss_slow_cut': (l10n) => l10n.dailyTip_fatloss_slow_cut,
    'fatloss_liquids': (l10n) => l10n.dailyTip_fatloss_liquids,
    'fatloss_steps': (l10n) => l10n.dailyTip_fatloss_steps,
    'fatloss_sleep': (l10n) => l10n.dailyTip_fatloss_sleep,
    'endurance_easy': (l10n) => l10n.dailyTip_endurance_easy,
    'endurance_more': (l10n) => l10n.dailyTip_endurance_more,
    'endurance_8020': (l10n) => l10n.dailyTip_endurance_8020,
    'endurance_strength': (l10n) => l10n.dailyTip_endurance_strength,
    'endurance_shoes': (l10n) => l10n.dailyTip_endurance_shoes,
    'endurance_hydration': (l10n) => l10n.dailyTip_endurance_hydration,
    'endurance_intervals': (l10n) => l10n.dailyTip_endurance_intervals,
    'endurance_recovery': (l10n) => l10n.dailyTip_endurance_recovery,
    'endurance_taper': (l10n) => l10n.dailyTip_endurance_taper,
    'endurance_only_cardio': (l10n) => l10n.dailyTip_endurance_only_cardio,
    'maintenance_consistency': (l10n) => l10n.dailyTip_maintenance_consistency,
    'maintenance_deload': (l10n) => l10n.dailyTip_maintenance_deload,
    'maintenance_variety': (l10n) => l10n.dailyTip_maintenance_variety,
    'maintenance_microcycles': (l10n) => l10n.dailyTip_maintenance_microcycles,
    'maintenance_mobility': (l10n) => l10n.dailyTip_maintenance_mobility,
    'maintenance_perfect_week': (l10n) => l10n.dailyTip_maintenance_perfect_week,
    'maintenance_habits': (l10n) => l10n.dailyTip_maintenance_habits,
    'maintenance_social': (l10n) => l10n.dailyTip_maintenance_social,
    'maintenance_health': (l10n) => l10n.dailyTip_maintenance_health,
    'maintenance_enjoy': (l10n) => l10n.dailyTip_maintenance_enjoy,
  };
}