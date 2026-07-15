import 'package:flutter/material.dart';
import '../../models/body_metric.dart';
import '../../models/profile.dart';
import '../theme/app_colors.dart';
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
  /// Métricas que muestran valor con color según rango de salud.
  static const colorCodedMetricKeys = {
    'weight',
    'bmi',
    'body_fat',
  };

  static bool usesColorCoding(String key) => colorCodedMetricKeys.contains(key);

  static Color colorFor({
    required String key,
    required BodyMetricSnapshot snapshot,
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? snapshots,
  }) {
    if (!snapshot.hasValue) return AppColors.textMuted;
    if (!usesColorCoding(key)) return AppColors.textPrimary;

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
    final heightCm = profile?.heightCm;

    return switch (key) {
      'bmi' => _evaluateBmi(snapshot.rawValue!),
      'weight' => _evaluateWeight(snapshot.valueKg!, heightCm),
      'body_fat' => _evaluateBodyFat(snapshot.rawValue!, gender),
      'bmr' => _evaluateBmr(snapshot.rawValue!, profile, snapshots),
      _ => null,
    };
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

  static BodyMetricHealthLevel _evaluateBodyFat(double pct, Gender? gender) {
    final female = gender == Gender.female;

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
}
