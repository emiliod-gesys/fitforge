import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../models/social.dart';
import '../providers/app_providers.dart';
import 'fitforge_loading_indicator.dart';
import 'routine_share_request_dialog.dart';

class SocialNotificationsBellButton extends ConsumerWidget {
  const SocialNotificationsBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unread = ref.watch(socialUnreadCountProvider).valueOrNull ?? 0;

    return IconButton(
      tooltip: l10n.notifications,
      onPressed: () => SocialNotificationsSheet.show(context),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 9 ? '9+' : '$unread'),
        child: Icon(
          unread > 0 ? Icons.notifications : Icons.notifications_outlined,
        ),
      ),
    );
  }
}

class SocialNotificationsSheet extends ConsumerWidget {
  const SocialNotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.62,
            child: const SocialNotificationsSheet(),
          ),
        ),
      ),
    );
  }

  Future<void> _markAllRead(WidgetRef ref) async {
    await ref.read(socialServiceProvider).markAllNotificationsRead();
    ref.invalidate(socialNotificationsProvider);
    ref.invalidate(socialUnreadCountProvider);
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    SocialNotification notification,
  ) async {
    if (notification.isRoutineShare && notification.referenceId != null) {
      if (!context.mounted) return;
      await RoutineShareRequestDialog.show(context, notification.referenceId!);
      ref.invalidate(socialNotificationsProvider);
      ref.invalidate(socialUnreadCountProvider);
      return;
    }

    if (notification.isUnread) {
      await ref.read(socialServiceProvider).markNotificationRead(notification.id);
      ref.invalidate(socialNotificationsProvider);
      ref.invalidate(socialUnreadCountProvider);
    }

    if (!context.mounted) return;
    Navigator.pop(context);

    if (notification.actorId.isNotEmpty) {
      context.push('/social/friend/${notification.actorId}');
    }
  }

  Future<void> _respondShare(
    BuildContext context,
    WidgetRef ref,
    SocialNotification notification,
    bool accept,
  ) async {
    final requestId = notification.referenceId;
    if (requestId == null) return;
    final l10n = context.l10n;

    try {
      await ref.read(routineShareServiceProvider).respondToShare(
            requestId: requestId,
            accept: accept,
          );
      ref.invalidate(socialNotificationsProvider);
      ref.invalidate(socialUnreadCountProvider);
      if (accept) ref.invalidate(routinesProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? l10n.routineShareAccepted : l10n.routineShareDeclined),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.saveFailed('$e')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notificationsAsync = ref.watch(socialNotificationsProvider);

    return Material(
      color: AppColors.card,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.notifications,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                notificationsAsync.maybeWhen(
                  data: (list) {
                    if (!list.any((n) => n.isUnread)) return const SizedBox.shrink();
                    return TextButton(
                      onPressed: () => _markAllRead(ref),
                      child: Text(l10n.markRead),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: notificationsAsync.when(
              loading: () => const Center(child: FitForgeLoadingIndicator()),
              error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
              data: (notifications) {
                if (notifications.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.friendWorkoutNotify,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(socialNotificationsProvider);
                    ref.invalidate(socialUnreadCountProvider);
                    await ref.read(socialNotificationsProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final isShare = notification.isRoutineShare && notification.isUnread;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: notification.isUnread
                                  ? AppColors.orange.withValues(alpha: 0.2)
                                  : AppColors.cardElevated,
                              child: Icon(
                                notification.isRoutineShare
                                    ? Icons.share_outlined
                                    : Icons.fitness_center,
                                color: notification.isUnread
                                    ? AppColors.orange
                                    : AppColors.textMuted,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              notification.message,
                              style: TextStyle(
                                fontWeight:
                                    notification.isUnread ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              l10n.timeAgo(notification.createdAt),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            onTap: () => _openNotification(context, ref, notification),
                          ),
                          if (isShare && notification.referenceId != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => RoutineShareRequestDialog.show(
                                        context,
                                        notification.referenceId!,
                                      ),
                                      child: Text(l10n.previewRoutine),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _respondShare(context, ref, notification, false),
                                      child: Text(l10n.decline),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _respondShare(context, ref, notification, true),
                                      child: Text(l10n.accept),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
