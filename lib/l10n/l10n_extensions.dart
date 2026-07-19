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
    return item.message;
  }

  String friendlyAiError(Object error) {
    if (isConnectionError(error)) return aiConnectionError;
    return errorGeneric('$error');
  }
}