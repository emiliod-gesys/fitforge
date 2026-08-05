import 'package:fitforge/services/health/health_body_metric_sample.dart';
import 'package:fitforge/services/health/health_body_metrics_evaluator.dart';
import 'package:fitforge/services/health/health_import_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthBodyMetricsEvaluator', () {
    final now = DateTime(2026, 7, 30, 12);

    test('proposes newer weight when delta exceeds threshold', () {
      final sample = HealthBodyMetricSample(
        type: 'weight',
        value: 72.5,
        measuredAt: now,
        sourceKey: 'w1',
      );

      expect(
        HealthBodyMetricsEvaluator.shouldProposeImport(
          sample: sample,
          fitForgeLastMeasuredAt: now.subtract(const Duration(days: 2)),
          fitForgeCurrentValue: 70.0,
          ledger: null,
          fitForgeManualEditAt: null,
        ),
        isTrue,
      );
    });

    test('skips weight when delta below threshold', () {
      final sample = HealthBodyMetricSample(
        type: 'weight',
        value: 70.1,
        measuredAt: now,
        sourceKey: 'w2',
      );

      expect(
        HealthBodyMetricsEvaluator.shouldProposeImport(
          sample: sample,
          fitForgeLastMeasuredAt: now.subtract(const Duration(days: 1)),
          fitForgeCurrentValue: 70.0,
          ledger: null,
          fitForgeManualEditAt: null,
        ),
        isFalse,
      );
    });

    test('skips when manual weight edit within grace period', () {
      final sample = HealthBodyMetricSample(
        type: 'weight',
        value: 75,
        measuredAt: now,
        sourceKey: 'w3',
      );

      expect(
        HealthBodyMetricsEvaluator.shouldProposeImport(
          sample: sample,
          fitForgeLastMeasuredAt: now.subtract(const Duration(days: 3)),
          fitForgeCurrentValue: 70,
          ledger: null,
          fitForgeManualEditAt: now.subtract(const Duration(hours: 2)),
          now: now,
        ),
        isFalse,
      );
    });

    test('skips already imported ledger entry', () {
      final sample = HealthBodyMetricSample(
        type: 'weight',
        value: 72,
        measuredAt: now,
        sourceKey: 'w4',
      );

      expect(
        HealthBodyMetricsEvaluator.shouldProposeImport(
          sample: sample,
          fitForgeLastMeasuredAt: now.subtract(const Duration(days: 1)),
          fitForgeCurrentValue: 70,
          ledger: HealthImportLedgerEntry(
            measuredAt: now,
            value: 72,
            lastImportedAt: now,
          ),
          fitForgeManualEditAt: null,
        ),
        isFalse,
      );
    });
  });
}
