import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/feed_reactions.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';

abstract final class FeedReactionPicker {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required String notificationId,
    String? selectedEmoji,
  }) async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: FeedReactions.emojis.map((e) {
              final isSelected = e == selectedEmoji;
              return InkWell(
                onTap: () => Navigator.pop(ctx, e),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.accentColor.withValues(alpha: 0.2)
                        : AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? context.accentColor : AppColors.border,
                    ),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 28)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (emoji == null || !context.mounted) return;

    await ref.read(socialServiceProvider).toggleFeedReaction(
          notificationId: notificationId,
          emoji: emoji,
        );
    ref.invalidate(socialFeedProvider);
  }
}

class FeedReactionBar extends StatelessWidget {
  const FeedReactionBar({
    super.key,
    required this.entries,
    required this.myEmoji,
    required this.onEmojiTap,
  });

  final List<MapEntry<String, int>> entries;
  final String? myEmoji;
  final ValueChanged<String> onEmojiTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: entries.map((entry) {
          final isMine = entry.key == myEmoji;
          return InkWell(
            onTap: () => onEmojiTap(entry.key),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isMine
                    ? context.accentColor.withValues(alpha: 0.18)
                    : AppColors.cardElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isMine ? context.accentColor.withValues(alpha: 0.5) : AppColors.border,
                ),
              ),
              child: Text(
                '${entry.key} ${entry.value}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isMine ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
