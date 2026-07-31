import '../../models/body_metric.dart';
import '../../models/profile.dart';
import '../profile_service.dart';
import 'health_body_metrics_evaluator.dart';
import 'health_import_store.dart';
import 'health_integration_service.dart';

class HealthSyncResult {
  const HealthSyncResult({
    this.proposals = const [],
    this.error,
    this.syncedAt,
  });

  final List<HealthImportProposal> proposals;
  final String? error;
  final DateTime? syncedAt;
}

/// Orquesta lectura desde salud, evaluación anti-duplicado y persistencia tras confirmación.
class HealthBodyMetricsImporter {
  HealthBodyMetricsImporter({
    required HealthIntegrationService healthService,
    required HealthImportStore store,
    required ProfileService profileService,
  })  : _health = healthService,
        _store = store,
        _profiles = profileService;

  final HealthIntegrationService _health;
  final HealthImportStore _store;
  final ProfileService _profiles;

  Future<HealthSyncResult> syncForReview({
    required UserProfile? profile,
    required Map<String, BodyMetricSnapshot> snapshots,
  }) async {
    try {
      if (!await _health.isPlatformSupported()) {
        return const HealthSyncResult(error: 'unsupported_platform');
      }

      if (!await _health.isHealthConnectAvailable()) {
        return const HealthSyncResult(error: 'health_connect_unavailable');
      }

      final prefs = await _store.loadPreferences();
      if (!prefs.connected) {
        return const HealthSyncResult(error: 'not_connected');
      }

      final hasPermission = await _health.hasReadPermissions();
      if (!hasPermission) {
        return const HealthSyncResult(error: 'permission_denied');
      }

      await _health.requestHistoryAuthorizationIfNeeded();

      final now = DateTime.now();
      final start = now.subtract(HealthBodyMetricsEvaluator.historyLookback);
      final samples = await _health.fetchBodyMetricSamples(start: start, end: now);

      final weightSnapshot = snapshots['weight'];
      final bodyFatSnapshot = snapshots['body_fat'];

      final proposals = HealthBodyMetricsEvaluator.buildProposals(
        samples: samples,
        importWeight: prefs.importWeight,
        importBodyFat: prefs.importBodyFat,
        weightLastMeasuredAt: weightSnapshot?.measuredAt ??
            await _profiles.getLastWeightMeasuredAt(),
        weightCurrentKg: weightSnapshot?.valueKg ?? profile?.bodyWeight,
        bodyFatLastMeasuredAt: bodyFatSnapshot?.measuredAt ??
            await _profiles.getLastBodyFatMeasuredAt(),
        bodyFatCurrentPct: bodyFatSnapshot?.rawValue,
        weightLedger: await _store.loadLedger('weight'),
        bodyFatLedger: await _store.loadLedger('body_fat'),
        fitForgeManualWeightEditAt: await _store.getLastManualWeightEditAt(),
      );

      await _store.savePreferences(
        prefs.copyWith(lastSyncAt: now),
      );

      return HealthSyncResult(proposals: proposals, syncedAt: now);
    } catch (e) {
      return HealthSyncResult(error: e.toString());
    }
  }

  Future<void> applyProposal({
    required HealthImportProposal proposal,
    required String unitSystem,
  }) async {
    final sample = proposal.sample;
    // Las muestras de salud ya vienen normalizadas: peso en kg, grasa en %.
    // Hay que persistir el peso con unitSystem 'kg'; si se pasa el del perfil ('lb'),
    // saveBodyMetric vuelve a convertir y corrompe el valor (~kg/2.2).
    final persistUnit = sample.type == 'weight' ? 'kg' : unitSystem;

    await _profiles.saveBodyMetric(
      type: sample.type,
      displayValue: sample.value,
      unitSystem: persistUnit,
      measuredAt: sample.measuredAt,
      source: 'health',
    );

    await _store.saveLedger(
      sample.type,
      HealthImportLedgerEntry(
        measuredAt: sample.measuredAt,
        value: sample.value,
        lastImportedAt: DateTime.now(),
      ),
    );
  }

  Future<void> dismissProposal(HealthImportProposal proposal) async {
    await _store.saveLedger(
      proposal.sample.type,
      HealthImportLedgerEntry(
        measuredAt: proposal.sample.measuredAt,
        value: proposal.sample.value,
        lastDismissedAt: DateTime.now(),
      ),
    );
  }
}
