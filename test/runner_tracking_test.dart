import 'package:fitforge/core/runner/runner_models.dart';
import 'package:fitforge/core/runner/runner_tracking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunnerTracking', () {
    test('haversineMeters computes distance', () {
      final d = RunnerTracking.haversineMeters(19.4326, -99.1332, 19.4336, -99.1332);
      expect(d, greaterThan(100));
      expect(d, lessThan(200));
    });

    test('detectNewSplits adds km markers', () {
      final splits = RunnerTracking.detectNewSplits(
        totalDistanceMeters: 2500,
        elapsedSeconds: 900,
        existing: const [],
      );
      expect(splits.length, 2);
      expect(splits.first.km, 1);
      expect(splits.last.km, 2);
    });

    test('isValidGpsPoint rejects poor accuracy', () {
      expect(
        RunnerTracking.isValidGpsPoint(
          accuracyMeters: 40,
          deltaMeters: 5,
          deltaSeconds: 1,
        ),
        isFalse,
      );
    });

    test('simplifyRoute reduces noisy points', () {
      final route = [
        const RunnerRoutePoint(lat: 0, lng: 0, timestampMs: 1),
        const RunnerRoutePoint(lat: 0.00001, lng: 0, timestampMs: 2),
        const RunnerRoutePoint(lat: 0.001, lng: 0, timestampMs: 3),
      ];
      final simplified = RunnerTracking.simplifyRoute(route, minGapMeters: 50);
      expect(simplified.length, lessThan(route.length));
    });

    test('elevationDelta ignores noise under threshold', () {
      final delta = RunnerTracking.elevationDelta(previousAlt: 100, currentAlt: 102);
      expect(delta.gain, 0);
      expect(delta.loss, 0);
    });

    test('elevationDelta accumulates gain and loss', () {
      final up = RunnerTracking.elevationDelta(previousAlt: 100, currentAlt: 110);
      expect(up.gain, 10);
      expect(up.loss, 0);

      final down = RunnerTracking.elevationDelta(previousAlt: 110, currentAlt: 100);
      expect(down.gain, 0);
      expect(down.loss, 10);
    });

    test('elevationFromRoute sums route altitude changes', () {
      final route = [
        const RunnerRoutePoint(lat: 0, lng: 0, timestampMs: 1, alt: 100),
        const RunnerRoutePoint(lat: 0, lng: 0.001, timestampMs: 2, alt: 110),
        const RunnerRoutePoint(lat: 0, lng: 0.002, timestampMs: 3, alt: 105),
      ];
      final totals = RunnerTracking.elevationFromRoute(route);
      expect(totals.gain, 10);
      expect(totals.loss, 5);
    });

    test('paceSecPerKm calculates correctly', () {
      final pace = RunnerTracking.paceSecPerKm(distanceMeters: 1000, elapsedSeconds: 300);
      expect(pace, 300);
    });
  });
}
