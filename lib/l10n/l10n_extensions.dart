import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../models/rest_timer_alert_mode.dart';
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

  String languageLabel(String code) => code == 'en' ? languageEn : languageEs;

  String muscleLabel(String muscle) {
    return switch (muscle) {
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
      _ => muscle,
    };
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

  List<String> get experienceLevels => [expBeginner, expIntermediate, expAdvanced];

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
    return name;
  }

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
}