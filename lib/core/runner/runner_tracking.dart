import 'dart:math';

import 'runner_models.dart';

abstract final class RunnerTracking {
  static const maxAccuracyMeters = 25.0;
  static const maxAltitudeAccuracyMeters = 30.0;
  static const minElevationStepMeters = 4.0;
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
    if (altitudeAccuracyMeters < 0) return true;
    return altitudeAccuracyMeters <= maxAltitudeAccuracyMeters;
  }

  static ({double gain, double loss}) elevationDelta({
    required double? previousAlt,
    required double currentAlt,
    double minStepMeters = minElevationStepMeters,
  }) {
    if (previousAlt == null) return (gain: 0, loss: 0);
    final delta = currentAlt - previousAlt;
    if (delta >= minStepMeters) return (gain: delta, loss: 0);
    if (delta <= -minStepMeters) return (gain: 0, loss: -delta);
    return (gain: 0, loss: 0);
  }

  static ({double gain, double loss}) elevationFromRoute(
    List<RunnerRoutePoint> route, {
    double minStepMeters = minElevationStepMeters,
  }) {
    double? lastAlt;
    var gain = 0.0;
    var loss = 0.0;
    for (final point in route) {
      final alt = point.alt;
      if (alt == null) continue;
      final delta = elevationDelta(previousAlt: lastAlt, currentAlt: alt, minStepMeters: minStepMeters);
      gain += delta.gain;
      loss += delta.loss;
      lastAlt = alt;
    }
    return (gain: gain, loss: loss);
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
