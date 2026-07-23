import 'package:fitforge/services/daily_tip_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyTipPreferences', () {
    test('shouldShowToday is true until marked for that day', () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime(2026, 7, 22, 9, 30);

      expect(await DailyTipPreferences.shouldShowToday(now: now), isTrue);

      await DailyTipPreferences.markShownToday(now: now);

      expect(await DailyTipPreferences.shouldShowToday(now: now), isFalse);
      expect(
        await DailyTipPreferences.shouldShowToday(
          now: now.add(const Duration(hours: 10)),
        ),
        isFalse,
      );
      expect(
        await DailyTipPreferences.shouldShowToday(
          now: now.add(const Duration(days: 1)),
        ),
        isTrue,
      );
    });
  });
}
