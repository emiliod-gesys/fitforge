import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_settings.dart';
import 'supabase_service.dart';

/// Preferencias de avisos. En el teléfono mandan al instante; en el servidor
/// deciden el push cuando la app está cerrada. Si no hay fila, todo sigue activo.
class NotificationSettingsStore {
  static const activeRestNotificationIdKey = 'active_rest_notification_id';

  static const _restKey = 'notif_rest_end';
  static const _friendRequestsKey = 'notif_friend_requests';
  static const _commentsKey = 'notif_comments';
  static const _routinesKey = 'notif_routines';
  static const _friendActivityKey = 'notif_friend_activity';
  static const _dirtyKey = 'notif_settings_dirty';

  static Future<bool> restEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_restKey) ?? true;
  }

  static Future<NotificationSettings> load() async {
    final local = await _readLocal();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_dirtyKey) == true) {
      final pushed = await _push(local);
      if (pushed) await prefs.setBool(_dirtyKey, false);
      return local;
    }

    final remote = await _fetch();
    if (remote == null) return local;
    await _writeLocal(remote);
    return remote;
  }

  static Future<void> save(NotificationSettings settings) async {
    await _writeLocal(settings);
    final pushed = await _push(settings);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dirtyKey, !pushed);
  }

  static Future<NotificationSettings> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    bool flag(String key) => prefs.getBool(key) ?? true;
    return NotificationSettings(
      restEnd: flag(_restKey),
      friendRequests: flag(_friendRequestsKey),
      comments: flag(_commentsKey),
      routines: flag(_routinesKey),
      friendActivity: flag(_friendActivityKey),
    );
  }

  static Future<void> _writeLocal(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_restKey, settings.restEnd);
    await prefs.setBool(_friendRequestsKey, settings.friendRequests);
    await prefs.setBool(_commentsKey, settings.comments);
    await prefs.setBool(_routinesKey, settings.routines);
    await prefs.setBool(_friendActivityKey, settings.friendActivity);
  }

  static Future<NotificationSettings?> _fetch() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;
    try {
      final row = await SupabaseService.client
          .from('notification_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return NotificationSettings.fromRow(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _push(NotificationSettings settings) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;
    try {
      await SupabaseService.client
          .from('notification_settings')
          .upsert(settings.toRow(userId), onConflict: 'user_id');
      return true;
    } catch (_) {
      return false;
    }
  }
}
