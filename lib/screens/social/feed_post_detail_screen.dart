import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/social_feed.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/feed_personal_record.dart';
import '../../core/utils/milestone_badge.dart';
import '../../core/utils/player_level_badge.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/feed_comment.dart';
import '../../models/profile.dart';
import '../../models/social.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/social/feed_reaction_picker.dart';

class FeedPostDetailScreen extends ConsumerStatefulWidget {
  const FeedPostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<FeedPostDetailScreen> createState() => _FeedPostDetailScreenState();
}

class _FeedPostDetailScreenState extends ConsumerState<FeedPostDetailScreen> {
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment(FeedPostDetailData detail) async {
    final body = _commentController.text.trim();
    final postId = detail.commentPostId;
    if (body.isEmpty || _submitting || postId == null) return;

    final l10n = context.l10n;
    setState(() => _submitting = true);
    try {
      await ref.read(socialServiceProvider).addFeedComment(
            postId: postId,
            body: body,
          );
      _commentController.clear();
      ref.invalidate(feedPostDetailProvider(widget.postId));
      ref.invalidate(socialFeedProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.feedCommentFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmDeletePost(FeedPostDetailData detail) async {
    final l10n = context.l10n;
    final postId = detail.commentPostId;
    if (postId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.feedDeletePostTitle),
        content: Text(l10n.feedDeletePostBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(socialServiceProvider).deleteFeedPost(postId);
      ref.invalidate(socialFeedProvider);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.feedPostDeleted)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric('$e'))),
      );
    }
  }

  Future<void> _confirmDeleteComment(FeedComment comment) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.feedDeleteCommentTitle),
        content: Text(l10n.feedDeleteCommentBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(socialServiceProvider).deleteFeedComment(comment.id);
      ref.invalidate(feedPostDetailProvider(widget.postId));
      ref.invalidate(socialFeedProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.feedCommentDeleted)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unitSystem = ref.watch(unitSystemProvider);
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.session?.user.id;
    final detailAsync = ref.watch(feedPostDetailProvider(widget.postId));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: FitForgeAppBar(
        title: l10n.feedPostDetailTitle,
        actions: [
          detailAsync.maybeWhen(
            data: (detail) {
              if (detail == null || !detail.canDeletePost(currentUserId)) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: l10n.feedDeletePostTitle,
                onPressed: () => _confirmDeletePost(detail),
                icon: const Icon(Icons.delete_outline),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return Center(child: Text(l10n.feedPostNotFound));
          }

          final post = detail.post;
          final item = post.notification;
          final actor = item.actor;
          final actorName = actor?.label ?? l10n.user;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  children: [
                    Card(
                      color: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: InkWell(
                        onLongPress: item.id.isEmpty
                            ? null
                            : () => FeedReactionPicker.show(
                                  context,
                                  ref,
                                  notificationId: item.id,
                                  selectedEmoji: post.reactions.myEmoji,
                                  refreshPostDetailId: widget.postId,
                                ),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: item.actorId.isEmpty
                                      ? null
                                      : () {
                                          if (item.isOwnPost(currentUserId)) {
                                            context.push('/profile');
                                          } else {
                                            context.push('/social/friend/${item.actorId}');
                                          }
                                        },
                                  borderRadius: BorderRadius.circular(24),
                                  child: ProfileAvatar(
                                    avatarUrl: actor?.avatarUrl,
                                    radius: 22,
                                    fallbackLetter: actorName,
                                  ),
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
                                    ],
                                  ),
                                ),
                                _FeedPostBadge(item: item),
                              ],
                            ),
                            if (item.isUserPost && post.imageUrl != null) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 220),
                                  child: CachedNetworkImage(
                                    imageUrl: post.imageUrl!,
                                    fit: BoxFit.cover,
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
                              ),
                            ],
                            if (item.feedAttachedPersonalRecord != null) ...[
                              const SizedBox(height: 10),
                              _FeedPrChip(
                                record: item.feedAttachedPersonalRecord!,
                                unitSystem: unitSystem,
                              ),
                            ],
                            if (item.id.isNotEmpty)
                              FeedReactionBar(
                                entries: post.reactions.sortedEntries,
                                myEmoji: post.reactions.myEmoji,
                                onEmojiTap: (emoji) async {
                                  await ref.read(socialServiceProvider).toggleFeedReaction(
                                        notificationId: item.id,
                                        emoji: emoji,
                                      );
                                  ref.invalidate(feedPostDetailProvider(widget.postId));
                                  ref.invalidate(socialFeedProvider);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.feedCommentsTitle(detail.comments.length),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (detail.comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          l10n.feedCommentsEmpty,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    else
                      ...detail.comments.map(
                        (comment) => _CommentTile(
                          comment: comment,
                          currentUserId: currentUserId,
                          postRouteId: widget.postId,
                          onDelete: () => _confirmDeleteComment(comment),
                        ),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: detail.canComment
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                maxLength: SocialFeed.maxCommentLength,
                                maxLines: 3,
                                minLines: 1,
                                enabled: !_submitting,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _submitComment(detail),
                                decoration: InputDecoration(
                                  hintText: l10n.feedCommentHint,
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _submitting ? null : () => _submitComment(detail),
                              icon: _submitting
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded),
                            ),
                          ],
                        )
                      : Text(
                          l10n.feedCommentsUnavailable,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: FitForgeLoadingIndicator(size: 100)),
        error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
      ),
    );
  }
}

class _CommentTile extends ConsumerWidget {
  const _CommentTile({
    required this.comment,
    required this.currentUserId,
    required this.postRouteId,
    required this.onDelete,
  });

  final FeedComment comment;
  final String? currentUserId;
  final String postRouteId;
  final VoidCallback onDelete;

  bool get _isOwn => currentUserId != null && comment.userId == currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final authorName = comment.author?.label ?? l10n.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            avatarUrl: comment.author?.avatarUrl,
            radius: 16,
            fallbackLetter: authorName,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onLongPress: () => FeedReactionPicker.show(
                  context,
                  ref,
                  commentId: comment.id,
                  selectedEmoji: comment.reactions.myEmoji,
                  refreshPostDetailId: postRouteId,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              authorName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          if (_isOwn)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              tooltip: l10n.feedDeleteCommentTitle,
                              onPressed: onDelete,
                              icon: const Icon(Icons.delete_outline, size: 16),
                            ),
                          Text(
                            l10n.timeAgo(comment.createdAt),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.body,
                        style: const TextStyle(height: 1.35),
                      ),
                      FeedReactionBar(
                        compact: true,
                        entries: comment.reactions.sortedEntries,
                        myEmoji: comment.reactions.myEmoji,
                        onEmojiTap: (emoji) async {
                          await ref.read(socialServiceProvider).toggleFeedCommentReaction(
                                commentId: comment.id,
                                emoji: emoji,
                              );
                          ref.invalidate(feedPostDetailProvider(postRouteId));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedPostBadge extends StatelessWidget {
  const _FeedPostBadge({required this.item});

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
        return Image.asset(asset, width: 36, height: 36);
      }
      return Icon(Icons.trending_up, color: context.accentColor, size: 28);
    }
    if (item.isPrUnlock) {
      return Icon(Icons.emoji_events, color: context.accentColor, size: 28);
    }
    if (item.isUserPost) {
      return Icon(Icons.chat_bubble_outline, color: context.accentColor, size: 24);
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
