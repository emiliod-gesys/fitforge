import 'package:fitforge/services/health/health_import_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthImportStore', () {
    late HealthImportStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = HealthImportStore(prefs: await SharedPreferences.getInstance());
    });

    test('persists preferences and ledger', () async {
      await store.savePreferences(
        HealthImportPreferences(
          connected: true,
          importWeight: true,
          exportWorkouts: false,
        ),
      );
      await store.saveLedger(
        'weight',
        HealthImportLedgerEntry(
          measuredAt: DateTime.utc(2026, 7, 30),
          value: 72.5,
          lastImportedAt: DateTime.utc(2026, 7, 30, 1),
        ),
      );

      final prefs = await store.loadPreferences();
      final ledger = await store.loadLedger('weight');

      expect(prefs.connected, isTrue);
      expect(prefs.exportWorkouts, isFalse);
      expect(ledger?.value, 72.5);
      expect(ledger?.lastImportedAt, isNotNull);
    });

    test('tracks exported workout ids', () async {
      expect(await store.wasWorkoutExported('w1'), isFalse);
      await store.markWorkoutExported('w1');
      expect(await store.wasWorkoutExported('w1'), isTrue);
    });

    test('records manual weight edit timestamp', () async {
      final when = DateTime.utc(2026, 7, 29, 8);
      await store.recordManualWeightEdit(when);
      expect(await store.getLastManualWeightEditAt(), when);
    });
  });
}
