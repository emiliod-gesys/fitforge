import '../../models/body_metric.dart';
import '../../models/profile.dart';

/// Meta diaria de agua (ml) según métricas del usuario.
///
/// Fórmula base: ml/kg × peso (35 hombres, 31 mujeres, 33 resto).
/// Si [UserProfile.waterGoalMl] está definido, ese valor gana.
abstract final class WaterGoalCalculator {
  static const int glassMl = 250;
  static const int minGoalMl = 1500;
  static const int maxGoalMl = 4500;
  static const int minCustomMl = 500;
  static const int maxCustomMl = 5000;
  static const int fallbackMaleMl = 2500;
  static const int fallbackFemaleMl = 2000;
  static const int fallbackDefaultMl = 2250;

  /// Onza líquida US.
  static const double mlPerFlOz = 29.5735295625;

  static double mlToFlOz(num ml) => ml / mlPerFlOz;

  static int flOzToMl(double flOz) =>
      (flOz * mlPerFlOz).round().clamp(1, maxCustomMl);

  static String formatVolume(int ml, {required bool useFlOz}) {
    if (useFlOz) {
      final oz = mlToFlOz(ml);
      final text = oz >= 100
          ? oz.toStringAsFixed(0)
          : (oz == oz.roundToDouble()
              ? oz.toStringAsFixed(0)
              : oz.toStringAsFixed(1));
      return '$text oz';
    }
    final liters = ml / 1000;
    if (liters == liters.roundToDouble()) {
      return '${liters.toStringAsFixed(0)} L';
    }
    return '${liters.toStringAsFixed(2)} L';
  }

  static String glassAmountLabel({required bool useFlOz}) {
    if (useFlOz) {
      final oz = mlToFlOz(glassMl);
      return '${oz.toStringAsFixed(1)} oz';
    }
    return '$glassMl ml';
  }

  /// Meta efectiva: override del perfil o sugerencia automática.
  static int goalMl({
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
  }) {
    final override = profile?.waterGoalMl;
    if (override != null &&
        override >= minCustomMl &&
        override <= maxCustomMl) {
      return override;
    }
    return suggestedGoalMl(profile: profile, bodyMetrics: bodyMetrics);
  }

  /// Sugerencia de la app (ignora override del usuario).
  static int suggestedGoalMl({
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
  }) {
    final weightKg = _resolveWeightKg(profile, bodyMetrics);
    final gender = profile?.gender;
    final age = profile?.effectiveAge;

    if (weightKg != null) {
      final mlPerKg = switch (gender) {
        Gender.male => 35.0,
        Gender.female => 31.0,
        _ => 33.0,
      };
      var goal = (weightKg * mlPerKg).round();
      if (age != null && age >= 55) {
        goal = (goal * 0.95).round();
      }
      return goal.clamp(minGoalMl, maxGoalMl);
    }

    return switch (gender) {
      Gender.male => fallbackMaleMl,
      Gender.female => fallbackFemaleMl,
      _ => fallbackDefaultMl,
    };
  }

  static WaterGoalWarning? evaluate({
    required int selectedMl,
    required int suggestedMl,
  }) {
    if (selectedMl < 1200 || selectedMl < suggestedMl * 0.7) {
      return WaterGoalWarning.tooLow;
    }
    if (selectedMl > 4000 || selectedMl > suggestedMl * 1.5) {
      return WaterGoalWarning.tooHigh;
    }
    return null;
  }

  static int glassesTowardGoal(int intakeMl, int goalMl) {
    if (goalMl <= 0) return 0;
    return (intakeMl / glassMl).floor();
  }

  static int glassesForGoal(int goalMl) {
    if (goalMl <= 0) return 0;
    return (goalMl / glassMl).ceil();
  }

  static double? _resolveWeightKg(
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? metrics,
  ) {
    final fromMetrics = metrics?['weight']?.valueKg;
    if (fromMetrics != null && fromMetrics > 20) return fromMetrics;
    final fromProfile = profile?.bodyWeight;
    if (fromProfile != null && fromProfile > 20) return fromProfile;
    return null;
  }
}

enum WaterGoalWarning {
  tooLow,
  tooHigh,
}
