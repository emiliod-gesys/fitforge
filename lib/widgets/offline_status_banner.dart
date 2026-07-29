import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../providers/app_providers.dart';

class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              if (online && pending > 0)
                TextButton(
                  onPressed: () async {
                    await ref.read(workoutSyncServiceProvider).syncPending();
                    ref.invalidate(pendingSyncCountProvider);
                  },
                  child: Text(l10n.offlineSyncNow),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
