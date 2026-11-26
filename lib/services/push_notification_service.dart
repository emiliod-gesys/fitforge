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
  await _ensureFirebaseApp();
  await showBackgroundRemoteMessage(message);
}

Future<void> _ensureFirebaseApp() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on FirebaseException catch (error) {
    if (error.code != 'duplicate-app') rethrow;
  }
}

class PushNotificationService {
  final _local = LocalNotificationService.instance;
  GoRouter? _router;
  bool _initialized = false;
  bool _listenersReady = false;
  Future<void>? _initializing;
  static bool _prepared = false;

  /// No leer [FirebaseMessaging.instance] antes de [Firebase.initializeApp]:
  /// el getter llama a [Firebase.app] y, si la app aún no existe, aborta el
  /// registro del token. Sin token el push no tiene a quién llegar.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  static bool get isAvailable => !kIsWeb && DefaultFirebaseOptions.isConfigured;

  void setRouter(GoRouter router) => _router = router;

  /// Hay que llamarlo antes de [runApp] para que el aviso llegue con la app cerrada.
  static Future<void> prepare() async {
    if (!isAvailable || _prepared) return;
    await _ensureFirebaseApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _prepared = true;
  }

  Future<void> initialize() async {
    if (!isAvailable || _initialized) return;
    final pending = _initializing;
    if (pending != null) {
      await pending;
      return;
    }

    final run = _initialize();
    _initializing = run;
    try {
      await run;
    } finally {
      if (identical(_initializing, run)) _initializing = null;
    }
  }

  Future<void> _initialize() async {
    if (_initialized) return;

    await prepare();

    await _local.initialize(onNotificationTap: _openSocial);

    if (!_listenersReady) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_local.showRemoteMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((_) => _openSocial());
      _messaging.onTokenRefresh.listen((_) => registerToken());
      _listenersReady = true;
    }

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      Future.microtask(_openSocial);
    }

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (!isAvailable) return false;
    await initialize();

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

    try {
      await initialize();
      if (!_initialized) return;

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
    } catch (error, stack) {
      debugPrint('No se pudo registrar el token de notificaciones: $error\n$stack');
    }
  }

  Future<void> unregisterToken() async {
    if (!isAvailable) return;
    await initialize();
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
