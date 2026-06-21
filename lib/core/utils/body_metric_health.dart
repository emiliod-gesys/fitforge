import 'package:flutter/material.dart';
import '../../models/body_metric.dart';
import '../../models/profile.dart';
import 'bmr_calculator.dart';

/// Nivel de salud de una métrica corporal respecto a rangos recomendados.
enum BodyMetricHealthLevel {
  veryLow,
  low,
  appropriate,
  ideal,
  high,
  veryBad,
}

abstract final class BodyMetricHealthColors {
  static const veryLow = Color(0xFF1E88E5);
  static const low = Color(0xFF4FC3F7);
  static const appropriate = Color(0xFF81C784);
  static const ideal = Color(0xFF2E7D32);
  static const high = Color(0xFFFFB300);
  static const veryBad = Color(0xFFE53935);

  static Color forLevel(BodyMetricHealthLevel level) {
    return switch (level) {
      BodyMetricHealthLevel.veryLow => veryLow,
      BodyMetricHealthLevel.low => low,
      BodyMetricHealthLevel.appropriate => appropriate,
      BodyMetricHealthLevel.ideal => ideal,
      BodyMetricHealthLevel.high => high,
      BodyMetricHealthLevel.veryBad => veryBad,
    };
  }
}

/// Evalúa métricas corporales con rangos orientativos (edad, sexo, peso, talla).
abstract final class BodyMetricHealthEvaluator {
  static Color colorFor({
    required String key,
    required BodyMetricSnapshot snapshot,
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? snapshots,
  }) {
    if (!snapshot.hasValue) return Colors.white38;

    final level = evaluate(
      key: key,
      snapshot: snapshot,
      profile: profile,
      snapshots: snapshots,
    );
    if (level == null) return BodyMetricHealthColors.appropriate;
    return BodyMetricHealthColors.forLevel(level);
  }

  static BodyMetricHealthLevel? evaluate({
    required String key,
    required BodyMetricSnapshot snapshot,
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? snapshots,
  }) {
    final gender = profile?.gender;
    final age = profile?.age;
    final heightCm = profile?.heightCm;
    final weightKg = _weightKg(profile, snapshots);

    return switch (key) {
      'bmi' => _evaluateBmi(snapshot.rawValue!),
      'weight' => _evaluateWeight(snapshot.valueKg!, heightCm),
      'body_fat' => _evaluateBodyFat(snapshot.rawValue!, gender, subcutaneous: false),
      'subcutaneous_fat' => _evaluateBodyFat(snapshot.rawValue!, gender, subcutaneous: true),
      'skeletal_muscle' => _evaluateSkeletalMuscle(snapshot.rawValue!, gender),
      'body_water' => _evaluateBodyWater(snapshot.rawValue!, gender),
      'protein' => _evaluateProtein(snapshot.rawValue!),
      'visceral_fat' => _evaluateVisceralFat(snapshot.rawValue!),
      'metabolic_age' => age != null ? _evaluateMetabolicAge(snapshot.rawValue!, age) : null,
      'bmr' => _evaluateBmr(snapshot.rawValue!, profile, snapshots),
      'muscle_mass' => weightKg != null
          ? _evaluateMuscleMassRatio(snapshot.valueKg! / weightKg, gender)
          : null,
      'bone_mass' => weightKg != null
          ? _evaluateBoneMassRatio(snapshot.valueKg! / weightKg * 100, gender)
          : null,
      'fat_free_mass' => weightKg != null
          ? _evaluateFatFreeMassRatio(snapshot.valueKg! / weightKg * 100, gender)
          : null,
      _ => null,
    };
  }

  static double? _weightKg(UserProfile? profile, Map<String, BodyMetricSnapshot>? snapshots) {
    final fromMetrics = snapshots?['weight']?.valueKg;
    if (fromMetrics != null && fromMetrics > 20) return fromMetrics;
    final fromProfile = profile?.bodyWeight;
    if (fromProfile != null && fromProfile > 20) return fromProfile;
    return null;
  }

  static BodyMetricHealthLevel _evaluateBmi(double bmi) {
    if (bmi < 16) return BodyMetricHealthLevel.veryBad;
    if (bmi < 17) return BodyMetricHealthLevel.veryLow;
    if (bmi < 18.5) return BodyMetricHealthLevel.low;
    if (bmi < 21.5) return BodyMetricHealthLevel.appropriate;
    if (bmi <= 24.9) return BodyMetricHealthLevel.ideal;
    if (bmi < 27) return BodyMetricHealthLevel.high;
    if (bmi < 30) return BodyMetricHealthLevel.high;
    return BodyMetricHealthLevel.veryBad;
  }

  static BodyMetricHealthLevel? _evaluateWeight(double weightKg, double? heightCm) {
    if (heightCm != null && heightCm >= 100) {
      final bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
      return _evaluateBmi(bmi);
    }
    return null;
  }

  static BodyMetricHealthLevel _evaluateBodyFat(
    double pct,
    Gender? gender, {
    required bool subcutaneous,
  }) {
    final female = gender == Gender.female;
    if (subcutaneous) {
      if (female) {
        if (pct < 12) return BodyMetricHealthLevel.veryLow;
        if (pct < 16) return BodyMetricHealthLevel.low;
        if (pct <= 22) return BodyMetricHealthLevel.ideal;
        if (pct <= 28) return BodyMetricHealthLevel.appropriate;
        if (pct <= 34) return BodyMetricHealthLevel.high;
        return BodyMetricHealthLevel.veryBad;
      }
      if (pct < 6) return BodyMetricHealthLevel.veryLow;
      if (pct < 9) return BodyMetricHealthLevel.low;
      if (pct <= 14) return BodyMetricHealthLevel.ideal;
      if (pct <= 18) return BodyMetricHealthLevel.appropriate;
      if (pct <= 24) return BodyMetricHealthLevel.high;
      return BodyMetricHealthLevel.veryBad;
    }

    if (female) {
      if (pct < 12) return BodyMetricHealthLevel.veryLow;
      if (pct < 16) return BodyMetricHealthLevel.low;
      if (pct <= 22) return BodyMetricHealthLevel.ideal;
      if (pct <= 28) return BodyMetricHealthLevel.appropriate;
      if (pct <= 33) return BodyMetricHealthLevel.high;
      return BodyMetricHealthLevel.veryBad;
    }

    if (pct < 5) return BodyMetricHealthLevel.veryLow;
    if (pct < 8) return BodyMetricHealthLevel.low;
    if (pct <= 14) return BodyMetricHealthLevel.ideal;
    if (pct <= 18) return BodyMetricHealthLevel.appropriate;
    if (pct <= 25) return BodyMetricHealthLevel.high;
    return BodyMetricHealthLevel.veryBad;
  }

  static BodyMetricHealthLevel _evaluateSkeletalMuscle(double pct, Gender? gender) {
    final female = gender == Gender.female;
    if (female) {
      if (pct < 24) return BodyMetricHealthLevel.veryLow;
      if (pct < 28) return BodyMetricHealthLevel.low;
      if (pct <= 34) return BodyMetricHealthLevel.appropriate;
      if (pct <= 38) return BodyMetricHealthLevel.ideal;
      if (pct <= 42) return BodyMetricHealthLevel.high;
      return BodyMetricHealthLevel.veryBad;
    }
    if (pct < 28) return BodyMetricHealthLevel.veryLow;
    if (pct < 32) return BodyMetricHealthLevel.low;
    if (pct <= 38) return BodyMetricHealthLevel.appropriate;
    if (pct <= 42) return BodyMetricHealthLevel.ideal;
    if (pct <= 46) return BodyMetricHealthLevel.high;
    return BodyMetricHealthLevel.veryBad;
  }

  static BodyMetricHealthLevel _evaluateBodyWater(double pct, Gender? gender) {
    final female = gender == Gender.female;
    if (female) {
      if (pct < 42) return BodyMetricHealthLevel.veryBad;
      if (pct < 45) return BodyMetricHealthLevel.veryLow;
      if (pct < 48) return BodyMetricHealthLevel.low;
      if (pct <= 54) return BodyMetricHealthLevel.appropriate;
      if (pct <= 58) return BodyMetricHealthLevel.ideal;
      if (pct <= 62) return BodyMetricHealthLevel.high;
      return BodyMetricHealthLevel.veryBad;
    }
    if (pct < 48) return BodyMetricHealthLevel.veryBad;
    if (pct < 50) return BodyMetricHealthLevel.veryLow;
    if (pct < 53) return BodyMetricHealthLevel.low;
    if (pct <= 58) return BodyMetricHealthLevel.appropriate;
    if (pct <= 63) return BodyMetricHealthLevel.ideal;
    if (pct <= 67) return BodyMetricHealthLevel.high;
    return BodyMetricHealthLevel.veryBad;
  }

  static BodyMetricHealthLevel _evaluateProtein(double pct) {
    if (pct < 13) return BodyMetricHealthLevel.veryLow;
    if (pct < 15) return BodyMetricHealthLevel.low;
    if (pct <= 17) return BodyMetricHealthLevel.appropriate;
    if (pct <= 19) return BodyMetricHealthLevel.ideal;
    if (pct <= 21) return BodyMetricHealthLevel.high;
    return BodyMetricHealthLevel.veryBad;
  }

  static BodyMetricHealthLevel _evaluateVisceralFat(double score) {
    if (score <= 4) return BodyMetricHealthLevel.ideal;
    if (score <= 7) return BodyMetricHealthLevel.appropriate;
    if (score <= 10) return BodyMetricHealthLevel.high;
    if (score <= 14) return BodyMetricHealthLevel.high;
    return BodyMetricHealthLevel.veryBad;
  }

  static BodyMetricHealthLevel _evaluateMetabolicAge(double metabolicAge, int chronologicalAge) {
    final diff = metabolicAge - chronologicalAge;
    if (diff <= -8) return BodyMetricHealthLevel.low;
    if (diff <= -4) return BodyMetricHealthLevel.ideal;
    if (diff <= 0) return BodyMetricHealthLevel.appropriate;
    if (diff <= 4) return BodyMetricHealthLevel.high;
    if (diff <= 8) return BodyMetricHealthLevel.high;
    return BodyMetricHealthLevel.veryBad;
  }

  static BodyMetricHealthLevel? _evaluateBmr(
    double bmr,
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? snapshots,
  ) {
    final reference = BmrCalculator.calculate(profile: profile, snapshots: snapshots);
    if (reference == null || reference <= 0) return null;

    final ratio = bmr / reference;
    if (ratio < 0.82) return BodyMetricHealthLevel.veryLow;
    if (ratio < 0.92) return BodyMetricHealthLevel.low;
    if (ratio < 0.97) return BodyMetricHealthLevel.appropriate;
    if (ratio <= 1.03) return BodyMetricHealthLevel.ideal;
    if (ratio <= 1.12) return BodyMetricHealthLevel.high;
    return BodyMetricHealthLevel.veryBad;
  }

  static BodyMetricHealthLevel _evaluateMuscleMassRatio(double ratio, Gender? gender) {
    final pct = ratio * 100;
    final female = gender == Gender.female;
    if (female) {
      if (pct < 28) return BodyMetricHealthLevel.veryLow;
      if (pct < 32) return BodyMetricHealthLevel.low;
      if (pct <= 38) return BodyMetricHealthLevel.appropriate;
      if (pct <= 42) return BodyMetricHealthLevel.ideal;
      if (pct <= 46) return BodyMetricHealthLevel.high;
      return BodyMetricHealthLevel.veryBad;
    }
    if (pct < 32) return BodyMetricHealthLevel.veryLow;
    if (pct < 36) return BodyMetricHealthLevel.low;
    if (pct <= 44) return BodyMetricHealthLevel.appropriate;
    if (pct <= 52) return BodyMetricHealthLevel.ideal;
    if (pct <= 58) return BodyMetricHealthLevel.high;
    return BodyMetricHealthLevel.veryBad;
  }

  static BodyMetricHealthLevel _evaluateBoneMassRatio(double pct, Gender? gender) {
    final female = gender == Gender.female;
    if (female) {
      if (pct < 2.0) return BodyMetricHealthLevel.veryLow;
      if (pct < 2.4) return BodyMetricHealthLevel.low;
      if (pct <= 3.0) return BodyMetricHealthLevel.appropriate;
      if (pct <= 3.6) return BodyMetricHealthLevel.ideal;
      if (pct <= 4.2) return BodyMetricHealthLevel.high;
      return BodyMetricHealthLevel.veryBad;
    }
    if (pct < 2.5) return BodyMetricHealthLevel.veryLow;
    if (pct < 3.0) return BodyMetricHealthLevel.low;
    if (pct <= 3.8) return BodyMetricHealthLevel.appropriate;
    if (pct <= 4.5) return BodyMetricHealthLevel.ideal;
    if (pct <= 5.0) return BodyMetricHealthLevel.high;
    return BodyMetricHealthLevel.veryBad;
  }

  static BodyMetricHealthLevel _evaluateFatFreeMassRatio(double pct, Gender? gender) {
    final female = gender == Gender.female;
    if (female) {
      if (pct < 62) return BodyMetricHealthLevel.veryLow;
      if (pct < 68) return BodyMetricHealthLevel.low;
      if (pct <= 76) return BodyMetricHealthLevel.appropriate;
      if (pct <= 82) return BodyMetricHealthLevel.ideal;
      if (pct <= 88) return BodyMetricHealthLevel.high;
      return BodyMetricHealthLevel.veryBad;
    }
    if (pct < 68) return BodyMetricHealthLevel.veryLow;
    if (pct < 74) return BodyMetricHealthLevel.low;
    if (pct <= 82) return BodyMetricHealthLevel.appropriate;
    if (pct <= 88) return BodyMetricHealthLevel.ideal;
    if (pct <= 92) return BodyMetricHealthLevel.high;
    return BodyMetricHealthLevel.veryBad;
  }
}
