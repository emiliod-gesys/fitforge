import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import 'health_body_metric_sample.dart';
import 'health_body_metrics_mapper.dart';

/// Fachada de lectura sobre Apple Health / Health Connect (Fase A: solo lectura).
class HealthIntegrationService {
  HealthIntegrationService({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const readTypes = [
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
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

  Future<bool> hasReadPermissions() async {
    await configure();
    final permissions = readTypes.map((_) => HealthDataAccess.READ).toList();
    final granted = await _health.hasPermissions(readTypes, permissions: permissions);
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
