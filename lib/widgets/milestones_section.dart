import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/cardio_format.dart';
import '../core/utils/milestone_badge.dart';
import '../core/utils/milestones.dart';
import '../core/utils/unit_converter.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';

class MilestonesSection extends StatelessWidget {
  final MilestoneTotals totals;
  final AppLocalizations l10n;
  final String unitSystem;

  const MilestonesSection({
    super.key,
    required this.totals,
    required this.l10n,
    required this.unitSystem,
  });

  static String categoryLabel(AppLocalizations l10n, MilestoneCategory category) {
    return switch (category) {
      MilestoneCategory.reps => l10n.milestoneCategoryReps,
      MilestoneCategory.volume => l10n.milestoneCategoryVolume,
      MilestoneCategory.distance => l10n.milestoneCategoryDistance,
      MilestoneCategory.calories => l10n.milestoneCategoryCalories,
      MilestoneCategory.workouts => l10n.milestoneCategoryWorkouts,
    };
  }

  String _formatValue(MilestoneCategory category, double value) {
    return switch (category) {
      MilestoneCategory.reps => _formatCount(value),
      MilestoneCategory.volume => UnitConverter.formatVolume(value, unitSystem),
      MilestoneCategory.distance => CardioFormat.distance(value, unitSystem),
      MilestoneCategory.calories => l10n.caloriesKcal(value.round()),
      MilestoneCategory.workouts => _formatCount(value),
    };
  }

  String _formatCount(double value) {
    final n = value.round();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k';
    return '$n';
  }

  void _showDetail(BuildContext context, MilestoneCategory category) {
    final current = totals.valueFor(category);
    final next = MilestonesCalculator.nextDefinition(category, totals);
    final remaining = MilestonesCalculator.remainingToNext(category, totals);
    final label = categoryLabel(l10n, category);
    final displayTier = MilestonesCalculator.displayTier(category, totals);
    final tierName = l10n.milestoneTierName(displayTier);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _MilestoneBadgeImage(
                assetPath: MilestoneBadge.assetPathForTier(displayTier),
                unlocked: MilestonesCalculator.hasUnlockedTier(category, totals),
                size: 72,
              ),
              const SizedBox(height: 8),
              Text(
                tierName,
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.milestoneTotal(_formatValue(category, current)),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
              ),
              if (next != null && remaining != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.milestoneNextTarget(_formatValue(category, next.threshold)),
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.milestoneDetailRemaining(
                    _formatValue(category, remaining),
                    _formatValue(category, next.threshold),
                  ),
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  l10n.milestoneAllUnlocked,
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.milestonesTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: MilestoneCategory.values.map((category) {
            final tier = MilestonesCalculator.displayTier(category, totals);
            final unlocked = MilestonesCalculator.hasUnlockedTier(category, totals);
            final currentLabel = _formatValue(category, totals.valueFor(category));

            return Expanded(
              child: InkWell(
                onTap: () => _showDetail(context, category),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _MilestoneBadgeImage(
                              assetPath: MilestoneBadge.assetPathForTier(tier),
                              unlocked: unlocked,
                            ),
                            if (!unlocked)
                              const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        categoryLabel(l10n, category),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentLabel,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MilestoneBadgeImage extends StatelessWidget {
  final String assetPath;
  final bool unlocked;
  final double size;

  const _MilestoneBadgeImage({
    required this.assetPath,
    required this.unlocked,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      opacity: unlocked ? const AlwaysStoppedAnimation(1) : const AlwaysStoppedAnimation(0.35),
      errorBuilder: (_, __, ___) => Icon(
        unlocked ? Icons.emoji_events : Icons.lock_outline,
        color: unlocked ? AppColors.orange : AppColors.textMuted,
        size: size * 0.55,
      ),
    );
  }
}
