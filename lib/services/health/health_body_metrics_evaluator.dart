import 'health_body_metric_sample.dart';
import 'health_import_store.dart';

/// Propuesta de importación lista para confirmación en UI.
class HealthImportProposal {
  const HealthImportProposal({
    required this.sample,
    required this.currentValue,
    required this.currentMeasuredAt,
  });

  final HealthBodyMetricSample sample;
  final double? currentValue;
  final DateTime? currentMeasuredAt;
}

abstract final class HealthBodyMetricsEvaluator {
  static const weightMinDeltaKg = 0.2;
  static const bodyFatMinDeltaPct = 0.5;
  static const manualEditGracePeriod = Duration(hours: 24);
  static const historyLookback = Duration(days: 30);

  static double minDeltaFor(String type) {
    return type == 'weight' ? weightMinDeltaKg : bodyFatMinDeltaPct;
  }

  static bool shouldProposeImport({
    required HealthBodyMetricSample sample,
    required DateTime? fitForgeLastMeasuredAt,
    required double? fitForgeCurrentValue,
    required HealthImportLedgerEntry? ledger,
    required DateTime? fitForgeManualEditAt,
  }) {
    if (fitForgeManualEditAt != null &&
        DateTime.now().difference(fitForgeManualEditAt) < manualEditGracePeriod) {
      return false;
    }

    if (fitForgeLastMeasuredAt != null &&
        !sample.measuredAt.isAfter(fitForgeLastMeasuredAt)) {
      return false;
    }

    if (fitForgeCurrentValue != null) {
      final delta = (sample.value - fitForgeCurrentValue).abs();
      if (delta < minDeltaFor(sample.type)) return false;
    }

    if (ledger != null &&
        ledger.measuredAt.difference(sample.measuredAt).inMicroseconds.abs() == 0 &&
        (ledger.value - sample.value).abs() < 0.0001) {
      if (ledger.lastImportedAt != null) return false;
      if (ledger.lastDismissedAt != null) return false;
    }

    return true;
  }

  static HealthBodyMetricSample? pickLatestSample(
    List<HealthBodyMetricSample> samples,
    String type,
  ) {
    HealthBodyMetricSample? latest;
    for (final sample in samples) {
      if (sample.type != type) continue;
      if (latest == null || sample.measuredAt.isAfter(latest.measuredAt)) {
        latest = sample;
      }
    }
    return latest;
  }

  static List<HealthImportProposal> buildProposals({
    required List<HealthBodyMetricSample> samples,
    required bool importWeight,
    required bool importBodyFat,
    required DateTime? weightLastMeasuredAt,
    required double? weightCurrentKg,
    required DateTime? bodyFatLastMeasuredAt,
    required double? bodyFatCurrentPct,
    required HealthImportLedgerEntry? weightLedger,
    required HealthImportLedgerEntry? bodyFatLedger,
    required DateTime? fitForgeManualWeightEditAt,
  }) {
    final proposals = <HealthImportProposal>[];

    if (importWeight) {
      final latest = pickLatestSample(samples, 'weight');
      if (latest != null &&
          shouldProposeImport(
            sample: latest,
            fitForgeLastMeasuredAt: weightLastMeasuredAt,
            fitForgeCurrentValue: weightCurrentKg,
            ledger: weightLedger,
            fitForgeManualEditAt: fitForgeManualWeightEditAt,
          )) {
        proposals.add(
          HealthImportProposal(
            sample: latest,
            currentValue: weightCurrentKg,
            currentMeasuredAt: weightLastMeasuredAt,
          ),
        );
      }
    }

    if (importBodyFat) {
      final latest = pickLatestSample(samples, 'body_fat');
      if (latest != null &&
          shouldProposeImport(
            sample: latest,
            fitForgeLastMeasuredAt: bodyFatLastMeasuredAt,
            fitForgeCurrentValue: bodyFatCurrentPct,
            ledger: bodyFatLedger,
            fitForgeManualEditAt: null,
          )) {
        proposals.add(
          HealthImportProposal(
            sample: latest,
            currentValue: bodyFatCurrentPct,
            currentMeasuredAt: bodyFatLastMeasuredAt,
          ),
        );
      }
    }

    return proposals;
  }
}
