import '../../models/body_metric.dart';
import '../../models/profile.dart';

/// Tasa metabólica basal (Mifflin-St Jeor, kcal/día).
abstract final class BmrCalculator {
  static const _minWeightKg = 20.0;
  static const _minHeightCm = 100.0;
  static const _minAge = 10;

  /// Requiere peso, altura, edad y género del perfil.
  static bool canCalculate({
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? snapshots,
  }) {
    return calculate(profile: profile, snapshots: snapshots) != null;
  }

  static double? calculate({
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? snapshots,
  }) {
    final weightKg = resolveWeightKg(profile, snapshots);
    final heightCm = profile?.heightCm;
    final age = profile?.age;
    final gender = profile?.gender;

    if (weightKg == null ||
        heightCm == null ||
        age == null ||
        gender == null ||
        weightKg <= _minWeightKg ||
        heightCm < _minHeightCm ||
        age < _minAge) {
      return null;
    }

    return mifflinStJeor(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );
  }

  static double? resolveWeightKg(
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? snapshots,
  ) {
    final fromMetrics = snapshots?['weight']?.valueKg;
    if (fromMetrics != null && fromMetrics > _minWeightKg) return fromMetrics;

    final fromProfile = profile?.bodyWeight;
    if (fromProfile != null && fromProfile > _minWeightKg) return fromProfile;

    return null;
  }

  /// Mifflin-St Jeor (kcal/día).
  static double mifflinStJeor({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return switch (gender) {
      Gender.female => base - 161,
      Gender.male => base + 5,
      Gender.nonBinary || Gender.preferNotToSay => base - 78,
    };
  }
}

/// Índice de masa corporal (kg/m²) a partir de peso y altura del perfil.
abstract final class BmiCalculator {
  static const _minWeightKg = 20.0;
  static const _minHeightCm = 100.0;

  static double? calculate({
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? snapshots,
  }) {
    final weightKg = BmrCalculator.resolveWeightKg(profile, snapshots);
    final heightCm = profile?.heightCm;
    if (weightKg == null ||
        heightCm == null ||
        weightKg <= _minWeightKg ||
        heightCm < _minHeightCm) {
      return null;
    }

    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }
}

abstract final class BodyMetricCalculator {
  static Map<String, BodyMetricSnapshot> enrich(
    Map<String, BodyMetricSnapshot> snapshots,
    UserProfile? profile,
  ) {
    final enriched = {...snapshots};

    final bmr = BmrCalculator.calculate(profile: profile, snapshots: snapshots);
    enriched['bmr'] = bmr == null
        ? const BodyMetricSnapshot(type: 'bmr')
        : BodyMetricSnapshot(type: 'bmr', rawValue: bmr.roundToDouble());

    final bmi = BmiCalculator.calculate(profile: profile, snapshots: snapshots);
    if (bmi == null) {
      enriched['bmi'] = const BodyMetricSnapshot(type: 'bmi');
    } else {
      final weight = snapshots['weight'];
      double? deltaRaw;
      if (weight?.deltaKg != null && profile?.heightCm != null) {
        final heightM = profile!.heightCm! / 100;
        final previousWeight = weight!.valueKg! - weight.deltaKg!;
        deltaRaw = bmi - (previousWeight / (heightM * heightM));
      }
      enriched['bmi'] = BodyMetricSnapshot(
        type: 'bmi',
        rawValue: double.parse(bmi.toStringAsFixed(1)),
        deltaRaw: deltaRaw != null ? double.parse(deltaRaw.toStringAsFixed(1)) : null,
      );
    }

    return enriched;
  }
}
