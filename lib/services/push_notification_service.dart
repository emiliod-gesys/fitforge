import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../firebase_options.dart';
import 'supabase_service.dart';

const _androidChannelId = 'fitforge_social';
const _androidChannelName = 'Actividad social';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  GoRouter? _router;
  bool _initialized = false;

  static bool get isAvailable => !kIsWeb && DefaultFirebaseOptions.isConfigured;

  void setRouter(GoRouter router) => _router = router;

  Future<void> initialize() async {
    if (!isAvailable || _initialized) return;

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (_) => _openSocial(),
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _androidChannelId,
              _androidChannelName,
              description: 'Avisos cuando un amigo entrena',
              importance: Importance.high,
            ),
          );
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _openSocial());
    _messaging.onTokenRefresh.listen((_) => registerToken());

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      Future.microtask(_openSocial);
    }

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (!isAvailable) return false;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> registerToken() async {
    if (!isAvailable) return;
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    final platform = Platform.isIOS ? 'ios' : 'android';
    await SupabaseService.client.from('user_push_tokens').upsert(
      {
        'user_id': userId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,token',
    );
  }

  Future<void> unregisterToken() async {
    if (!isAvailable) return;
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final token = await _messaging.getToken();
    if (token != null) {
      await SupabaseService.client
          .from('user_push_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('token', token);
    }
    await _messaging.deleteToken();
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'FitForge',
      notification.body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  void _openSocial() {
    _router?.go('/social');
  }
}
