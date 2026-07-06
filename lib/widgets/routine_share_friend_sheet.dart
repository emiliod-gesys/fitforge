import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../models/routine.dart';
import '../models/social.dart';
import '../providers/app_providers.dart';
import 'fitforge_loading_indicator.dart';
import 'profile_avatar.dart';

class RoutineShareFriendSheet extends ConsumerWidget {
  final Routine routine;

  const RoutineShareFriendSheet({super.key, required this.routine});

  static Future<void> show(BuildContext context, Routine routine) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        builder: (_, __) => RoutineShareFriendSheet(routine: routine),
      ),
    );
  }

  Future<void> _send(BuildContext context, WidgetRef ref, FriendUser friend) async {
    final l10n = context.l10n;
    try {
      await ref.read(routineShareServiceProvider).sendRoutineShare(
            routineId: routine.id,
            recipientId: friend.id,
          );
      ref.invalidate(socialNotificationsProvider);
      ref.invalidate(socialUnreadCountProvider);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.shareRoutineSent(friend.label))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.shareRoutineFailed('$e')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final friendshipsAsync = ref.watch(friendshipsProvider);

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.shareRoutineTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        routine.name,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              l10n.shareRoutineSelectFriend,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: friendshipsAsync.when(
              loading: () => const Center(child: FitForgeLoadingIndicator()),
              error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
              data: (friendships) {
                final uid = ref.watch(authStateProvider).valueOrNull?.session?.user.id;
                final friends = friendships
                    .where((f) => f.status == FriendshipStatus.accepted)
                    .map((f) => uid != null ? f.friendFor(uid) : null)
                    .whereType<FriendUser>()
                    .toList();

                if (friends.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.shareRoutineNoFriends,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                  itemCount: friends.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return ListTile(
                      leading: ProfileAvatar(
                        avatarUrl: friend.avatarUrl,
                        radius: 22,
                        fallbackLetter: friend.label,
                      ),
                      title: Text(friend.label),
                      trailing: const Icon(Icons.send, color: AppColors.orange),
                      onTap: () => _send(context, ref, friend),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
