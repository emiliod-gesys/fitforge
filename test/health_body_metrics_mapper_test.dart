import 'package:fitforge/services/health/health_body_metrics_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

void main() {
  group('HealthBodyMetricsMapper.weightToKg', () {
    test('keeps kilograms', () {
      expect(HealthBodyMetricsMapper.weightToKg(72.5, HealthDataUnit.KILOGRAM), 72.5);
    });

    test('converts pounds to kilograms', () {
      final kg = HealthBodyMetricsMapper.weightToKg(154.3, HealthDataUnit.POUND)!;
      expect(kg, closeTo(70.0, 0.05));
    });

    test('converts grams to kilograms', () {
      expect(HealthBodyMetricsMapper.weightToKg(70000, HealthDataUnit.GRAM), 70);
    });

    test('rejects implausible weights', () {
      expect(HealthBodyMetricsMapper.weightToKg(5, HealthDataUnit.KILOGRAM), isNull);
      expect(HealthBodyMetricsMapper.weightToKg(500, HealthDataUnit.KILOGRAM), isNull);
    });
  });

  group('HealthBodyMetricsMapper.bodyFatToPercent', () {
    test('converts Apple Health fraction 0-1 to percent', () {
      expect(HealthBodyMetricsMapper.bodyFatToPercent(0.185), closeTo(18.5, 0.001));
    });

    test('keeps Health Connect percent 0-100', () {
      expect(HealthBodyMetricsMapper.bodyFatToPercent(18.5), 18.5);
    });

    test('rejects implausible body fat', () {
      expect(HealthBodyMetricsMapper.bodyFatToPercent(0), isNull);
      expect(HealthBodyMetricsMapper.bodyFatToPercent(0.005), isNull); // 0.5%
      expect(HealthBodyMetricsMapper.bodyFatToPercent(85), isNull);
    });
  });
}
