import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/l10n_extensions.dart';
import '../../providers/app_providers.dart';

/// Escucha notificaciones sociales en tiempo real y muestra un aviso breve.
class SocialNotificationListener extends ConsumerWidget {
  final Widget child;

  const SocialNotificationListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    ref.listen<AsyncValue<String>>(socialRealtimeProvider, (prev, next) {
      next.whenData((message) {
        ref.invalidate(socialNotificationsProvider);
        ref.invalidate(socialUnreadCountProvider);

        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: l10n.view,
              onPressed: () => context.go('/social'),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      });
    });

    return child;
  }
}
