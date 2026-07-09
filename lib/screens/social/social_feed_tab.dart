import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/milestone_badge.dart';
import '../../core/utils/player_level_badge.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/feed_reaction.dart';
import '../../models/social.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/social/feed_reaction_picker.dart';

class SocialFeedTab extends ConsumerWidget {
  const SocialFeedTab({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unitSystem = ref.watch(unitSystemProvider);
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.session?.user.id;
    final feedAsync = ref.watch(socialFeedProvider);

    return feedAsync.when(
      skipLoadingOnReload: true,
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 48),
                Icon(Icons.dynamic_feed_outlined, size: 56, color: context.accentColor.withValues(alpha: 0.7)),
                const SizedBox(height: 16),
                Text(
                  l10n.feedEmptyTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.feedEmptySubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == items.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Column(
                    children: [
                      Text(
                        l10n.feedLongPressToReact,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.feedExpiryHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                );
              }

              final post = items[index];
              return _FeedItemTile(
                post: post,
                unitSystem: unitSystem,
                currentUserId: currentUserId,
                onTap: post.notification.actorId.isEmpty
                    ? null
                    : () {
                        if (post.notification.isOwnPost(currentUserId)) {
                          context.push('/profile');
                        } else {
                          context.push('/social/friend/${post.notification.actorId}');
                        }
                      },
              );
            },
          ),
        );
      },
      loading: () => Center(child: FitForgeLoadingIndicator(size: 100)),
      error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
    );
  }
}

class _FeedItemTile extends ConsumerWidget {
  const _FeedItemTile({
    required this.post,
    required this.unitSystem,
    required this.currentUserId,
    this.onTap,
  });

  final FeedPost post;
  final String unitSystem;
  final String? currentUserId;
  final VoidCallback? onTap;

  SocialNotification get item => post.notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final actor = item.actor;
    final actorName = actor?.label ?? l10n.user;

    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => FeedReactionPicker.show(
          context,
          ref,
          notificationId: item.id,
          selectedEmoji: post.reactions.myEmoji,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                avatarUrl: actor?.avatarUrl,
                radius: 22,
                fallbackLetter: actorName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.feedItemMessage(
                        item,
                        unitSystem: unitSystem,
                        currentUserId: currentUserId,
                      ),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.timeAgo(item.createdAt),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    FeedReactionBar(
                      entries: post.reactions.sortedEntries,
                      myEmoji: post.reactions.myEmoji,
                      onEmojiTap: (emoji) async {
                        await ref.read(socialServiceProvider).toggleFeedReaction(
                              notificationId: item.id,
                              emoji: emoji,
                            );
                        ref.invalidate(socialFeedProvider);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _FeedItemBadge(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedItemBadge extends StatelessWidget {
  const _FeedItemBadge({required this.item});

  final SocialNotification item;

  @override
  Widget build(BuildContext context) {
    if (item.isMilestoneUnlock) {
      final tier = item.milestoneTier ?? 1;
      return Image.asset(
        MilestoneBadge.assetPathForTier(tier),
        width: 40,
        height: 40,
        errorBuilder: (_, __, ___) => Icon(Icons.emoji_events, color: context.accentColor, size: 32),
      );
    }

    if (item.isLevelUp) {
      final level = item.levelReached ?? item.actor?.level ?? 1;
      final asset = PlayerLevelBadge.assetForLevel(level);
      if (asset != null) {
        return Image.asset(
          asset,
          width: 40,
          height: 40,
          errorBuilder: (_, __, ___) => Icon(Icons.trending_up, color: context.accentColor, size: 32),
        );
      }
      return Icon(Icons.trending_up, color: context.accentColor, size: 32);
    }

    if (item.isPrUnlock) {
      return Icon(Icons.emoji_events, color: context.accentColor, size: 32);
    }

    return Icon(Icons.fitness_center, color: context.accentColor, size: 28);
  }
}
