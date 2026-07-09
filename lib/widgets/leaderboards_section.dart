import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/leaderboard_format.dart';
import '../../core/utils/milestone_badge.dart';
import '../../core/utils/milestones.dart';
import '../../core/utils/player_level_badge.dart';
import '../../l10n/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../models/leaderboard.dart';
import '../../providers/app_providers.dart';
import 'profile_avatar.dart';
import 'social/social_filter_chip.dart';
import 'fitforge_loading_indicator.dart';
import 'tappable_badge.dart';
import '../core/theme/app_accent.dart';

class LeaderboardsSection extends ConsumerStatefulWidget {
  const LeaderboardsSection({super.key});

  @override
  ConsumerState<LeaderboardsSection> createState() => _LeaderboardsSectionState();
}

class _LeaderboardsSectionState extends ConsumerState<LeaderboardsSection> {
  LeaderboardScope _scope = LeaderboardScope.friends;
  LeaderboardMetric _metric = LeaderboardMetric.level;
  LeaderboardPeriod _period = LeaderboardPeriod.all;
  int _limit = LeaderboardPagination.pageSize;

  LeaderboardKey get _key => (
        scope: _scope,
        metric: _metric,
        period: _period,
        limit: _limit,
      );

  void _updateFilters(void Function() update) {
    setState(() {
      update();
      _limit = LeaderboardPagination.pageSize;
    });
  }

  Color _rankColor(int rank) {
    return switch (rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => AppColors.textMuted,
    };
  }

  Future<void> _onRefresh() async {
    ref.invalidate(leaderboardProvider(_key));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unitSystem = ref.watch(unitSystemProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider(_key));

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                SocialFilterChip(
                  label: l10n.leaderboardScopeFriends,
                  selected: _scope == LeaderboardScope.friends,
                  onTap: () => _updateFilters(() => _scope = LeaderboardScope.friends),
                ),
                SocialFilterChip(
                  label: l10n.leaderboardScopeGlobal,
                  selected: _scope == LeaderboardScope.global,
                  onTap: () => _updateFilters(() => _scope = LeaderboardScope.global),
                ),
                const SizedBox(width: 4),
                Container(width: 1, height: 22, color: AppColors.border),
                const SizedBox(width: 4),
                SocialFilterChip(
                  label: l10n.leaderboardPeriodWeek,
                  selected: _period == LeaderboardPeriod.week,
                  onTap: () => _updateFilters(() => _period = LeaderboardPeriod.week),
                ),
                SocialFilterChip(
                  label: l10n.leaderboardPeriodMonth,
                  selected: _period == LeaderboardPeriod.month,
                  onTap: () => _updateFilters(() => _period = LeaderboardPeriod.month),
                ),
                SocialFilterChip(
                  label: l10n.leaderboardPeriodAll,
                  selected: _period == LeaderboardPeriod.all,
                  onTap: () => _updateFilters(() => _period = LeaderboardPeriod.all),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: LeaderboardMetric.values.map((metric) {
                return SocialFilterChip(
                  label: LeaderboardFormat.metricLabel(l10n, metric),
                  selected: _metric == metric,
                  onTap: () => _updateFilters(() => _metric = metric),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          leaderboardAsync.when(
            skipLoadingOnReload: true,
            loading: () => const _LeaderboardSkeleton(),
            error: (e, _) => Text(l10n.errorGeneric('$e')),
            data: (result) => _LeaderboardList(
              result: result,
              metric: _metric,
              period: _period,
              l10n: l10n,
              unitSystem: unitSystem,
              rankColorFor: _rankColor,
              isLoadingMore: leaderboardAsync.isLoading && _limit > LeaderboardPagination.pageSize,
              onLoadMore: result.hasMore
                  ? () => setState(() => _limit += LeaderboardPagination.pageSize)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final LeaderboardResult result;
  final LeaderboardMetric metric;
  final LeaderboardPeriod period;
  final AppLocalizations l10n;
  final String unitSystem;
  final Color Function(int rank) rankColorFor;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  const _LeaderboardList({
    required this.result,
    required this.metric,
    required this.period,
    required this.l10n,
    required this.unitSystem,
    required this.rankColorFor,
    required this.isLoadingMore,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (result.entries.isEmpty && result.currentUserOutsideTop == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          l10n.leaderboardEmpty,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return Column(
      children: [
        for (final entry in result.entries)
          _LeaderboardTile(
            entry: entry,
            metric: metric,
            period: period,
            l10n: l10n,
            unitSystem: unitSystem,
            rankColor: rankColorFor(entry.rank),
            onTap: entry.isCurrentUser
                ? null
                : () => context.push('/social/friend/${entry.userId}'),
          ),
        if (result.currentUserOutsideTop != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.leaderboardYourPosition,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 8),
          _LeaderboardTile(
            entry: result.currentUserOutsideTop!,
            metric: metric,
            period: period,
            l10n: l10n,
            unitSystem: unitSystem,
            rankColor: context.accentColor,
            onTap: null,
          ),
        ],
        if (onLoadMore != null) ...[
          SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isLoadingMore ? null : onLoadMore,
              style: OutlinedButton.styleFrom(
                foregroundColor: context.accentColor,
                side: BorderSide(color: context.accentColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: isLoadingMore
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: FitForgeLoadingIndicator(size: 20),
                    )
                  : Text(l10n.leaderboardLoadMore),
            ),
          ),
        ],
      ],
    );
  }
}

class _LeaderboardSkeleton extends StatelessWidget {
  const _LeaderboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardElevated,
      highlightColor: AppColors.card,
      child: Column(
        children: List.generate(
          5,
          (index) => Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
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
    final subtitle = metric == LeaderboardMetric.level
        ? valueLabel
        : '${LeaderboardFormat.metricLabel(l10n, metric)} · $valueLabel';
    final badgeAsset = _badgeAsset(period);
    final badgeLabel = _badgeLabel(period);
    final isTopThree = entry.rank <= 3;

    return Card(
      color: entry.isCurrentUser
          ? context.accentColor.withValues(alpha: 0.08)
          : isTopThree
              ? rankColor.withValues(alpha: 0.06)
              : AppColors.card,
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: entry.isCurrentUser
              ? context.accentColor.withValues(alpha: 0.28)
              : isTopThree
                  ? rankColor.withValues(alpha: 0.22)
                  : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isTopThree ? 16 : 14,
                    color: rankColor,
                  ),
                ),
              ),
              ProfileAvatar(
                avatarUrl: entry.avatarUrl,
                radius: 20,
                fallbackLetter: entry.label,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: entry.isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                        color: entry.isCurrentUser ? context.accentColor : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) => const SizedBox(width: 40, height: 40),
                  ),
                ),
            ],
          ),
        ),
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
