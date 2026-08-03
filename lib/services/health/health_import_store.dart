import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias y ledger local de importación desde salud.
class HealthImportPreferences {
  const HealthImportPreferences({
    this.connected = false,
    this.importWeight = true,
    this.importBodyFat = true,
    this.exportWorkouts = true,
    this.lastSyncAt,
  });

  final bool connected;
  final bool importWeight;
  final bool importBodyFat;
  final bool exportWorkouts;
  final DateTime? lastSyncAt;

  HealthImportPreferences copyWith({
    bool? connected,
    bool? importWeight,
    bool? importBodyFat,
    bool? exportWorkouts,
    DateTime? lastSyncAt,
    bool clearLastSyncAt = false,
  }) {
    return HealthImportPreferences(
      connected: connected ?? this.connected,
      importWeight: importWeight ?? this.importWeight,
      importBodyFat: importBodyFat ?? this.importBodyFat,
      exportWorkouts: exportWorkouts ?? this.exportWorkouts,
      lastSyncAt: clearLastSyncAt ? null : (lastSyncAt ?? this.lastSyncAt),
    );
  }
}

class HealthImportLedgerEntry {
  const HealthImportLedgerEntry({
    required this.measuredAt,
    required this.value,
    this.lastImportedAt,
    this.lastDismissedAt,
  });

  final DateTime measuredAt;
  final double value;
  final DateTime? lastImportedAt;
  final DateTime? lastDismissedAt;

  Map<String, dynamic> toJson() => {
        'measured_at': measuredAt.toIso8601String(),
        'value': value,
        if (lastImportedAt != null) 'last_imported_at': lastImportedAt!.toIso8601String(),
        if (lastDismissedAt != null) 'last_dismissed_at': lastDismissedAt!.toIso8601String(),
      };

  factory HealthImportLedgerEntry.fromJson(Map<String, dynamic> json) {
    return HealthImportLedgerEntry(
      measuredAt: DateTime.parse(json['measured_at'] as String),
      value: (json['value'] as num).toDouble(),
      lastImportedAt: json['last_imported_at'] != null
          ? DateTime.parse(json['last_imported_at'] as String)
          : null,
      lastDismissedAt: json['last_dismissed_at'] != null
          ? DateTime.parse(json['last_dismissed_at'] as String)
          : null,
    );
  }
}

class HealthImportStore {
  HealthImportStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const _connected = 'health_connected';
  static const _importWeight = 'health_import_weight';
  static const _importBodyFat = 'health_import_body_fat';
  static const _exportWorkouts = 'health_export_workouts';
  static const _lastSyncAt = 'health_last_sync_at';
  static const _manualWeightEditAt = 'health_manual_weight_edit_at';
  static const _ledgerPrefix = 'health_ledger_';
  static const _exportedWorkoutPrefix = 'health_exported_workout_';

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<HealthImportPreferences> loadPreferences() async {
    final prefs = await _ensurePrefs();
    final syncRaw = prefs.getString(_lastSyncAt);
    return HealthImportPreferences(
      connected: prefs.getBool(_connected) ?? false,
      importWeight: prefs.getBool(_importWeight) ?? true,
      importBodyFat: prefs.getBool(_importBodyFat) ?? true,
      exportWorkouts: prefs.getBool(_exportWorkouts) ?? true,
      lastSyncAt: syncRaw != null ? DateTime.tryParse(syncRaw) : null,
    );
  }

  Future<void> savePreferences(HealthImportPreferences value) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_connected, value.connected);
    await prefs.setBool(_importWeight, value.importWeight);
    await prefs.setBool(_importBodyFat, value.importBodyFat);
    await prefs.setBool(_exportWorkouts, value.exportWorkouts);
    if (value.lastSyncAt != null) {
      await prefs.setString(_lastSyncAt, value.lastSyncAt!.toIso8601String());
    } else {
      await prefs.remove(_lastSyncAt);
    }
  }

  Future<bool> wasWorkoutExported(String workoutId) async {
    if (workoutId.isEmpty) return false;
    final prefs = await _ensurePrefs();
    return prefs.getBool('$_exportedWorkoutPrefix$workoutId') ?? false;
  }

  Future<void> markWorkoutExported(String workoutId) async {
    if (workoutId.isEmpty) return;
    final prefs = await _ensurePrefs();
    await prefs.setBool('$_exportedWorkoutPrefix$workoutId', true);
  }

  Future<HealthImportLedgerEntry?> loadLedger(String type) async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString('$_ledgerPrefix$type');
    if (raw == null) return null;
    try {
      final parts = raw.split('|');
      if (parts.length < 3) return null;
      return HealthImportLedgerEntry(
        measuredAt: DateTime.parse(parts[0]),
        value: double.parse(parts[1]),
        lastImportedAt: parts.length > 3 && parts[3].isNotEmpty
            ? DateTime.tryParse(parts[3])
            : null,
        lastDismissedAt: parts.length > 4 && parts[4].isNotEmpty
            ? DateTime.tryParse(parts[4])
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLedger(String type, HealthImportLedgerEntry entry) async {
    final prefs = await _ensurePrefs();
    final encoded = [
      entry.measuredAt.toIso8601String(),
      entry.value.toString(),
      type,
      entry.lastImportedAt?.toIso8601String() ?? '',
      entry.lastDismissedAt?.toIso8601String() ?? '',
    ].join('|');
    await prefs.setString('$_ledgerPrefix$type', encoded);
  }

  Future<void> clearAll() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_connected);
    await prefs.remove(_importWeight);
    await prefs.remove(_importBodyFat);
    await prefs.remove(_exportWorkouts);
    await prefs.remove(_lastSyncAt);
    await prefs.remove(_manualWeightEditAt);
    for (final type in ['weight', 'body_fat']) {
      await prefs.remove('$_ledgerPrefix$type');
    }
    // Conservamos marcas de export para no reenviar entrenos antiguos al reconectar.
  }

  Future<void> recordManualWeightEdit([DateTime? when]) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(
      _manualWeightEditAt,
      (when ?? DateTime.now()).toIso8601String(),
    );
  }

  Future<DateTime?> getLastManualWeightEditAt() async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(_manualWeightEditAt);
    return raw != null ? DateTime.tryParse(raw) : null;
  }
}
