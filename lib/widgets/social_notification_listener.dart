import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_scaffold.dart';
import '../l10n/l10n_extensions.dart';
import '../models/social.dart';
import '../providers/app_providers.dart';

/// Escucha notificaciones sociales en tiempo real y muestra un aviso breve.
class SocialNotificationListener extends ConsumerStatefulWidget {
  final Widget child;

  const SocialNotificationListener({super.key, required this.child});

  @override
  ConsumerState<SocialNotificationListener> createState() => _SocialNotificationListenerState();
}

class _SocialNotificationListenerState extends ConsumerState<SocialNotificationListener> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<SocialRealtimeEvent>>(
      socialRealtimeProvider,
      (prev, next) {
        next.whenData(_onRealtimeEvent);
      },
      fireImmediately: false,
    );
  }

  void _onRealtimeEvent(SocialRealtimeEvent event) {
    if (event.message.isEmpty) return;

    ref.invalidate(socialNotificationsProvider);
    ref.invalidate(socialUnreadCountProvider);

    final l10n = context.l10n;
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(event.message),
        duration: const Duration(seconds: 5),
        showCloseIcon: true,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        action: SnackBarAction(
          label: l10n.view,
          onPressed: () => _openNotification(event),
        ),
      ),
    );
  }

  Future<void> _openNotification(SocialRealtimeEvent event) async {
    rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();

    try {
      await ref.read(socialServiceProvider).markNotificationRead(event.notificationId);
      ref.invalidate(socialNotificationsProvider);
      ref.invalidate(socialUnreadCountProvider);
    } catch (_) {}

    if (!mounted) return;
    if (event.actorId.isNotEmpty) {
      context.push('/social/friend/${event.actorId}');
    } else {
      context.go('/social');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
