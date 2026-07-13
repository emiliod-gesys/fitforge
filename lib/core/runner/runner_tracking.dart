import 'dart:math';

import 'runner_models.dart';

abstract final class RunnerTracking {
  static const maxAccuracyMeters = 25.0;
  static const maxAltitudeAccuracyMeters = 30.0;
  /// Mínimo acumulado para confirmar una subida/bajada (filtra ruido GPS).
  static const minElevationStepMeters = 2.5;
  static const minMovementStartMeters = 15.0;
  static const maxSpeedMetersPerSecond = 12.0;
  static const splitDistanceMeters = 1000.0;

  static double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  static bool isValidGpsPoint({
    required double accuracyMeters,
    required double? deltaMeters,
    required int deltaSeconds,
  }) {
    if (accuracyMeters <= 0 || accuracyMeters > maxAccuracyMeters) return false;
    if (deltaMeters == null || deltaSeconds <= 0) return true;
    final speed = deltaMeters / deltaSeconds;
    return speed <= maxSpeedMetersPerSecond;
  }

  static double? paceSecPerKm({required double distanceMeters, required int elapsedSeconds}) {
    if (distanceMeters <= 0 || elapsedSeconds <= 0) return null;
    return elapsedSeconds / (distanceMeters / 1000);
  }

  static double? currentPaceSecPerKm({
    required double distanceMeters,
    required int elapsedSeconds,
    required int windowSeconds,
  }) {
    if (distanceMeters <= 0 || elapsedSeconds <= 0 || windowSeconds <= 0) return null;
    final window = min(elapsedSeconds, windowSeconds);
    if (window <= 0) return null;
    final fraction = window / elapsedSeconds;
    final windowDistance = distanceMeters * fraction;
    return paceSecPerKm(distanceMeters: windowDistance, elapsedSeconds: window);
  }

  static List<RunnerRoutePoint> simplifyRoute(List<RunnerRoutePoint> points, {double minGapMeters = 8}) {
    if (points.length <= 2) return points;
    final out = <RunnerRoutePoint>[points.first];
    for (var i = 1; i < points.length; i++) {
      final prev = out.last;
      final cur = points[i];
      final gap = haversineMeters(prev.lat, prev.lng, cur.lat, cur.lng);
      if (gap >= minGapMeters || i == points.length - 1) {
        out.add(cur);
      }
    }
    return out;
  }

  static bool isValidAltitude({
    required double altitudeMeters,
    required double altitudeAccuracyMeters,
  }) {
    if (altitudeMeters.isNaN || altitudeMeters.isInfinite) return false;
    // 0.0 suele significar "desconocido" en Android; aceptamos si hay lectura horizontal válida.
    if (altitudeAccuracyMeters <= 0) return true;
    return altitudeAccuracyMeters <= maxAltitudeAccuracyMeters;
  }

  /// Acumula pendiente gradual (varios puntos pequeños → una subida real).
  static ({double gain, double loss}) elevationFromRoute(
    List<RunnerRoutePoint> route, {
    double minStepMeters = minElevationStepMeters,
    DateTime? since,
  }) {
    final sinceMs = since?.millisecondsSinceEpoch;
    final filtered = sinceMs == null
        ? route
        : route.where((p) => p.timestampMs >= sinceMs).toList();
    final acc = ElevationAccumulator(minSegmentMeters: minStepMeters);
    for (final point in filtered) {
      final alt = point.alt;
      if (alt != null) acc.addSample(alt);
    }
    acc.finalize();
    return (gain: acc.gain, loss: acc.loss);
  }

  static List<RunnerKmSplit> detectNewSplits({
    required double totalDistanceMeters,
    required int elapsedSeconds,
    required List<RunnerKmSplit> existing,
  }) {
    final completedKm = (totalDistanceMeters / splitDistanceMeters).floor();
    if (completedKm <= existing.length) return const [];

    final splits = <RunnerKmSplit>[];
    for (var km = existing.length + 1; km <= completedKm; km++) {
      splits.add(RunnerKmSplit(km: km, seconds: elapsedSeconds));
    }
    return splits;
  }
}

/// Rastrea desnivel acumulando tramos pequeños hasta superar el umbral.
class ElevationAccumulator {
  final double minSegmentMeters;

  double gain = 0;
  double loss = 0;
  double? _lastAlt;
  double _climb = 0;
  double _descent = 0;

  ElevationAccumulator({this.minSegmentMeters = RunnerTracking.minElevationStepMeters});

  factory ElevationAccumulator.fromRoute(List<RunnerRoutePoint> route) {
    final acc = ElevationAccumulator();
    for (final point in route) {
      final alt = point.alt;
      if (alt != null) acc.addSample(alt);
    }
    return acc;
  }

  void addSample(double alt) {
    if (_lastAlt == null) {
      _lastAlt = alt;
      return;
    }

    final delta = alt - _lastAlt!;
    _lastAlt = alt;

    if (delta > 0) {
      if (_descent > 0) {
        _flushDescent();
        _descent = 0;
      }
      _climb += delta;
    } else if (delta < 0) {
      if (_climb > 0) {
        _flushClimb();
        _climb = 0;
      }
      _descent += -delta;
    }
  }

  void finalize() {
    _flushClimb();
    _flushDescent();
  }

  /// Totales para UI en vivo (incluye tramo pendiente si ya supera 1 m).
  ({double gain, double loss}) liveTotals({double previewMeters = 1.0}) {
    return (
      gain: gain + (_climb >= previewMeters ? _climb : 0),
      loss: loss + (_descent >= previewMeters ? _descent : 0),
    );
  }

  void _flushClimb() {
    if (_climb >= minSegmentMeters) gain += _climb;
    _climb = 0;
  }

  void _flushDescent() {
    if (_descent >= minSegmentMeters) loss += _descent;
    _descent = 0;
  }
}
