import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/runner/runner_standards.dart';
import 'health_import_store.dart';
import 'health_integration_service.dart';
import 'health_workout_activity_mapper.dart';

/// Exporta entrenos completados a Apple Health / Health Connect (Fase B).
class HealthWorkoutExporter {
  HealthWorkoutExporter({
    required HealthIntegrationService healthService,
    required HealthImportStore store,
  })  : _health = healthService,
        _store = store;

  final HealthIntegrationService _health;
  final HealthImportStore _store;

  /// Fire-and-forget seguro: no lanza; false si se omitió o falló.
  Future<bool> exportIfEnabled({
    required String workoutId,
    required DateTime startAt,
    required DateTime endAt,
    required int durationMinutes,
    required String title,
    int? activeCaloriesKcal,
    double? distanceMeters,
    bool isRunner = false,
    bool isHyrox = false,
    RunnerType? runnerType,
  }) async {
    if (kIsWeb || workoutId.isEmpty) return false;

    try {
      final prefs = await _store.loadPreferences();
      if (!prefs.connected || !prefs.exportWorkouts) return false;
      if (await _store.wasWorkoutExported(workoutId)) return false;
      if (!await _health.isPlatformSupported()) return false;
      if (!await _health.isHealthConnectAvailable()) return false;

      var hasWrite = await _health.hasWritePermissions();
      if (!hasWrite) {
        hasWrite = await _health.requestWritePermissions();
        if (!hasWrite) return false;
      }

      final start = startAt.toUtc();
      var end = endAt.toUtc();
      if (!end.isAfter(start)) {
        end = start.add(Duration(minutes: math.max(durationMinutes, 1)));
      }

      final activityType = HealthWorkoutActivityMapper.resolve(
        isRunner: isRunner,
        isHyrox: isHyrox,
        runnerType: runnerType,
        isIOS: Platform.isIOS,
      );

      final distance = distanceMeters != null && distanceMeters > 0
          ? distanceMeters.round()
          : null;
      final energy = activeCaloriesKcal != null && activeCaloriesKcal > 0
          ? activeCaloriesKcal
          : null;

      final ok = await _health.exportWorkout(
        activityType: activityType,
        start: start,
        end: end,
        totalEnergyBurnedKcal: energy,
        totalDistanceMeters: distance,
        title: title.trim().isEmpty ? 'FORGEN' : title.trim(),
      );

      if (ok) {
        await _store.markWorkoutExported(workoutId);
      }
      return ok;
    } catch (_) {
      return false;
    }
  }
}
