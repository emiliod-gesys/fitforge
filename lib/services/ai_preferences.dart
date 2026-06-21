import 'package:shared_preferences/shared_preferences.dart';

class AiPreferences {
  static const _proactiveAiKey = 'ai_proactive_enabled';

  static Future<bool> isProactiveAiEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_proactiveAiKey) ?? false;
  }

  static Future<void> setProactiveAiEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proactiveAiKey, enabled);
  }
}
