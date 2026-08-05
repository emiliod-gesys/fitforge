import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import 'health_body_metric_sample.dart';
import 'health_body_metrics_mapper.dart';

/// Fachada Apple Health / Health Connect: lectura de métricas + escritura de entrenos.
class HealthIntegrationService {
  HealthIntegrationService({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const readTypes = [
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
  ];

  static const writeTypes = [
    HealthDataType.WORKOUT,
  ];

  Future<void> configure() async {
    if (_configured || kIsWeb) return;
    await _health.configure();
    _configured = true;
  }

  Future<bool> isPlatformSupported() async {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  Future<bool> isHealthConnectAvailable() async {
    if (!Platform.isAndroid) return true;
    await configure();
    final status = await _health.getHealthConnectSdkStatus();
    return status == HealthConnectSdkStatus.sdkAvailable;
  }

  Future<void> installHealthConnect() async {
    if (Platform.isAndroid) {
      await configure();
      await _health.installHealthConnect();
    }
  }

  Future<bool> requestReadPermissions() async {
    await configure();
    final permissions = readTypes.map((_) => HealthDataAccess.READ).toList();
    return _health.requestAuthorization(readTypes, permissions: permissions);
  }

  Future<bool> requestWritePermissions() async {
    await configure();
    final permissions = writeTypes.map((_) => HealthDataAccess.WRITE).toList();
    return _health.requestAuthorization(writeTypes, permissions: permissions);
  }

  /// Pide lectura (peso/grasa) y escritura (entrenos) en un solo diálogo cuando sea posible.
  Future<bool> requestConnectPermissions({bool includeWrite = true}) async {
    await configure();
    final types = <HealthDataType>[...readTypes];
    final permissions = <HealthDataAccess>[
      ...readTypes.map((_) => HealthDataAccess.READ),
    ];
    if (includeWrite) {
      types.addAll(writeTypes);
      permissions.addAll(writeTypes.map((_) => HealthDataAccess.WRITE));
    }
    return _health.requestAuthorization(types, permissions: permissions);
  }

  Future<bool> hasReadPermissions() =>
      _hasPermissions(readTypes, HealthDataAccess.READ);

  Future<bool> hasWritePermissions() =>
      _hasPermissions(writeTypes, HealthDataAccess.WRITE);

  /// HealthKit nunca revela el estado de LECTURA por privacidad, así que en iOS
  /// `hasPermissions` devuelve `null` incluso con el permiso concedido. Tratar ese
  /// `null` como denegado bloquearía la sincronización para siempre; en su lugar
  /// dejamos pasar y que la propia lectura devuelva vacío si no hay acceso.
  Future<bool> _hasPermissions(
    List<HealthDataType> types,
    HealthDataAccess access,
  ) async {
    await configure();
    final permissions = types.map((_) => access).toList();
    final granted = await _health.hasPermissions(types, permissions: permissions);
    if (granted == null && Platform.isIOS) return true;
    return granted ?? false;
  }

  Future<void> requestHistoryAuthorizationIfNeeded() async {
    if (!Platform.isAndroid) return;
    await configure();
    final authorized = await _health.isHealthDataHistoryAuthorized();
    if (authorized != true) {
      await _health.requestHealthDataHistoryAuthorization();
    }
  }

  Future<List<HealthBodyMetricSample>> fetchBodyMetricSamples({
    required DateTime start,
    required DateTime end,
  }) async {
    await configure();
    if (kIsWeb) return const [];

    final points = await _health.getHealthDataFromTypes(
      types: readTypes,
      startTime: start,
      endTime: end,
    );

    final samples = <HealthBodyMetricSample>[];
    for (final point in points) {
      final mapped = _mapPoint(point);
      if (mapped != null) samples.add(mapped);
    }

    samples.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    return samples;
  }

  Future<bool> exportWorkout({
    required HealthWorkoutActivityType activityType,
    required DateTime start,
    required DateTime end,
    int? totalEnergyBurnedKcal,
    int? totalDistanceMeters,
    String? title,
  }) async {
    await configure();
    if (kIsWeb) return false;

    return _health.writeWorkoutData(
      activityType: activityType,
      start: start,
      end: end,
      totalEnergyBurned: totalEnergyBurnedKcal,
      totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      totalDistance: totalDistanceMeters,
      totalDistanceUnit: HealthDataUnit.METER,
      title: title,
      recordingMethod: RecordingMethod.manual,
    );
  }

  HealthBodyMetricSample? _mapPoint(HealthDataPoint point) {
    final raw = _numericValue(point);
    if (raw == null || raw <= 0) return null;

    final type = switch (point.type) {
      HealthDataType.WEIGHT => 'weight',
      HealthDataType.BODY_FAT_PERCENTAGE => 'body_fat',
      _ => null,
    };
    if (type == null) return null;

    final normalized = type == 'weight'
        ? HealthBodyMetricsMapper.weightToKg(raw, point.unit)
        : HealthBodyMetricsMapper.bodyFatToPercent(raw);
    if (normalized == null) return null;

    final measuredAt = point.dateFrom;
    final sourceKey =
        '${point.type.name}_${measuredAt.toUtc().millisecondsSinceEpoch}_$normalized';

    return HealthBodyMetricSample(
      type: type,
      value: normalized,
      measuredAt: measuredAt,
      sourceKey: sourceKey,
    );
  }

  double? _numericValue(HealthDataPoint point) {
    final raw = point.value;
    if (raw is NumericHealthValue) {
      return raw.numericValue.toDouble();
    }
    return double.tryParse(raw.toString());
  }
}
