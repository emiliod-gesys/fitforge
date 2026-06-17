import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/player_level.dart';
import '../l10n/app_localizations.dart';

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.military_tech, color: AppColors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.playerLevelTitle(progress.level),
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        progress.isMaxLevel
                            ? l10n.playerLevelMax
                            : l10n.playerXpProgress(progress.xpInCurrentLevel, progress.xpToNextLevel),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
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
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.progressFraction,
                minHeight: 10,
                backgroundColor: AppColors.border,
                color: AppColors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
