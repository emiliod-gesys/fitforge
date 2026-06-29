import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const socialChannelId = 'fitforge_social';
const socialChannelName = 'Actividad social';
const restChannelId = 'fitforge_rest';
const restChannelName = 'Descanso entre series';

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
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          socialChannelId,
          socialChannelName,
          description: 'Avisos cuando un amigo entrena',
          importance: Importance.high,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          restChannelId,
          restChannelName,
          description: 'Aviso al terminar el descanso entre series',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (!isSupported) return false;

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
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

  Future<void> showSocial({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          socialChannelId,
          socialChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Programa aviso de fin de descanso aunque la app esté en segundo plano.
  Future<void> scheduleRestEnd({
    required int id,
    required DateTime endsAt,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;

    final when = tz.TZDateTime.from(endsAt, tz.local);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      _restNotificationId(id),
      title,
      body,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          restChannelId,
          restChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelRestEnd(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(_restNotificationId(id));
  }

  int _restNotificationId(int sessionId) => 20000 + sessionId;

  Future<void> showRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await showSocial(
      id: notification.hashCode,
      title: notification.title ?? 'FitForge',
      body: notification.body ?? '',
    );
  }
}

@pragma('vm:entry-point')
Future<void> showBackgroundRemoteMessage(RemoteMessage message) async {
  final service = LocalNotificationService.instance;
  await service.initialize();
  await service.showRemoteMessage(message);
}
