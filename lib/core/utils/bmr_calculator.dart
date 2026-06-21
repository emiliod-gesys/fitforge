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
    final weightKg = _resolveWeightKg(profile, snapshots);
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

  static double? _resolveWeightKg(
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

abstract final class BodyMetricCalculator {
  static Map<String, BodyMetricSnapshot> enrich(
    Map<String, BodyMetricSnapshot> snapshots,
    UserProfile? profile,
  ) {
    final bmr = BmrCalculator.calculate(profile: profile, snapshots: snapshots);
    if (bmr == null) {
      return {...snapshots, 'bmr': const BodyMetricSnapshot(type: 'bmr')};
    }

    return {
      ...snapshots,
      'bmr': BodyMetricSnapshot(
        type: 'bmr',
        rawValue: bmr.roundToDouble(),
      ),
    };
  }
}
