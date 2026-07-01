import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/player_level.dart';
import '../core/utils/player_level_badge.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';

class PlayerLevelCard extends StatelessWidget {
  final PlayerLevelProgress progress;
  final AppLocalizations l10n;

  const PlayerLevelCard({
    super.key,
    required this.progress,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          children: [
            _CircularLevelRing(progress: progress, l10n: l10n),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress.isMaxLevel
                        ? l10n.playerLevelMax
                        : l10n.playerXpProgress(
                            progress.xpInCurrentLevel,
                            progress.xpToNextLevel,
                          ),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
                Text(
                  '${progress.totalXp} XP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w700,
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

class _CircularLevelRing extends StatelessWidget {
  final PlayerLevelProgress progress;
  final AppLocalizations l10n;

  const _CircularLevelRing({
    required this.progress,
    required this.l10n,
  });

  static const _size = 132.0;
  static const _stroke = 5.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = progress.level;
    final badgeAsset = PlayerLevelBadge.assetForLevel(level);
    final badgeName = l10n.playerLevelBadgeName(level);

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: _size,
            height: _size,
            child: CircularProgressIndicator(
              value: progress.progressFraction,
              strokeWidth: _stroke,
              backgroundColor: AppColors.border,
              color: AppColors.orange,
              strokeCap: StrokeCap.round,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(_stroke + 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: badgeAsset != null
                      ? Image.asset(
                          badgeAsset,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.military_tech,
                            color: AppColors.orange,
                            size: 32,
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.military_tech, color: AppColors.orange, size: 28),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  badgeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
                Text(
                  l10n.playerLevelTitle(level),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
