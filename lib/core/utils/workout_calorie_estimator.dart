import '../../models/body_metric.dart';
import '../../models/profile.dart';

/// Estimación de gasto calórico al finalizar un entrenamiento de fuerza.
///
/// Basado en:
/// - Compendium of Physical Activities (MET para entrenamiento con pesas, 3.5–6.0)
/// - Ecuación de Mifflin-St Jeor para ajuste metabólico (edad, sexo, peso, talla)
/// - Intensidad inferida por volumen y series por minuto
abstract final class WorkoutCalorieEstimator {
  static const _defaultWeightKg = 70.0;
  static const _defaultHeightCm = 170.0;
  static const _defaultAge = 30;

  static WorkoutCalorieEstimate estimate({
    required int durationMinutes,
    required double totalVolumeKg,
    required int completedSets,
    required int totalReps,
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
  }) {
    return _estimateInternal(
      durationMinutes: durationMinutes,
      totalVolumeKg: totalVolumeKg,
      completedSets: completedSets,
      totalReps: totalReps,
      profile: profile,
      bodyMetrics: bodyMetrics,
    );
  }

  /// Estimación a partir del resumen guardado (sin detalle de series).
  static WorkoutCalorieEstimate estimateFromSummary({
    required int durationMinutes,
    required double totalVolumeKg,
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
  }) {
    if (durationMinutes < 1) {
      return const WorkoutCalorieEstimate.unavailable();
    }
    final estimatedSets = (durationMinutes / 2.5).round().clamp(1, 80);
    final avgRepsPerSet = totalVolumeKg > 0
        ? (totalVolumeKg / estimatedSets / 40).clamp(4, 12).round()
        : 8;
    return _estimateInternal(
      durationMinutes: durationMinutes,
      totalVolumeKg: totalVolumeKg,
      completedSets: estimatedSets,
      totalReps: estimatedSets * avgRepsPerSet,
      profile: profile,
      bodyMetrics: bodyMetrics,
    );
  }

  static WorkoutCalorieEstimate _estimateInternal({
    required int durationMinutes,
    required double totalVolumeKg,
    required int completedSets,
    required int totalReps,
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
  }) {
    if (durationMinutes < 1 || completedSets < 1) {
      return const WorkoutCalorieEstimate.unavailable();
    }

    final weight = _resolveWeightKg(profile, bodyMetrics);
    final usedDefaultWeight = weight.fromDefault;
    final weightKg = weight.kg;

    final bmr = _resolveBmr(profile, bodyMetrics, weightKg);
    final met = _intensityMet(
      totalVolumeKg: totalVolumeKg,
      durationMinutes: durationMinutes,
      completedSets: completedSets,
      totalReps: totalReps,
    );

    final durationHours = durationMinutes / 60.0;
    var kcal = met * weightKg * durationHours;

    if (bmr != null) {
      final referenceBmr = _mifflinStJeor(
        weightKg: 70,
        heightCm: 175,
        age: 30,
        gender: Gender.male,
      );
      final factor = (bmr / referenceBmr).clamp(0.88, 1.12);
      kcal *= factor;
    }

    // Componente mecánico menor (trabajo de desplazamiento de carga).
    final mechanical = (totalVolumeKg * 0.00045).clamp(0.0, kcal * 0.12);
    kcal += mechanical;

    return WorkoutCalorieEstimate(
      caloriesKcal: kcal.round().clamp(1, 9999),
      usedDefaultWeight: usedDefaultWeight,
      met: met,
    );
  }

  static _WeightSource _resolveWeightKg(
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
  ) {
    final fromMetrics = bodyMetrics?['weight']?.valueKg;
    if (fromMetrics != null && fromMetrics > 20) {
      return _WeightSource(fromMetrics, fromDefault: false);
    }
    final fromProfile = profile?.bodyWeight;
    if (fromProfile != null && fromProfile > 20) {
      return _WeightSource(fromProfile, fromDefault: false);
    }
    return const _WeightSource(_defaultWeightKg, fromDefault: true);
  }

  static double? _resolveBmr(
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
    double weightKg,
  ) {
    final stored = bodyMetrics?['bmr']?.rawValue;
    if (stored != null && stored > 500) return stored;

    final height = profile?.heightCm ?? _defaultHeightCm;
    final age = profile?.age ?? _defaultAge;
    final gender = profile?.gender;
    if (height < 100 || age < 10) return null;

    return _mifflinStJeor(
      weightKg: weightKg,
      heightCm: height,
      age: age,
      gender: gender,
    );
  }

  /// Mifflin-St Jeor (kcal/día).
  static double _mifflinStJeor({
    required double weightKg,
    required double heightCm,
    required int age,
    Gender? gender,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return switch (gender) {
      Gender.female => base - 161,
      Gender.male => base + 5,
      Gender.nonBinary || Gender.preferNotToSay || null => base - 78,
    };
  }

  /// MET 3.5 (moderado) – 6.0 (vigoroso) según densidad de trabajo.
  static double _intensityMet({
    required double totalVolumeKg,
    required int durationMinutes,
    required int completedSets,
    required int totalReps,
  }) {
    const baseMet = 3.5;
    const maxMet = 6.0;

    final volumePerMin = totalVolumeKg / durationMinutes;
    final setsPerMin = completedSets / durationMinutes;
    final repsPerMin = totalReps / durationMinutes;

    final volumeFactor = ((volumePerMin - 40) / 150).clamp(0.0, 1.0);
    final paceFactor = ((setsPerMin - 0.12) / 0.4).clamp(0.0, 1.0);
    final repFactor = ((repsPerMin - 4) / 16).clamp(0.0, 1.0);

    final intensity = volumeFactor * 0.45 + paceFactor * 0.35 + repFactor * 0.2;
    return baseMet + intensity * (maxMet - baseMet);
  }
}

class WorkoutCalorieEstimate {
  final int? caloriesKcal;
  final bool usedDefaultWeight;
  final double? met;

  const WorkoutCalorieEstimate({
    required this.caloriesKcal,
    this.usedDefaultWeight = false,
    this.met,
  });

  const WorkoutCalorieEstimate.unavailable()
      : caloriesKcal = null,
        usedDefaultWeight = false,
        met = null;

  bool get isAvailable => caloriesKcal != null;
}

class _WeightSource {
  final double kg;
  final bool fromDefault;

  const _WeightSource(this.kg, {required this.fromDefault});
}
