import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/milestone_badge.dart';
import '../../core/utils/milestones.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../milestones_section.dart';
import '../../core/theme/app_accent.dart';

class ProgressMilestonesCarousel extends StatelessWidget {
  final MilestoneTotals totals;
  final AppLocalizations l10n;
  final String unitSystem;

  const ProgressMilestonesCarousel({
    super.key,
    required this.totals,
    required this.l10n,
    required this.unitSystem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.milestonesTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: MilestoneCategory.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = MilestoneCategory.values[index];
              return _MilestoneCard(
                category: category,
                totals: totals,
                l10n: l10n,
                unitSystem: unitSystem,
              )
                  .animate()
                  .fadeIn(delay: (40 * index).ms, duration: 300.ms)
                  .slideX(begin: 0.04, end: 0, delay: (40 * index).ms, duration: 300.ms);
            },
          ),
        ),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final MilestoneCategory category;
  final MilestoneTotals totals;
  final AppLocalizations l10n;
  final String unitSystem;

  const _MilestoneCard({
    required this.category,
    required this.totals,
    required this.l10n,
    required this.unitSystem,
  });

  @override
  Widget build(BuildContext context) {
    final tier = MilestonesCalculator.displayTier(category, totals);
    final unlocked = MilestonesCalculator.hasUnlockedTier(category, totals);
    final progress = MilestonesCalculator.nextProgress(category, totals);
    final currentLabel = MilestonesSection.formatValue(
      category,
      totals.valueFor(category),
      l10n,
      unitSystem,
    );
    final next = MilestonesCalculator.nextDefinition(category, totals);
    final tierName = l10n.milestoneTierName(tier);

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => MilestonesSection.showCategoryDetail(
          context,
          category: category,
          totals: totals,
          l10n: l10n,
          unitSystem: unitSystem,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 132,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    MilestoneBadge.assetPathForTier(tier),
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    opacity: unlocked ? AlwaysStoppedAnimation(1) : const AlwaysStoppedAnimation(0.35),
                    errorBuilder: (_, __, ___) => Icon(
                      unlocked ? Icons.emoji_events : Icons.lock_outline,
                      color: unlocked ? context.accentColor : AppColors.textMuted,
                      size: 24,
                    ),
                  ),
                  Spacer(),
                  Text(
                    tierName,
                    style: TextStyle(
                      color: unlocked ? context.accentColor : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                MilestonesSection.categoryLabel(l10n, category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                currentLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const Spacer(),
              if (progress != null && next != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppColors.cardElevated,
                    color: context.accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.progressMilestoneNext(
                    MilestonesSection.formatValue(category, next.threshold, l10n, unitSystem),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ] else
                Text(
                  l10n.milestoneAllUnlocked,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.accentColor, fontSize: 10, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
