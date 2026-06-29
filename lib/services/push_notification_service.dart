import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../firebase_options.dart';
import 'local_notification_service.dart';
import 'supabase_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await showBackgroundRemoteMessage(message);
}

class PushNotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _local = LocalNotificationService.instance;
  GoRouter? _router;
  bool _initialized = false;

  static bool get isAvailable => !kIsWeb && DefaultFirebaseOptions.isConfigured;

  void setRouter(GoRouter router) => _router = router;

  Future<void> initialize() async {
    if (!isAvailable || _initialized) return;

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _local.initialize(onNotificationTap: _openSocial);

    FirebaseMessaging.onMessage.listen(_local.showRemoteMessage);
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

    await _local.requestPermission();

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

    final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
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

  void _openSocial() {
    _router?.go('/social');
  }
}
