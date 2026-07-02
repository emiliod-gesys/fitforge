import 'package:flutter/material.dart';
import 'package:flutter_body_heatmap/flutter_body_heatmap.dart';

/// Convierte % de recuperación de FitForge a intensidad del mapa muscular.
abstract final class BodyMannequinMapper {
  static const _recoveryThreshold = 88.0;

  static const _groupToMuscles = <String, List<Muscle>>{
    'Pecho': [Muscle.chest],
    'Espalda': [Muscle.upperBack, Muscle.lowerBack, Muscle.trapezius],
    'Hombros': [Muscle.deltoids],
    'Bíceps': [Muscle.biceps],
    'Tríceps': [Muscle.triceps],
    'Piernas': [
      Muscle.quadriceps,
      Muscle.hamstring,
      Muscle.calves,
      Muscle.adductors,
      Muscle.tibialis,
    ],
    'Glúteos': [Muscle.gluteal],
    'Abdominales': [Muscle.abs, Muscle.obliques],
    'Antebrazos': [Muscle.forearm],
  };

  static Map<Muscle, MuscleData> toHeatmapData(
    Map<String, double> recovery, {
    String? focusGroup,
  }) {
    final data = <Muscle, MuscleData>{};

    recovery.forEach((group, percent) {
      var intensity = _fatigueIntensity(percent);
      if (intensity <= 0 && focusGroup != group) return;

      if (focusGroup != null) {
        intensity = group == focusGroup ? intensity.clamp(0.45, 1.0) : intensity * 0.2;
      }
      if (intensity <= 0) return;

      final muscles = _groupToMuscles[group];
      if (muscles == null) return;

      for (final muscle in muscles) {
        final existing = data[muscle]?.intensity ?? 0;
        if (intensity > existing) {
          data[muscle] = MuscleData(intensity: intensity);
        }
      }
    });

    return data;
  }

  static double _fatigueIntensity(double recoveryPercent) {
    if (recoveryPercent >= _recoveryThreshold) return 0;
    return ((100 - recoveryPercent) / 100).clamp(0.0, 1.0);
  }
}
