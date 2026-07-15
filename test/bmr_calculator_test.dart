import 'package:fitforge/core/utils/bmr_calculator.dart';
import 'package:fitforge/models/body_metric.dart';
import 'package:fitforge/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BmrCalculator', () {
    final profile = UserProfile(
      id: 'u1',
      bodyWeight: 80,
      age: 30,
      gender: Gender.male,
      heightCm: 180,
      createdAt: DateTime.utc(2026),
    );

    test('calculates BMR with weight from profile', () {
      final bmr = BmrCalculator.calculate(profile: profile);
      expect(bmr, isNotNull);
      expect(bmr!.round(), 1780);
    });

    test('uses body metric weight when available', () {
      final snapshots = {
        'weight': const BodyMetricSnapshot(type: 'weight', valueKg: 75),
      };
      final bmr = BmrCalculator.calculate(profile: profile, snapshots: snapshots);
      expect(bmr!.round(), 1730);
    });

    test('returns null without gender', () {
      final incomplete = UserProfile(
        id: 'u1',
        bodyWeight: 80,
        age: 30,
        heightCm: 180,
        createdAt: DateTime.utc(2026),
      );
      expect(BmrCalculator.calculate(profile: incomplete), isNull);
    });

    test('returns null without height', () {
      final incomplete = UserProfile(
        id: 'u1',
        bodyWeight: 80,
        age: 30,
        gender: Gender.male,
        createdAt: DateTime.utc(2026),
      );
      expect(BmrCalculator.calculate(profile: incomplete), isNull);
    });

    test('enrich replaces stored BMR with calculated value', () {
      final snapshots = {
        'weight': const BodyMetricSnapshot(type: 'weight', valueKg: 80),
        'bmr': const BodyMetricSnapshot(type: 'bmr', rawValue: 9999),
      };
      final enriched = BodyMetricCalculator.enrich(snapshots, profile);
      expect(enriched['bmr']!.rawValue!.round(), 1780);
    });

    test('enrich computes BMI from weight and height', () {
      final snapshots = {
        'weight': const BodyMetricSnapshot(type: 'weight', valueKg: 80),
      };
      final enriched = BodyMetricCalculator.enrich(snapshots, profile);
      expect(enriched['bmi']!.rawValue, closeTo(24.7, 0.1));
    });

    test('BMI returns null without height', () {
      final incomplete = UserProfile(
        id: 'u1',
        bodyWeight: 80,
        createdAt: DateTime.utc(2026),
      );
      expect(
        BmiCalculator.calculate(
          profile: incomplete,
          snapshots: {'weight': const BodyMetricSnapshot(type: 'weight', valueKg: 80)},
        ),
        isNull,
      );
    });
  });
}
