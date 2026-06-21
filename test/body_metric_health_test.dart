import 'package:fitforge/core/utils/body_metric_health.dart';
import 'package:fitforge/models/body_metric.dart';
import 'package:fitforge/models/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BodyMetricHealthEvaluator', () {
    test('BMI ideal range is dark green', () {
      expect(
        BodyMetricHealthEvaluator.evaluate(
          key: 'bmi',
          snapshot: const BodyMetricSnapshot(type: 'bmi', rawValue: 23),
        ),
        BodyMetricHealthLevel.ideal,
      );
    });

    test('BMI obese is red', () {
      expect(
        BodyMetricHealthEvaluator.evaluate(
          key: 'bmi',
          snapshot: const BodyMetricSnapshot(type: 'bmi', rawValue: 32),
        ),
        BodyMetricHealthLevel.veryBad,
      );
    });

    test('male body fat athletic is ideal', () {
      expect(
        BodyMetricHealthEvaluator.evaluate(
          key: 'body_fat',
          snapshot: const BodyMetricSnapshot(type: 'body_fat', rawValue: 12),
          profile: UserProfile(id: 'u1', gender: Gender.male, createdAt: DateTime.utc(2026)),
        ),
        BodyMetricHealthLevel.ideal,
      );
    });

    test('male body fat high is yellow', () {
      expect(
        BodyMetricHealthEvaluator.evaluate(
          key: 'body_fat',
          snapshot: const BodyMetricSnapshot(type: 'body_fat', rawValue: 22),
          profile: UserProfile(id: 'u1', gender: Gender.male, createdAt: DateTime.utc(2026)),
        ),
        BodyMetricHealthLevel.high,
      );
    });

    test('metabolic age below chronological is ideal', () {
      expect(
        BodyMetricHealthEvaluator.evaluate(
          key: 'metabolic_age',
          snapshot: const BodyMetricSnapshot(type: 'metabolic_age', rawValue: 29),
          profile: UserProfile(id: 'u1', age: 35, createdAt: DateTime.utc(2026)),
        ),
        BodyMetricHealthLevel.ideal,
      );
    });

    test('protein in ideal range is dark green', () {
      expect(
        BodyMetricHealthEvaluator.evaluate(
          key: 'protein',
          snapshot: const BodyMetricSnapshot(type: 'protein', rawValue: 18.3),
        ),
        BodyMetricHealthLevel.ideal,
      );
    });

    test('colors map to expected palette', () {
      expect(
        BodyMetricHealthColors.forLevel(BodyMetricHealthLevel.veryLow),
        const Color(0xFF1E88E5),
      );
      expect(
        BodyMetricHealthColors.forLevel(BodyMetricHealthLevel.high),
        const Color(0xFFFFB300),
      );
    });
  });
}
