import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda si ya se mostró el tip del día.
abstract final class DailyTipPreferences {
  static const _lastShownKey = 'daily_tip_last_shown_date';

  static String _dateKey(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Future<bool> shouldShowToday({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_lastShownKey);
    return last != _dateKey(now ?? DateTime.now());
  }

  static Future<void> markShownToday({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastShownKey, _dateKey(now ?? DateTime.now()));
  }
}
