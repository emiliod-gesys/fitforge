import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/player_level.dart';
import '../../core/utils/player_level_badge.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';

class SocialHeroCard extends StatelessWidget {
  final PlayerLevelProgress? progress;
  final int friendsCount;
  final int pendingCount;
  final int? friendsRank;
  final int? globalRank;
  final bool isLoading;
  final AppLocalizations l10n;

  const SocialHeroCard({
    super.key,
    required this.progress,
    required this.friendsCount,
    required this.pendingCount,
    required this.friendsRank,
    required this.globalRank,
    required this.isLoading,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = progress?.level ?? 1;
    final badgeAsset = PlayerLevelBadge.assetForLevel(level);
    final badgeName = l10n.playerLevelBadgeName(level);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6622), Color(0xFFE05518), Color(0xFF8B3A12)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: badgeAsset != null
                      ? Image.asset(badgeAsset, fit: BoxFit.contain)
                      : const Icon(Icons.groups, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.socialHeroTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (isLoading)
                        Text(
                          l10n.socialHeroSubtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else ...[
                        Text(
                          friendsRank != null
                              ? l10n.socialHeroRank(friendsRank!)
                              : l10n.socialHeroNoRank,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (globalRank != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            l10n.socialHeroRankGlobal(globalRank!),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                if (!isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: Text(
                      badgeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatPill(
                  icon: Icons.people_outline,
                  label: isLoading ? '—' : l10n.socialHeroFriends(friendsCount),
                ),
                const SizedBox(width: 10),
                _StatPill(
                  icon: Icons.mail_outline,
                  label: isLoading ? '—' : l10n.socialHeroPending(pendingCount),
                  highlight: pendingCount > 0,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.04, curve: Curves.easeOutCubic);
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _StatPill({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: highlight
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
