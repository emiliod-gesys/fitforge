import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/leaderboard.dart';
import 'cardio_format.dart';
import 'milestones.dart';
import 'player_level.dart';
import 'unit_converter.dart';

abstract final class LeaderboardFormat {
  static String metricLabel(AppLocalizations l10n, LeaderboardMetric metric) {
    return switch (metric) {
      LeaderboardMetric.level => l10n.leaderboardMetricLevel,
      LeaderboardMetric.volume => l10n.milestoneCategoryVolume,
      LeaderboardMetric.workouts => l10n.milestoneCategoryWorkouts,
      LeaderboardMetric.distance => l10n.milestoneCategoryDistance,
      LeaderboardMetric.calories => l10n.milestoneCategoryCalories,
      LeaderboardMetric.reps => l10n.milestoneCategoryReps,
    };
  }

  static String periodLabel(AppLocalizations l10n, LeaderboardPeriod period) {
    return switch (period) {
      LeaderboardPeriod.week => l10n.leaderboardPeriodWeek,
      LeaderboardPeriod.month => l10n.leaderboardPeriodMonth,
      LeaderboardPeriod.all => l10n.leaderboardPeriodAll,
    };
  }

  static String valueLabel(
    AppLocalizations l10n,
    LeaderboardMetric metric,
    LeaderboardEntry entry, {
    required String unitSystem,
    LeaderboardPeriod period = LeaderboardPeriod.all,
  }) {
    return switch (metric) {
      LeaderboardMetric.level => period == LeaderboardPeriod.all
          ? l10n.playerLevelRankSummary(
              PlayerLevelCalculator.fromTotalXp(entry.totalXp).level,
            )
          : l10n.leaderboardPeriodXp(entry.metricValue.round()),
      LeaderboardMetric.volume => UnitConverter.formatVolume(entry.totalVolume, unitSystem),
      LeaderboardMetric.workouts => _formatCount(entry.totalWorkouts.toDouble()),
      LeaderboardMetric.distance => CardioFormat.distance(entry.totalDistance, unitSystem),
      LeaderboardMetric.calories => l10n.caloriesKcal(entry.totalCalories),
      LeaderboardMetric.reps => _formatCount(entry.totalReps.toDouble()),
    };
  }

  static String _formatCount(double value) {
    final n = value.round();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k';
    return '$n';
  }

  static MilestoneCategory? milestoneCategoryFor(LeaderboardMetric metric) {
    return switch (metric) {
      LeaderboardMetric.level => null,
      LeaderboardMetric.volume => MilestoneCategory.volume,
      LeaderboardMetric.workouts => MilestoneCategory.workouts,
      LeaderboardMetric.distance => MilestoneCategory.distance,
      LeaderboardMetric.calories => MilestoneCategory.calories,
      LeaderboardMetric.reps => MilestoneCategory.reps,
    };
  }

  static MilestoneTotals totalsFor(LeaderboardEntry entry) {
    return MilestoneTotals(
      totalReps: entry.totalReps,
      totalVolumeKg: entry.totalVolume,
      totalDistanceMeters: entry.totalDistance,
      totalCalories: entry.totalCalories,
      totalWorkouts: entry.totalWorkouts,
    );
  }
}
