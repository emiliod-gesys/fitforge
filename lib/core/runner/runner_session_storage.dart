import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'runner_models.dart';

abstract final class RunnerSessionStorage {
  static String _key(String workoutId) => 'runner_session_$workoutId';

  static Future<void> save(RunnerTrackingSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(snapshot.workoutId), jsonEncode(snapshot.toJson()));
  }

  static Future<RunnerTrackingSnapshot?> load(String workoutId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(workoutId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return RunnerTrackingSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(String workoutId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(workoutId));
  }
}
