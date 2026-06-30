import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../services/local_notification_service.dart';
import '../services/push_notification_service.dart';

/// Inicializa FCM al iniciar sesión y registra el token en Supabase.
class PushNotificationBootstrap extends ConsumerStatefulWidget {
  final GoRouter router;
  final Widget child;

  const PushNotificationBootstrap({
    super.key,
    required this.router,
    required this.child,
  });

  @override
  ConsumerState<PushNotificationBootstrap> createState() => _PushNotificationBootstrapState();
}

class _PushNotificationBootstrapState extends ConsumerState<PushNotificationBootstrap>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPush());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshTokenIfLoggedIn();
    }
  }

  Future<void> _refreshTokenIfLoggedIn() async {
    if (!PushNotificationService.isAvailable) return;
    final session = ref.read(authStateProvider).valueOrNull?.session;
    if (session == null) return;
    await ref.read(pushNotificationServiceProvider).registerToken();
  }

  Future<void> _syncPush() async {
    if (LocalNotificationService.isSupported) {
      final local = LocalNotificationService.instance;
      await local.initialize(onNotificationTap: () {
        if (mounted) widget.router.go('/social');
      });
      if (Platform.isAndroid || Platform.isIOS) {
        await local.requestPermission();
      }
    }

    if (!PushNotificationService.isAvailable) return;

    final push = ref.read(pushNotificationServiceProvider);
    push.setRouter(widget.router);
    await push.initialize();

    final session = ref.read(authStateProvider).valueOrNull?.session;
    if (session != null) {
      await push.requestPermission();
      await push.registerToken();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (prev, next) async {
      if (!PushNotificationService.isAvailable) return;

      final push = ref.read(pushNotificationServiceProvider);
      final wasLoggedIn = prev?.valueOrNull?.session != null;
      final isLoggedIn = next.valueOrNull?.session != null;

      if (!wasLoggedIn && isLoggedIn) {
        await push.requestPermission();
        await push.registerToken();
      } else if (wasLoggedIn && !isLoggedIn) {
        await push.unregisterToken();
      }
    });

    return widget.child;
  }
}
