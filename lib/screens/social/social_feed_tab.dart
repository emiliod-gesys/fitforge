import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/feed_personal_record.dart';
import '../../core/utils/milestone_badge.dart';
import '../../core/utils/player_level_badge.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/feed_reaction.dart';
import '../../models/profile.dart';
import '../../models/social.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/social/feed_compose_sheet.dart';
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

    return Stack(
      children: [
        feedAsync.when(
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
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
                            l10n.feedTapToComment,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.feedLongPressCommentToReact,
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
                    onOpenComments: () {
                      final id = post.notification.feedPostId ?? post.notification.id;
                      context.push('/social/post/$id');
                    },
                  );
                },
              ),
            );
          },
          loading: () => Center(child: FitForgeLoadingIndicator(size: 100)),
          error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () async {
              final published = await FeedComposeSheet.show(context);
              if (published == true) onRefresh();
            },
            child: const Icon(Icons.edit_outlined),
          ),
        ),
      ],
    );
  }
}

class _FeedItemTile extends ConsumerWidget {
  const _FeedItemTile({
    required this.post,
    required this.unitSystem,
    required this.currentUserId,
    required this.onOpenComments,
  });

  final FeedPost post;
  final String unitSystem;
  final String? currentUserId;
  final VoidCallback onOpenComments;

  SocialNotification get item => post.notification;

  void _openProfile(BuildContext context) {
    if (item.actorId.isEmpty) return;
    if (item.isOwnPost(currentUserId)) {
      context.push('/profile');
    } else {
      context.push('/social/friend/${item.actorId}');
    }
  }

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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openProfile(context),
                borderRadius: BorderRadius.circular(22),
                child: ProfileAvatar(
                  avatarUrl: actor?.avatarUrl,
                  radius: 22,
                  fallbackLetter: actorName,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpenComments,
                  onLongPress: () => FeedReactionPicker.show(
                    context,
                    ref,
                    notificationId: item.id,
                    selectedEmoji: post.reactions.myEmoji,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
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
                    if (item.isUserPost && post.imageUrl != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: post.imageUrl!,
                          fit: BoxFit.cover,
                          height: 180,
                          width: double.infinity,
                          placeholder: (_, __) => Container(
                            height: 180,
                            color: AppColors.surface,
                            alignment: Alignment.center,
                            child: const FitForgeLoadingIndicator(size: 48),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 120,
                            color: AppColors.surface,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ],
                    if (item.isUserPost && item.feedAttachedPersonalRecord != null) ...[
                      const SizedBox(height: 8),
                      _FeedPrChip(
                        record: item.feedAttachedPersonalRecord!,
                        unitSystem: unitSystem,
                      ),
                    ],
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
                    if (post.commentCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 14, color: context.accentColor),
                            const SizedBox(width: 4),
                            Text(
                              l10n.feedCommentCount(post.commentCount),
                              style: TextStyle(
                                color: context.accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _FeedItemBadge(item: item),
          ],
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

    if (item.isUserPost) {
      return Icon(Icons.chat_bubble_outline, color: context.accentColor, size: 28);
    }

    return Icon(Icons.fitness_center, color: context.accentColor, size: 28);
  }
}

class _FeedPrChip extends StatelessWidget {
  const _FeedPrChip({required this.record, required this.unitSystem});

  final PersonalRecord record;
  final String unitSystem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 18, color: context.accentColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${record.exerciseName} · ${FeedPersonalRecord.formatValue(record, unitSystem)}',
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
