import '../../models/workout.dart';
import '../../models/body_metric.dart';
import '../../models/profile.dart';
import 'bmr_calculator.dart';

/// Estimación de **calorías activas netas** al finalizar un entrenamiento.
///
/// Basado en:
/// - Compendium of Physical Activities (MET para entrenamiento con pesas, 3.5–6.0)
/// - Carrera/caminata según ritmo (MET ~4–12)
/// - Resta el gasto basal de la misma ventana (TMB/24) para no duplicar lo ya
///   incluido en la meta diaria de Comida
/// - Intensidad inferida por volumen y series por minuto
abstract final class WorkoutCalorieEstimator {
  static const _defaultWeightKg = 70.0;

  static WorkoutCalorieEstimate estimate({
    required int durationMinutes,
    required double totalVolumeKg,
    required int completedSets,
    required int totalReps,
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
    int cardioDurationSeconds = 0,
    double? runningPaceSecPerKm,
  }) {
    return _estimateInternal(
      durationMinutes: durationMinutes,
      totalVolumeKg: totalVolumeKg,
      completedSets: completedSets,
      totalReps: totalReps,
      profile: profile,
      bodyMetrics: bodyMetrics,
      cardioDurationSeconds: cardioDurationSeconds,
      runningPaceSecPerKm: runningPaceSecPerKm,
    );
  }

  static WorkoutCalorieEstimate estimateForWorkout({
    required Workout workout,
    required int durationMinutes,
    required double totalVolumeKg,
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
  }) {
    final completedSets = workout.exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.sets.where((s) => s.completed).length,
    );
    final totalReps = workout.exercises.fold<int>(
      0,
      (sum, ex) => sum +
          ex.sets
              .where((s) => s.completed)
              .fold<int>(0, (setSum, s) => setSum + s.reps),
    );
    final cardioDurationSeconds = completedCardioDurationSeconds(workout);
    final resolvedDuration = resolveDurationMinutes(
      workout: workout,
      wallClockMinutes: durationMinutes,
    );
    final runningPaceSecPerKm =
        workout.runnerAvgPaceSecPerKm ?? _paceFromCardioSets(workout);

    return estimate(
      durationMinutes: resolvedDuration,
      totalVolumeKg: totalVolumeKg,
      completedSets: completedSets,
      totalReps: totalReps,
      profile: profile,
      bodyMetrics: bodyMetrics,
      cardioDurationSeconds: cardioDurationSeconds,
      runningPaceSecPerKm: runningPaceSecPerKm,
    );
  }

  /// Usa kcal guardadas al completar el entreno; si no hay, estima desde resumen.
  static int resolvedActiveCalories({
    required Workout workout,
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
  }) {
    final stored = workout.activeCaloriesKcal;
    if (stored != null && stored > 0) return stored;

    if (workout.exercises.isNotEmpty) {
      final estimate = estimateForWorkout(
        workout: workout,
        durationMinutes: workout.durationMinutes,
        totalVolumeKg: workout.totalVolume,
        profile: profile,
        bodyMetrics: bodyMetrics,
      );
      return estimate.caloriesKcal ?? 0;
    }

    return estimateFromSummary(
      durationMinutes: workout.durationMinutes,
      totalVolumeKg: workout.totalVolume,
      profile: profile,
      bodyMetrics: bodyMetrics,
    ).caloriesKcal ??
        0;
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

  static int completedCardioDurationSeconds(Workout workout) {
    return workout.exercises
        .expand((ex) => ex.sets)
        .where((s) => s.completed && s.isCardio)
        .map((s) => s.durationSeconds ?? 0)
        .fold<int>(0, (sum, seconds) => sum + seconds);
  }

  static int resolveDurationMinutes({
    required Workout workout,
    required int wallClockMinutes,
  }) {
    if (wallClockMinutes >= 1) return wallClockMinutes;

    final cardioSeconds = completedCardioDurationSeconds(workout);
    if (cardioSeconds >= 60) {
      return (cardioSeconds / 60).ceil().clamp(1, 999);
    }

    return wallClockMinutes;
  }

  static WorkoutCalorieEstimate _estimateInternal({
    required int durationMinutes,
    required double totalVolumeKg,
    required int completedSets,
    required int totalReps,
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
    int cardioDurationSeconds = 0,
    double? runningPaceSecPerKm,
  }) {
    if (cardioDurationSeconds >= 60 && durationMinutes < 1) {
      durationMinutes = (cardioDurationSeconds / 60).ceil().clamp(1, 999);
    }

    if (durationMinutes < 1 ||
        (completedSets < 1 && cardioDurationSeconds < 60)) {
      return const WorkoutCalorieEstimate.unavailable();
    }

    final weight = _resolveWeightKg(profile, bodyMetrics);
    final usedDefaultWeight = weight.fromDefault;
    final weightKg = weight.kg;

    final bmr = BmrCalculator.calculate(profile: profile, snapshots: bodyMetrics);
    final cardioFraction = cardioDurationSeconds >= 60
        ? ((cardioDurationSeconds / 60) / durationMinutes).clamp(0.0, 1.0)
        : 0.0;
    final isRunningDominant = cardioFraction >= 0.8 && runningPaceSecPerKm != null;

    final met = isRunningDominant
        ? runningMetFromPaceSecPerKm(runningPaceSecPerKm!)
        : _resolveMet(
            totalVolumeKg: totalVolumeKg,
            durationMinutes: durationMinutes,
            completedSets: completedSets,
            totalReps: totalReps,
            cardioDurationSeconds: cardioDurationSeconds,
          );

    final durationHours = durationMinutes / 60.0;
    final grossKcal = met * weightKg * durationHours;

    // Reposo durante la sesión: ya cubierto por TMB/TDEE en la meta diaria.
    final restingDuringSession = bmr != null
        ? (bmr / 24.0) * durationHours
        : weightKg * durationHours;

    var activeKcal = grossKcal - restingDuringSession;
    if (activeKcal < 0) activeKcal = 0;

    // Componente mecánico menor (trabajo de desplazamiento de carga).
    if (!isRunningDominant) {
      final mechanical = (totalVolumeKg * 0.00045).clamp(0.0, grossKcal * 0.12);
      activeKcal += mechanical;
    }

    return WorkoutCalorieEstimate(
      caloriesKcal: activeKcal.round().clamp(1, 9999),
      usedDefaultWeight: usedDefaultWeight,
      met: met,
    );
  }

  static double _resolveMet({
    required double totalVolumeKg,
    required int durationMinutes,
    required int completedSets,
    required int totalReps,
    required int cardioDurationSeconds,
  }) {
    var met = _intensityMet(
      totalVolumeKg: totalVolumeKg,
      durationMinutes: durationMinutes,
      completedSets: completedSets,
      totalReps: totalReps,
    );
    if (cardioDurationSeconds >= 60) {
      const cardioMet = 7.0;
      final cardioFraction =
          ((cardioDurationSeconds / 60) / durationMinutes).clamp(0.0, 1.0);
      met = met * (1 - cardioFraction) + cardioMet * cardioFraction;
    }
    return met;
  }

  static double? _paceFromCardioSets(Workout workout) {
    double? bestPace;
    for (final set in workout.exercises.expand((ex) => ex.sets)) {
      if (!set.completed || !set.isCardio) continue;
      final seconds = set.durationSeconds;
      final meters = set.distanceMeters;
      if (seconds == null || seconds < 30 || meters == null || meters <= 0) {
        continue;
      }
      final pace = seconds / (meters / 1000);
      if (bestPace == null || pace < bestPace) bestPace = pace;
    }
    return bestPace;
  }

  /// MET orientativo según ritmo (Compendium of Physical Activities).
  static double runningMetFromPaceSecPerKm(double paceSecPerKm) {
    if (paceSecPerKm <= 0) return 9.0;

    final speedKmh = 3600 / paceSecPerKm;
    if (speedKmh < 4) return 3.5;
    if (speedKmh < 6) return 4.3 + (speedKmh - 4) * 0.85;
    if (speedKmh < 8) return 6.0 + (speedKmh - 6) * 1.15;
    if (speedKmh < 10) return 8.3 + (speedKmh - 8) * 0.75;
    if (speedKmh < 12) return 9.8 + (speedKmh - 10) * 0.6;
    return 11.8;
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
