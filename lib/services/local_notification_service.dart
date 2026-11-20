import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/rest_timer_alert_mode.dart';
import 'notification_settings_store.dart';
import 'rest_preferences.dart';

const socialChannelId = 'fitforge_social';
const socialChannelName = 'Actividad social';
const restChannelId = 'fitforge_rest_alarm';
const restChannelName = 'Descanso entre series';
const restSilentChannelId = 'fitforge_rest_status';
const restSilentChannelName = 'Aviso de descanso';
const _restBellSound = RawResourceAndroidNotificationSound('rest_timer_bell');

const _androidSocialDetails = AndroidNotificationDetails(
  socialChannelId,
  socialChannelName,
  channelDescription: 'Avisos cuando un amigo entrena',
  importance: Importance.max,
  priority: Priority.high,
  visibility: NotificationVisibility.public,
  category: AndroidNotificationCategory.social,
  icon: '@mipmap/ic_launcher',
  playSound: true,
  enableVibration: true,
);

/// Notificaciones del sistema (bandeja) compartidas por push social y timer de descanso.
class LocalNotificationService {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static bool get isSupported => !kIsWeb;

  Future<void> initialize({void Function()? onNotificationTap}) async {
    if (!isSupported || _initialized) return;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (_) => onNotificationTap?.call(),
    );

    if (Platform.isAndroid) {
      final android = _androidPlugin;
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          socialChannelId,
          socialChannelName,
          description: 'Avisos cuando un amigo entrena',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          restChannelId,
          restChannelName,
          description: 'Aviso al terminar el descanso entre series',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          sound: _restBellSound,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          restSilentChannelId,
          restSilentChannelName,
          description: 'Aviso visible al terminar el descanso con la app abierta',
          importance: Importance.high,
          playSound: false,
          enableVibration: false,
        ),
      );
    }

    _initialized = true;
  }

  Future<void> ensureReadyForRestTimer() async {
    if (!_initialized) await initialize();
    await requestPermission();
    await requestExactAlarmsIfNeeded();
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> requestExactAlarmsIfNeeded() async {
    if (!Platform.isAndroid) return;
    final android = _androidPlugin;
    if (android == null) return;

    final canExact = await android.canScheduleExactNotifications();
    if (canExact != true) {
      await android.requestExactAlarmsPermission();
    }
  }

  Future<bool> requestPermission() async {
    if (!isSupported) return false;

    if (Platform.isAndroid) {
      final android = _androidPlugin;
      final granted = await android?.requestNotificationsPermission();
      await requestExactAlarmsIfNeeded();
      return granted ?? false;
    }

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    return false;
  }

  Future<NotificationDetails> _restDetails(RestTimerAlertMode mode) async {
    final playSound =
        mode == RestTimerAlertMode.sound || mode == RestTimerAlertMode.both;
    final enableVibration =
        mode == RestTimerAlertMode.vibration || mode == RestTimerAlertMode.both;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        restChannelId,
        restChannelName,
        channelDescription: 'Aviso al terminar el descanso entre series',
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        icon: '@mipmap/ic_launcher',
        playSound: playSound,
        enableVibration: enableVibration,
        sound: playSound ? _restBellSound : null,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: playSound,
      ),
    );
  }

  Future<void> showSocial({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    if (body.isEmpty && title == 'FORGEN') return;

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: _androidSocialDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Muestra de inmediato el aviso de fin de descanso.
  ///
  /// [audible] en falso deja el aviso en la bandeja sin repetir el sonido
  /// que ya reproduce la app en primer plano.
  Future<void> showRestEnd({
    required int id,
    required String title,
    required String body,
    RestTimerAlertMode? alertMode,
    bool audible = true,
  }) async {
    if (!await NotificationSettingsStore.restEnabled()) {
      await cancelRestEnd(id);
      return;
    }
    await ensureReadyForRestTimer();

    final mode = audible
        ? (alertMode ?? await RestPreferences.getRestTimerAlertMode())
        : null;
    await _plugin.show(
      _restNotificationId(id),
      title,
      body,
      mode == null
          ? await _silentRestDetails()
          : await _restDetails(mode),
    );
    await _rememberRestSession(id);
  }

  /// Programa aviso de fin de descanso aunque la app esté en segundo plano.
  Future<void> scheduleRestEnd({
    required int id,
    required DateTime endsAt,
    required String title,
    required String body,
    RestTimerAlertMode? alertMode,
  }) async {
    if (!await NotificationSettingsStore.restEnabled()) {
      await cancelRestEnd(id);
      return;
    }
    await ensureReadyForRestTimer();

    final when = tz.TZDateTime.from(endsAt.toUtc(), tz.UTC);
    if (!when.isAfter(tz.TZDateTime.now(tz.UTC))) return;

    final mode = alertMode ?? await RestPreferences.getRestTimerAlertMode();
    final details = await _restDetails(mode);
    final notificationId = _restNotificationId(id);

    var scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    if (Platform.isAndroid) {
      final canExact = await _androidPlugin?.canScheduleExactNotifications();
      if (canExact == true) {
        scheduleMode = AndroidScheduleMode.alarmClock;
      }
    }

    try {
      await _plugin.zonedSchedule(
        notificationId,
        title,
        body,
        when,
        details,
        androidScheduleMode: scheduleMode,
      );
    } catch (_) {
      if (scheduleMode == AndroidScheduleMode.inexactAllowWhileIdle) rethrow;
      await _plugin.zonedSchedule(
        notificationId,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    await _rememberRestSession(id);
  }

  Future<void> cancelRestEnd(int id) async {
    if (!isSupported) return;
    if (!_initialized) await initialize();
    if (!_initialized) return;
    await _plugin.cancel(_restNotificationId(id));
    await _forgetRestSession(id);
  }

  Future<void> cancelRememberedRest() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(NotificationSettingsStore.activeRestNotificationIdKey);
    if (id == null) return;
    await cancelRestEnd(id);
  }

  Future<void> _rememberRestSession(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(NotificationSettingsStore.activeRestNotificationIdKey, id);
  }

  Future<void> _forgetRestSession(int id) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(NotificationSettingsStore.activeRestNotificationIdKey) == id) {
      await prefs.remove(NotificationSettingsStore.activeRestNotificationIdKey);
    }
  }

  Future<NotificationDetails> _silentRestDetails() async {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        restSilentChannelId,
        restSilentChannelName,
        channelDescription: 'Aviso visible al terminar el descanso con la app abierta',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        icon: '@mipmap/ic_launcher',
        playSound: false,
        enableVibration: false,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      ),
    );
  }

  int _restNotificationId(int sessionId) => 20000 + sessionId;

  Future<void> showRemoteMessage(RemoteMessage message) async {
    final payload = _parseRemoteMessage(message);
    if (payload.body.isEmpty) return;

    await showSocial(
      id: message.messageId?.hashCode ?? payload.body.hashCode,
      title: payload.title,
      body: payload.body,
    );
  }

  static ({String title, String body}) _parseRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    return (
      title: notification?.title ?? data['title'] as String? ?? 'FORGEN',
      body: notification?.body ??
          data['message'] as String? ??
          data['body'] as String? ??
          '',
    );
  }
}

@pragma('vm:entry-point')
Future<void> showBackgroundRemoteMessage(RemoteMessage message) async {
  final service = LocalNotificationService.instance;
  await service.initialize();
  await service.showRemoteMessage(message);
}
