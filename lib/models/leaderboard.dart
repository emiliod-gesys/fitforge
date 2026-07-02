import '../core/utils/player_level.dart';

enum LeaderboardScope { friends, global }

enum LeaderboardPeriod { week, month, all }

enum LeaderboardMetric {
  level,
  volume,
  workouts,
  distance,
  calories,
  reps,
}

extension LeaderboardMetricApi on LeaderboardMetric {
  String get apiValue => name;
}

extension LeaderboardPeriodApi on LeaderboardPeriod {
  String get apiValue => name;
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final int totalXp;
  final double metricValue;
  final int totalReps;
  final double totalVolume;
  final double totalDistance;
  final int totalCalories;
  final int totalWorkouts;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    this.displayName,
    this.avatarUrl,
    required this.totalXp,
    required this.metricValue,
    required this.totalReps,
    required this.totalVolume,
    required this.totalDistance,
    required this.totalCalories,
    required this.totalWorkouts,
    required this.isCurrentUser,
  });

  String get label => displayName ?? 'Usuario';

  int get level => PlayerLevelCalculator.fromTotalXp(totalXp).level;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      metricValue: (json['metric_value'] as num?)?.toDouble() ?? 0,
      totalReps: (json['total_reps'] as num?)?.toInt() ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0,
      totalDistance: (json['total_distance'] as num?)?.toDouble() ?? 0,
      totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
      totalWorkouts: (json['total_workouts'] as num?)?.toInt() ?? 0,
      isCurrentUser: json['is_current_user'] as bool? ?? false,
    );
  }
}

class LeaderboardResult {
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? currentUserOutsideTop;
  final bool hasMore;

  const LeaderboardResult({
    required this.entries,
    this.currentUserOutsideTop,
    this.hasMore = false,
  });

  factory LeaderboardResult.fromJson(Map<String, dynamic> json) {
    final entriesRaw = json['entries'];
    final entries = entriesRaw is List
        ? entriesRaw
            .map((row) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(row as Map)))
            .toList()
        : <LeaderboardEntry>[];

    final outsideRaw = json['current_user_outside_top'];
    final outside = outsideRaw is Map
        ? LeaderboardEntry.fromJson(Map<String, dynamic>.from(outsideRaw))
        : null;

    return LeaderboardResult(
      entries: entries,
      currentUserOutsideTop: outside,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}

abstract final class LeaderboardPagination {
  static const int pageSize = 50;
  static const int maxLimit = 500;
}

typedef LeaderboardKey = ({
  LeaderboardScope scope,
  LeaderboardMetric metric,
  LeaderboardPeriod period,
  int limit,
});
