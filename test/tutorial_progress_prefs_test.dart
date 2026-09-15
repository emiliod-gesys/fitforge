import 'package:fitforge/core/tutorials/tutorial_catalog.dart';
import 'package:fitforge/providers/tutorial_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tutorial prefs are scoped per user', () async {
    SharedPreferences.setMockInitialValues({
      tutorialDonePrefKey('user-a', 'train'): true,
      tutorialDonePrefKey('user-b', 'food'): true,
      tutorialLegacyDonePrefKey('progress'): true,
    });
    final prefs = await SharedPreferences.getInstance();

    expect(tutorialCompletedIdsForUser(prefs, 'user-a'), {'train'});
    expect(tutorialCompletedIdsForUser(prefs, 'user-b'), {'food'});
    expect(tutorialCompletedIdsForUser(prefs, 'user-c'), isEmpty);
  });

  test('legacy device-wide tutorial keys do not apply to a new user', () async {
    final legacy = {
      for (final tour in TutorialCatalog.all)
        tutorialLegacyDonePrefKey(tour.id): true,
      tutorialLegacySnoozeKey: DateTime(2026, 9, 15).toIso8601String(),
    };
    SharedPreferences.setMockInitialValues(legacy);
    final prefs = await SharedPreferences.getInstance();

    expect(tutorialCompletedIdsForUser(prefs, 'fresh-user'), isEmpty);

    await tutorialPurgeLegacyUnscopedKeys(prefs);

    for (final tour in TutorialCatalog.all) {
      expect(prefs.getBool(tutorialLegacyDonePrefKey(tour.id)), isNull);
    }
    expect(prefs.getString(tutorialLegacySnoozeKey), isNull);
  });

  test('purging legacy keys keeps per-user progress', () async {
    SharedPreferences.setMockInitialValues({
      tutorialLegacyDonePrefKey('train'): true,
      tutorialDonePrefKey('user-a', 'food'): true,
    });
    final prefs = await SharedPreferences.getInstance();
    await tutorialPurgeLegacyUnscopedKeys(prefs);

    expect(prefs.getBool(tutorialLegacyDonePrefKey('train')), isNull);
    expect(tutorialCompletedIdsForUser(prefs, 'user-a'), {'food'});
  });
}
