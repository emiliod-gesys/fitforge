import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_scaffold.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../providers/app_providers.dart';
import '../services/supabase_service.dart';

class OfflineStatusBanner extends ConsumerStatefulWidget {
  const OfflineStatusBanner({super.key});

  @override
  ConsumerState<OfflineStatusBanner> createState() => _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends ConsumerState<OfflineStatusBanner> {
  bool _busy = false;

  Future<void> _uploadNow() async {
    if (_busy) return;
    final l10n = context.l10n;
    if (SupabaseService.currentUser == null) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(l10n.offlineSyncNeedSignIn)),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(workoutSyncServiceProvider).syncPending();
      ref.invalidate(pendingSyncCountProvider);
      final remaining =
          await ref.read(offlineWorkoutSupportProvider).pendingSyncCount();
      if (!mounted) return;
      if (remaining > 0) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(l10n.offlineSyncFailed)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(l10n.offlineSyncFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dismissPending() async {
    if (_busy) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.offlineDismissPendingTitle),
        content: Text(l10n.offlineDismissPendingBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.offlineDismissPending),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(offlineWorkoutSupportProvider).discardPendingUploads();
      ref.invalidate(pendingSyncCountProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final pending = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final l10n = context.l10n;

    if (online && pending == 0) return const SizedBox.shrink();

    final message = !online
        ? l10n.offlineModeBanner
        : l10n.offlinePendingSyncBanner(pending);

    return Material(
      color: !online ? AppColors.error.withValues(alpha: 0.92) : AppColors.cardElevated,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                !online ? Icons.cloud_off_outlined : Icons.cloud_sync_outlined,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (online && pending > 0)
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: _uploadNow,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(l10n.offlineSyncNow),
                        ),
                        TextButton(
                          onPressed: _dismissPending,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(l10n.offlineDismissPending),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
