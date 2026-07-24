import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../models/social.dart';
import '../providers/app_providers.dart';
import 'fitforge_loading_indicator.dart';
import 'routine_share_request_dialog.dart';
import '../core/theme/app_accent.dart';

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

    if ((notification.isTrainerRequest || notification.isFriendRequest) &&
        notification.isUnread) {
      return;
    }

    final postId = notification.bellPostId;
    if (postId != null &&
        (notification.isFeedComment ||
            notification.isFeedReaction ||
            notification.isFeedCommentReaction)) {
      if (notification.isUnread) {
        await ref.read(socialServiceProvider).markNotificationRead(notification.id);
        ref.invalidate(socialNotificationsProvider);
        ref.invalidate(socialUnreadCountProvider);
      }

      if (!context.mounted) return;
      Navigator.pop(context);
      context.push('/social/post/$postId');
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

  Future<void> _respondTrainerRequest(
    BuildContext context,
    WidgetRef ref,
    SocialNotification notification,
    bool accept,
  ) async {
    final requestId = notification.referenceId;
    if (requestId == null) return;
    final l10n = context.l10n;

    try {
      await ref.read(trainerServiceProvider).respondToTrainerRequest(
            requestId: requestId,
            accept: accept,
          );
      ref.invalidate(socialNotificationsProvider);
      ref.invalidate(socialUnreadCountProvider);
      ref.invalidate(myTrainerProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? l10n.trainerRequestAccepted : l10n.trainerRequestDeclined),
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

  Future<void> _respondFriendRequest(
    BuildContext context,
    WidgetRef ref,
    SocialNotification notification,
    bool accept,
  ) async {
    final friendshipId = notification.referenceId;
    if (friendshipId == null) return;
    final l10n = context.l10n;
    final social = ref.read(socialServiceProvider);

    try {
      if (accept) {
        await social.acceptFriendRequest(friendshipId);
      } else {
        await social.removeFriendship(friendshipId);
      }

      if (notification.isUnread) {
        await social.markNotificationRead(notification.id);
      }

      ref.invalidate(socialNotificationsProvider);
      ref.invalidate(socialUnreadCountProvider);
      ref.invalidate(friendshipsProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? l10n.friendRequestAccepted : l10n.friendRequestDeclined),
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

  IconData _iconFor(SocialNotification notification) {
    if (notification.isRoutineShare) return Icons.share_outlined;
    if (notification.isTrainerRequest) return Icons.school_outlined;
    if (notification.isFriendRequest) return Icons.person_add_outlined;
    if (notification.isFeedComment) return Icons.chat_bubble_outline;
    if (notification.isFeedReaction || notification.isFeedCommentReaction) {
      return Icons.favorite_outline;
    }
    return Icons.notifications_outlined;
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
                        l10n.socialNotificationsEmpty,
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
                      final isTrainerReq =
                          notification.isTrainerRequest && notification.isUnread;
                      final isFriendReq =
                          notification.isFriendRequest && notification.isUnread;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: notification.isUnread
                                  ? context.accentColor.withValues(alpha: 0.2)
                                  : AppColors.cardElevated,
                              child: Icon(
                                _iconFor(notification),
                                color: notification.isUnread
                                    ? context.accentColor
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
                          if (isTrainerReq && notification.referenceId != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _respondTrainerRequest(
                                          context, ref, notification, false),
                                      child: Text(l10n.decline),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _respondTrainerRequest(
                                          context, ref, notification, true),
                                      child: Text(l10n.accept),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isFriendReq && notification.referenceId != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _respondFriendRequest(
                                          context, ref, notification, false),
                                      child: Text(l10n.decline),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _respondFriendRequest(
                                          context, ref, notification, true),
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
