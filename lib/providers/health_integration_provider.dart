import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/body_metric.dart';
import '../models/profile.dart';
import '../services/health/health_body_metrics_evaluator.dart';
import '../services/health/health_body_metrics_importer.dart';
import '../services/health/health_import_store.dart';
import '../services/health/health_integration_service.dart';
import '../services/health/health_workout_exporter.dart';
import 'app_providers.dart';

final healthIntegrationServiceProvider = Provider((ref) => HealthIntegrationService());

final healthImportStoreProvider = Provider((ref) => HealthImportStore());

final healthBodyMetricsImporterProvider = Provider((ref) {
  return HealthBodyMetricsImporter(
    healthService: ref.watch(healthIntegrationServiceProvider),
    store: ref.watch(healthImportStoreProvider),
    profileService: ref.watch(profileServiceProvider),
  );
});

final healthWorkoutExporterProvider = Provider((ref) {
  return HealthWorkoutExporter(
    healthService: ref.watch(healthIntegrationServiceProvider),
    store: ref.watch(healthImportStoreProvider),
  );
});

class HealthIntegrationState {
  const HealthIntegrationState({
    this.prefs = const HealthImportPreferences(),
    this.loading = false,
    this.permissionsGranted = false,
    this.platformSupported = false,
    this.healthConnectAvailable = true,
    this.pendingProposals = const [],
    this.errorCode,
    this.initialized = false,
  });

  final HealthImportPreferences prefs;
  final bool loading;
  final bool permissionsGranted;
  final bool platformSupported;
  final bool healthConnectAvailable;
  final List<HealthImportProposal> pendingProposals;
  final String? errorCode;
  final bool initialized;

  HealthIntegrationState copyWith({
    HealthImportPreferences? prefs,
    bool? loading,
    bool? permissionsGranted,
    bool? platformSupported,
    bool? healthConnectAvailable,
    List<HealthImportProposal>? pendingProposals,
    String? errorCode,
    bool clearError = false,
    bool? initialized,
  }) {
    return HealthIntegrationState(
      prefs: prefs ?? this.prefs,
      loading: loading ?? this.loading,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      platformSupported: platformSupported ?? this.platformSupported,
      healthConnectAvailable: healthConnectAvailable ?? this.healthConnectAvailable,
      pendingProposals: pendingProposals ?? this.pendingProposals,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      initialized: initialized ?? this.initialized,
    );
  }
}

class HealthIntegrationNotifier extends StateNotifier<HealthIntegrationState> {
  HealthIntegrationNotifier(this._ref) : super(const HealthIntegrationState());

  final Ref _ref;

  HealthIntegrationService get _health => _ref.read(healthIntegrationServiceProvider);
  HealthImportStore get _store => _ref.read(healthImportStoreProvider);
  HealthBodyMetricsImporter get _importer => _ref.read(healthBodyMetricsImporterProvider);

  Future<void> initialize() async {
    if (state.initialized) return;
    final supported = await _health.isPlatformSupported();
    final hcAvailable = supported ? await _health.isHealthConnectAvailable() : false;
    final prefs = await _store.loadPreferences();
    final permissions = prefs.connected && supported
        ? await _health.hasReadPermissions()
        : false;

    state = state.copyWith(
      platformSupported: supported,
      healthConnectAvailable: hcAvailable,
      prefs: prefs,
      permissionsGranted: permissions,
      initialized: true,
    );
  }

  Future<bool> connect() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final prefsBefore = await _store.loadPreferences();
      final granted = await _health.requestConnectPermissions(
        includeWrite: prefsBefore.exportWorkouts,
      );
      final prefs = prefsBefore.copyWith(connected: granted);
      await _store.savePreferences(prefs);
      state = state.copyWith(
        loading: false,
        permissionsGranted: granted,
        prefs: prefs,
        errorCode: granted ? null : 'permission_denied',
      );
      if (granted) {
        await syncNow();
      }
      return granted;
    } catch (e) {
      state = state.copyWith(loading: false, errorCode: 'connect_failed');
      return false;
    }
  }

  Future<void> disconnect() async {
    await _store.clearAll();
    state = state.copyWith(
      prefs: const HealthImportPreferences(),
      permissionsGranted: false,
      pendingProposals: const [],
      clearError: true,
    );
  }

  Future<void> setImportWeight(bool value) async {
    final prefs = state.prefs.copyWith(importWeight: value);
    await _store.savePreferences(prefs);
    state = state.copyWith(prefs: prefs);
  }

  Future<void> setImportBodyFat(bool value) async {
    final prefs = state.prefs.copyWith(importBodyFat: value);
    await _store.savePreferences(prefs);
    state = state.copyWith(prefs: prefs);
  }

  Future<bool> setExportWorkouts(bool value) async {
    if (value && state.prefs.connected) {
      final granted = await _health.requestWritePermissions();
      if (!granted) {
        state = state.copyWith(errorCode: 'permission_denied');
        return false;
      }
    }
    final prefs = state.prefs.copyWith(exportWorkouts: value);
    await _store.savePreferences(prefs);
    state = state.copyWith(prefs: prefs, clearError: true);
    return true;
  }

  Future<void> installHealthConnect() async {
    await _health.installHealthConnect();
    final available = await _health.isHealthConnectAvailable();
    state = state.copyWith(healthConnectAvailable: available);
  }

  Future<void> syncNow({
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? snapshots,
  }) async {
    if (!state.prefs.connected) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final resolvedProfile = profile ?? await _ref.read(profileServiceProvider).getProfile();
      final resolvedSnapshots =
          snapshots ?? await _ref.read(profileServiceProvider).getBodyMetricSnapshots();

      final result = await _importer.syncForReview(
        profile: resolvedProfile,
        snapshots: resolvedSnapshots,
      );

      if (result.error != null) {
        state = state.copyWith(
          loading: false,
          errorCode: result.error,
          pendingProposals: const [],
        );
        return;
      }

      final prefs = (await _store.loadPreferences()).copyWith(
        lastSyncAt: result.syncedAt,
      );
      await _store.savePreferences(prefs);

      state = state.copyWith(
        loading: false,
        pendingProposals: result.proposals,
        prefs: prefs,
      );
    } catch (e) {
      state = state.copyWith(loading: false, errorCode: 'sync_failed');
    }
  }

  Future<void> applyProposal(
    HealthImportProposal proposal, {
    required String unitSystem,
  }) async {
    await _importer.applyProposal(proposal: proposal, unitSystem: unitSystem);
    final remaining = state.pendingProposals
        .where((p) => p.sample.sourceKey != proposal.sample.sourceKey)
        .toList();
    state = state.copyWith(pendingProposals: remaining);
    _ref.invalidate(bodyMetricSnapshotsProvider);
    _ref.invalidate(profileProvider);
  }

  Future<void> dismissProposal(HealthImportProposal proposal) async {
    await _importer.dismissProposal(proposal);
    final remaining = state.pendingProposals
        .where((p) => p.sample.sourceKey != proposal.sample.sourceKey)
        .toList();
    state = state.copyWith(pendingProposals: remaining);
  }

  void clearPendingProposals() {
    state = state.copyWith(pendingProposals: const []);
  }
}

final healthIntegrationProvider =
    StateNotifierProvider<HealthIntegrationNotifier, HealthIntegrationState>((ref) {
  return HealthIntegrationNotifier(ref);
});

/// Duración de ventana histórica expuesta para tests/documentación.
const healthHistoryLookback = HealthBodyMetricsEvaluator.historyLookback;
