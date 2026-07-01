import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/leaderboard_format.dart';
import '../core/utils/milestone_badge.dart';
import '../core/utils/milestones.dart';
import '../core/utils/player_level_badge.dart';
import '../l10n/l10n_extensions.dart';
import '../l10n/app_localizations.dart';
import '../models/leaderboard.dart';
import '../providers/app_providers.dart';
import 'fitforge_loading_indicator.dart';
import 'profile_avatar.dart';
import 'tappable_badge.dart';

class LeaderboardsSection extends ConsumerStatefulWidget {
  const LeaderboardsSection({super.key});

  @override
  ConsumerState<LeaderboardsSection> createState() => _LeaderboardsSectionState();
}

class _LeaderboardsSectionState extends ConsumerState<LeaderboardsSection> {
  LeaderboardScope _scope = LeaderboardScope.friends;
  LeaderboardMetric _metric = LeaderboardMetric.level;
  LeaderboardPeriod _period = LeaderboardPeriod.all;

  LeaderboardKey get _key => (scope: _scope, metric: _metric, period: _period);

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
    final l10n = context.l10n;
    final unitSystem = ref.watch(unitSystemProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider(_key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.leaderboardsTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        SegmentedButton<LeaderboardScope>(
          segments: [
            ButtonSegment(value: LeaderboardScope.friends, label: Text(l10n.leaderboardScopeFriends)),
            ButtonSegment(value: LeaderboardScope.global, label: Text(l10n.leaderboardScopeGlobal)),
          ],
          selected: {_scope},
          onSelectionChanged: (selection) => setState(() => _scope = selection.first),
        ),
        const SizedBox(height: 12),
        SegmentedButton<LeaderboardPeriod>(
          segments: [
            ButtonSegment(value: LeaderboardPeriod.week, label: Text(l10n.leaderboardPeriodWeek)),
            ButtonSegment(value: LeaderboardPeriod.month, label: Text(l10n.leaderboardPeriodMonth)),
            ButtonSegment(value: LeaderboardPeriod.all, label: Text(l10n.leaderboardPeriodAll)),
          ],
          selected: {_period},
          onSelectionChanged: (selection) => setState(() => _period = selection.first),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: LeaderboardMetric.values.map((metric) {
              final selected = _metric == metric;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(LeaderboardFormat.metricLabel(l10n, metric)),
                  selected: selected,
                  onSelected: (_) => setState(() => _metric = metric),
                  selectedColor: AppColors.orange.withValues(alpha: 0.25),
                  checkmarkColor: AppColors.orange,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.orange : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        leaderboardAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: FitForgeLoadingIndicator(size: 32)),
          ),
          error: (e, _) => Text(l10n.errorGeneric('$e')),
          data: (result) {
            if (result.entries.isEmpty && result.currentUserOutsideTop == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.leaderboardEmpty,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              );
            }

            return Card(
              color: AppColors.card,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    for (var i = 0; i < result.entries.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 56),
                      _LeaderboardTile(
                        entry: result.entries[i],
                        metric: _metric,
                        period: _period,
                        l10n: l10n,
                        unitSystem: unitSystem,
                        rankColor: _rankColor(result.entries[i].rank),
                        onTap: result.entries[i].isCurrentUser
                            ? null
                            : () => context.push('/social/friend/${result.entries[i].userId}'),
                      ),
                    ],
                    if (result.currentUserOutsideTop != null) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          l10n.leaderboardYourPosition,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _LeaderboardTile(
                        entry: result.currentUserOutsideTop!,
                        metric: _metric,
                        period: _period,
                        l10n: l10n,
                        unitSystem: unitSystem,
                        rankColor: AppColors.orange,
                        onTap: null,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final LeaderboardMetric metric;
  final LeaderboardPeriod period;
  final AppLocalizations l10n;
  final String unitSystem;
  final Color rankColor;
  final VoidCallback? onTap;

  const _LeaderboardTile({
    required this.entry,
    required this.metric,
    required this.period,
    required this.l10n,
    required this.unitSystem,
    required this.rankColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = entry.isCurrentUser ? l10n.rankYou(entry.label) : entry.label;
    final valueLabel = LeaderboardFormat.valueLabel(
      l10n,
      metric,
      entry,
      unitSystem: unitSystem,
      period: period,
    );
    final categoryLabel = LeaderboardFormat.metricLabel(l10n, metric);
    final badgeAsset = _badgeAsset(period);
    final badgeLabel = _badgeLabel(period);

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
            avatarUrl: entry.avatarUrl,
            radius: 16,
            fallbackLetter: entry.label,
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
                  '$categoryLabel · $valueLabel',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (badgeAsset != null)
            TappableBadge(
              label: badgeLabel!,
              child: Image.asset(
                badgeAsset,
                width: 36,
                height: 36,
                errorBuilder: (_, __, ___) => const SizedBox(width: 36, height: 36),
              ),
            ),
        ],
      ),
    );
  }

  String? _badgeAsset(LeaderboardPeriod period) {
    if (metric == LeaderboardMetric.level) {
      return PlayerLevelBadge.assetForLevel(entry.level);
    }

    if (period != LeaderboardPeriod.all) return null;

    final category = LeaderboardFormat.milestoneCategoryFor(metric);
    if (category == null) return null;

    final totals = LeaderboardFormat.totalsFor(entry);
    final tier = MilestonesCalculator.displayTier(category, totals);
    return MilestoneBadge.assetPathForTier(tier);
  }

  String? _badgeLabel(LeaderboardPeriod period) {
    if (metric == LeaderboardMetric.level) {
      return l10n.playerLevelBadgeName(entry.level);
    }

    if (period != LeaderboardPeriod.all) return null;

    final category = LeaderboardFormat.milestoneCategoryFor(metric);
    if (category == null) return null;

    final totals = LeaderboardFormat.totalsFor(entry);
    final tier = MilestonesCalculator.displayTier(category, totals);
    return l10n.milestoneTierName(tier);
  }
}
