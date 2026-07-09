import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/utils/player_level.dart';
import '../../core/utils/player_level_badge.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';

class ProgressHeroCard extends StatelessWidget {
  final PlayerLevelProgress progress;
  final AppLocalizations l10n;

  const ProgressHeroCard({
    super.key,
    required this.progress,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = progress.level;
    final badgeAsset = PlayerLevelBadge.assetForLevel(level);
    final badgeName = l10n.playerLevelBadgeName(level);
    final fraction = progress.progressFraction;
    final remainingXp = progress.isMaxLevel
        ? 0
        : (progress.xpToNextLevel - progress.xpInCurrentLevel).clamp(0, progress.xpToNextLevel);

    return Container(
      decoration: AppDecorations.heroCard(context.appAccent),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: badgeAsset != null
                      ? Image.asset(badgeAsset, fit: BoxFit.contain)
                      : const Icon(Icons.military_tech, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badgeName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        l10n.playerLevelTitle(level),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.progressTotalXp(progress.totalXp),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              progress.isMaxLevel
                  ? l10n.playerLevelMax
                  : l10n.progressXpToNext(remainingXp, level + 1),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.04, end: 0, duration: 350.ms, curve: Curves.easeOutCubic);
  }
}
