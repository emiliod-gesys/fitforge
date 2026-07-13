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

    test('paceSecPerKm calculates correctly', () {
      final pace = RunnerTracking.paceSecPerKm(distanceMeters: 1000, elapsedSeconds: 300);
      expect(pace, 300);
    });
  });
}
