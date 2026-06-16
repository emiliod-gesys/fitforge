import 'package:shared_preferences/shared_preferences.dart';

class RestPreferences {
  static const _key = 'default_rest_seconds';

  static Future<int> getDefaultRestSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 90;
  }

  static Future<void> setDefaultRestSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, seconds);
  }
}
