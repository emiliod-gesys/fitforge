import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/feed_personal_record.dart';
import '../../core/utils/milestone_badge.dart';
import '../../core/utils/player_level_badge.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/feed_reaction.dart';
import '../../models/profile.dart';
import '../../models/social.dart';
import '../../providers/app_providers.dart';
import '../../widgets/ff/ff_button.dart';
import '../../widgets/ff/ff_empty_state.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/social/feed_compose_sheet.dart';
import '../../widgets/social/feed_reaction_picker.dart';

class SocialFeedTab extends ConsumerWidget {
  const SocialFeedTab({
    super.key,
    required this.onRefresh,
    this.onFindFriends,
  });

  final Future<void> Function() onRefresh;
  final VoidCallback? onFindFriends;

  Future<void> _compose(BuildContext context) async {
    final published = await FeedComposeSheet.show(context);
    if (published == true) onRefresh();
  }

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
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.62,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FfEmptyState(
                            icon: Icons.dynamic_feed_rounded,
                            title: l10n.emptyFeedTitle,
                            subtitle: l10n.emptyFeedSubtitle,
                            actionLabel: l10n.feedEmptyCreatePost,
                            onAction: () => _compose(context),
                          ),
                          if (onFindFriends != null) ...[
                            const SizedBox(height: AppTokens.space12),
                            FfButton(
                              label: l10n.feedEmptyFindFriends,
                              variant: FfButtonVariant.secondary,
                              icon: Icons.person_search_outlined,
                              onPressed: onFindFriends,
                            ),
                          ],
                        ],
                      ),
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
                itemCount: items.length,
                itemBuilder: (context, index) {
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
          loading: () => const Center(child: FitForgeLoadingIndicator(size: 100)),
          error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _compose(context),
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

  Future<void> _react(BuildContext context, WidgetRef ref) async {
    final postId = item.feedPostId;
    if (postId == null) return;
    await FeedReactionPicker.show(
      context,
      ref,
      postId: postId,
      selectedEmoji: post.reactions.myEmoji,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accent = context.accentColor;
    final actor = item.actor;
    final actorName = actor?.label ?? l10n.user;
    final canReact = item.feedPostId != null;

    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.75)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => _openProfile(context),
                        child: Text(
                          actorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.timeAgo(item.createdAt),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _FeedItemBadge(item: item),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.feedItemMessage(
                item,
                unitSystem: unitSystem,
                currentUserId: currentUserId,
              ),
              style: const TextStyle(color: AppColors.textPrimary, height: 1.4, fontSize: 14.5),
            ),
            if (item.isUserPost && post.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, __) => Container(
                      color: AppColors.surface,
                      alignment: Alignment.center,
                      child: const FitForgeLoadingIndicator(size: 48),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surface,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
            ],
            if (item.isUserPost && item.feedAttachedPersonalRecord != null) ...[
              const SizedBox(height: 10),
              _FeedPrChip(
                record: item.feedAttachedPersonalRecord!,
                unitSystem: unitSystem,
              ),
            ],
            if (canReact)
              FeedReactionBar(
                entries: post.reactions.sortedEntries,
                myEmoji: post.reactions.myEmoji,
                onEmojiTap: (emoji) async {
                  await ref.read(socialServiceProvider).toggleFeedReaction(
                        postId: item.feedPostId!,
                        emoji: emoji,
                      );
                  ref.invalidate(socialFeedProvider);
                },
              ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.border),
            Row(
              children: [
                if (canReact)
                  TextButton.icon(
                    onPressed: () => _react(context, ref),
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      size: 18,
                      color: post.reactions.myEmoji != null ? accent : AppColors.textMuted,
                    ),
                    label: Text(
                      l10n.feedReactAction,
                      style: TextStyle(
                        color: post.reactions.myEmoji != null ? accent : AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                TextButton.icon(
                  onPressed: onOpenComments,
                  icon: Icon(Icons.chat_bubble_outline, size: 18, color: accent),
                  label: Text(
                    post.commentCount > 0
                        ? l10n.feedCommentCount(post.commentCount)
                        : l10n.feedCommentAction,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
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
        width: 36,
        height: 36,
        errorBuilder: (_, __, ___) => Icon(Icons.emoji_events, color: context.accentColor, size: 28),
      );
    }

    if (item.isLevelUp) {
      final level = item.levelReached ?? item.actor?.level ?? 1;
      final asset = PlayerLevelBadge.assetForLevel(level);
      if (asset != null) {
        return Image.asset(
          asset,
          width: 36,
          height: 36,
          errorBuilder: (_, __, ___) => Icon(Icons.trending_up, color: context.accentColor, size: 28),
        );
      }
      return Icon(Icons.trending_up, color: context.accentColor, size: 28);
    }

    if (item.isPrUnlock) {
      return Icon(Icons.emoji_events, color: context.accentColor, size: 28);
    }

    if (item.isUserPost) {
      return Icon(Icons.chat_bubble_outline, color: AppColors.textMuted, size: 22);
    }

    return Icon(Icons.fitness_center, color: context.accentColor, size: 24);
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
        color: context.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.accentColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 18, color: context.accentColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${record.exerciseName} · ${FeedPersonalRecord.formatValue(record, unitSystem)}',
              style: const TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
