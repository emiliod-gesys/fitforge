import 'package:shared_preferences/shared_preferences.dart';

class AiPreferences {
  static const _proactiveAiKey = 'ai_proactive_enabled';

  static Future<bool> isProactiveAiEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final asBool = prefs.getBool(_proactiveAiKey);
    if (asBool != null) return asBool;
    final asDouble = prefs.getDouble(_proactiveAiKey);
    if (asDouble != null) return asDouble != 0;
    final asInt = prefs.getInt(_proactiveAiKey);
    if (asInt != null) return asInt != 0;
    return false;
  }

  static Future<void> setProactiveAiEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proactiveAiKey, enabled);
  }
}
