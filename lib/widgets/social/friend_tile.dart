import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/player_level_badge.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/social.dart';
import '../profile_avatar.dart';
import '../tappable_badge.dart';

class FriendTile extends StatelessWidget {
  final FriendUser friend;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  const FriendTile({
    super.key,
    required this.friend,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final badgeAsset = PlayerLevelBadge.assetForLevel(friend.level);
    final badgeName = l10n.playerLevelBadgeName(friend.level);

    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              ProfileAvatar(
                avatarUrl: friend.avatarUrl,
                radius: 22,
                fallbackLetter: friend.label,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.playerLevelRankSummary(friend.level),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeAsset != null)
                TappableBadge(
                  label: badgeName,
                  child: Image.asset(
                    badgeAsset,
                    width: 36,
                    height: 36,
                    errorBuilder: (_, __, ___) => const SizedBox(width: 36, height: 36),
                  ),
                ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
