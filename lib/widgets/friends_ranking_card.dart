import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/social.dart';
import '../widgets/profile_avatar.dart';

class FriendsRankingCard extends StatelessWidget {
  final List<FriendRankingEntry> entries;
  final AppLocalizations l10n;

  const FriendsRankingCard({
    super.key,
    required this.entries,
    required this.l10n,
  });

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 56),
              _RankingTile(
                entry: entries[i],
                l10n: l10n,
                rankColor: _rankColor(entries[i].rank),
                onTap: entries[i].isCurrentUser
                    ? null
                    : () => context.push('/social/friend/${entries[i].user.id}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  final FriendRankingEntry entry;
  final AppLocalizations l10n;
  final Color rankColor;
  final VoidCallback? onTap;

  const _RankingTile({
    required this.entry,
    required this.l10n,
    required this.rankColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = entry.user;
    final name = entry.isCurrentUser ? l10n.rankYou(user.label) : user.label;

    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 40,
        child: Text(
          '#${entry.rank}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: entry.rank <= 3 ? 16 : 14,
            color: rankColor,
          ),
        ),
      ),
      title: Row(
        children: [
          ProfileAvatar(
            avatarUrl: user.avatarUrl,
            radius: 16,
            fallbackLetter: user.label,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: entry.isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                    color: entry.isCurrentUser ? AppColors.orange : AppColors.textPrimary,
                  ),
                ),
                Text(
                  l10n.playerLevelTitle(user.level),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${user.totalXp} XP',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.orange,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
