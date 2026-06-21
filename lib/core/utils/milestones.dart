import '../../models/body_metric.dart';
import '../../models/exercise_logging.dart';
import '../../models/profile.dart';
import '../../models/workout.dart';
import 'supabase_datetime.dart';
import 'workout_calorie_estimator.dart';
import 'workout_day_utils.dart';

enum MilestoneCategory {
  reps,
  volume,
  distance,
  calories,
  workouts,
}

class MilestoneDefinition {
  final int tier;
  final double threshold;

  const MilestoneDefinition({
    required this.tier,
    required this.threshold,
  });
}

class MilestoneEntry {
  final MilestoneDefinition definition;
  final bool unlocked;

  const MilestoneEntry({required this.definition, required this.unlocked});
}

class MilestoneUnlock {
  final MilestoneCategory category;
  final int tier;

  const MilestoneUnlock({
    required this.category,
    required this.tier,
  });
}

class MilestoneTotals {
  final int totalReps;
  final double totalVolumeKg;
  final double totalDistanceMeters;
  final int totalCalories;
  final int totalWorkouts;

  const MilestoneTotals({
    required this.totalReps,
    required this.totalVolumeKg,
    required this.totalDistanceMeters,
    required this.totalCalories,
    required this.totalWorkouts,
  });

  static const empty = MilestoneTotals(
    totalReps: 0,
    totalVolumeKg: 0,
    totalDistanceMeters: 0,
    totalCalories: 0,
    totalWorkouts: 0,
  );

  double valueFor(MilestoneCategory category) {
    return switch (category) {
      MilestoneCategory.reps => totalReps.toDouble(),
      MilestoneCategory.volume => totalVolumeKg,
      MilestoneCategory.distance => totalDistanceMeters,
      MilestoneCategory.calories => totalCalories.toDouble(),
      MilestoneCategory.workouts => totalWorkouts.toDouble(),
    };
  }
}

abstract final class MilestonesCalculator {
  static const _definitions = {
    MilestoneCategory.workouts: [
      MilestoneDefinition(tier: 1, threshold: 1),
      MilestoneDefinition(tier: 2, threshold: 5),
      MilestoneDefinition(tier: 3, threshold: 10),
      MilestoneDefinition(tier: 4, threshold: 25),
      MilestoneDefinition(tier: 5, threshold: 50),
      MilestoneDefinition(tier: 6, threshold: 100),
      MilestoneDefinition(tier: 7, threshold: 250),
      MilestoneDefinition(tier: 8, threshold: 500),
    ],
    MilestoneCategory.reps: [
      MilestoneDefinition(tier: 1, threshold: 500),
      MilestoneDefinition(tier: 2, threshold: 2500),
      MilestoneDefinition(tier: 3, threshold: 5000),
      MilestoneDefinition(tier: 4, threshold: 25000),
      MilestoneDefinition(tier: 5, threshold: 50000),
      MilestoneDefinition(tier: 6, threshold: 125000),
      MilestoneDefinition(tier: 7, threshold: 250000),
      MilestoneDefinition(tier: 8, threshold: 500000),
    ],
    MilestoneCategory.volume: [
      MilestoneDefinition(tier: 1, threshold: 20000),
      MilestoneDefinition(tier: 2, threshold: 100000),
      MilestoneDefinition(tier: 3, threshold: 200000),
      MilestoneDefinition(tier: 4, threshold: 500000),
      MilestoneDefinition(tier: 5, threshold: 1000000),
      MilestoneDefinition(tier: 6, threshold: 2000000),
      MilestoneDefinition(tier: 7, threshold: 5000000),
      MilestoneDefinition(tier: 8, threshold: 10000000),
    ],
    MilestoneCategory.distance: [
      MilestoneDefinition(tier: 1, threshold: 5000),
      MilestoneDefinition(tier: 2, threshold: 25000),
      MilestoneDefinition(tier: 3, threshold: 50000),
      MilestoneDefinition(tier: 4, threshold: 250000),
      MilestoneDefinition(tier: 5, threshold: 500000),
      MilestoneDefinition(tier: 6, threshold: 1250000),
      MilestoneDefinition(tier: 7, threshold: 2500000),
      MilestoneDefinition(tier: 8, threshold: 5000000),
    ],
    MilestoneCategory.calories: [
      MilestoneDefinition(tier: 1, threshold: 1500),
      MilestoneDefinition(tier: 2, threshold: 7500),
      MilestoneDefinition(tier: 3, threshold: 15000),
      MilestoneDefinition(tier: 4, threshold: 30000),
      MilestoneDefinition(tier: 5, threshold: 75000),
      MilestoneDefinition(tier: 6, threshold: 150000),
      MilestoneDefinition(tier: 7, threshold: 300000),
      MilestoneDefinition(tier: 8, threshold: 750000),
    ],
  };

  static List<MilestoneDefinition> definitionsFor(MilestoneCategory category) {
    return _definitions[category] ?? const [];
  }

  static MilestoneTotals computeTotals(
    List<Workout> workouts, {
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
  }) {
    final completed = workouts.where((w) => w.completedAt != null);
    var reps = 0;
    var distanceMeters = 0.0;
    var volumeKg = 0.0;
    var calories = 0;

    for (final workout in completed) {
      volumeKg += workout.totalVolume;
      final estimate = WorkoutCalorieEstimator.estimateFromSummary(
        durationMinutes: workout.durationMinutes,
        totalVolumeKg: workout.totalVolume,
        profile: profile,
        bodyMetrics: bodyMetrics,
      );
      calories += estimate.caloriesKcal ?? 0;

      for (final exercise in workout.exercises) {
        for (final set in exercise.sets) {
          if (!set.completed) continue;
          if (set.loggingType == ExerciseLoggingType.strength) {
            reps += set.reps;
          } else if (set.distanceMeters != null && set.distanceMeters! > 0) {
            distanceMeters += set.distanceMeters!;
          }
        }
      }
    }

    return MilestoneTotals(
      totalReps: reps,
      totalVolumeKg: volumeKg,
      totalDistanceMeters: distanceMeters,
      totalCalories: calories,
      totalWorkouts: WorkoutDayUtils.uniqueDayCountFromWorkouts(completed),
    );
  }

  /// Totales agregados del RPC `get_friend_milestone_data`.
  static MilestoneTotals fromFriendData(
    Map<String, dynamic> data, {
    UserProfile? profile,
  }) {
    final workoutsRaw = data['workouts'];
    final workoutRows = workoutsRaw is List ? workoutsRaw : const [];
    var volumeKg = 0.0;
    var calories = 0;

    for (final row in workoutRows) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      final duration = map['duration_minutes'] as int? ?? 0;
      final volume = (map['total_volume'] as num?)?.toDouble() ?? 0;
      volumeKg += volume;
      final estimate = WorkoutCalorieEstimator.estimateFromSummary(
        durationMinutes: duration,
        totalVolumeKg: volume,
        profile: profile,
      );
      calories += estimate.caloriesKcal ?? 0;
    }

    return MilestoneTotals(
      totalReps: (data['total_reps'] as num?)?.toInt() ?? 0,
      totalVolumeKg: volumeKg,
      totalDistanceMeters: (data['total_distance_meters'] as num?)?.toDouble() ?? 0,
      totalCalories: calories,
      totalWorkouts: _uniqueWorkoutDaysFromRows(workoutRows),
    );
  }

  static int _uniqueWorkoutDaysFromRows(List workoutRows) {
    final days = <DateTime>{};
    var hasCompletedAt = false;

    for (final row in workoutRows) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      final raw = map['completed_at'];
      if (raw == null) continue;

      hasCompletedAt = true;
      final parsed = raw is String
          ? SupabaseDateTime.parse(raw)
          : raw is DateTime
              ? raw
              : null;
      if (parsed != null) {
        days.add(WorkoutDayUtils.localDay(parsed));
      }
    }

    if (hasCompletedAt) return days.length;
    return workoutRows.length;
  }

  static List<MilestoneUnlock> newlyUnlocked(MilestoneTotals before, MilestoneTotals after) {
    final unlocks = <MilestoneUnlock>[];
    for (final category in MilestoneCategory.values) {
      final tierBefore = currentTier(category, before);
      final tierAfter = currentTier(category, after);
      if (tierAfter <= tierBefore) continue;
      for (var tier = tierBefore + 1; tier <= tierAfter; tier++) {
        unlocks.add(MilestoneUnlock(category: category, tier: tier));
      }
    }
    return unlocks;
  }

  static List<MilestoneEntry> entriesFor(MilestoneCategory category, MilestoneTotals totals) {
    final current = totals.valueFor(category);
    return definitionsFor(category)
        .map(
          (def) => MilestoneEntry(
            definition: def,
            unlocked: current >= def.threshold,
          ),
        )
        .toList();
  }

  static int unlockedCount(MilestoneCategory category, MilestoneTotals totals) {
    return entriesFor(category, totals).where((e) => e.unlocked).length;
  }

  /// Progreso hacia el siguiente hito (0–1). Null si ya desbloqueó todos.
  static double? nextProgress(MilestoneCategory category, MilestoneTotals totals) {
    final current = totals.valueFor(category);
    final defs = definitionsFor(category);
    for (final def in defs) {
      if (current < def.threshold) {
        final prevThreshold = def.tier == 1 ? 0.0 : defs[def.tier - 2].threshold;
        final span = def.threshold - prevThreshold;
        if (span <= 0) return 0;
        return ((current - prevThreshold) / span).clamp(0.0, 1.0);
      }
    }
    return null;
  }

  static MilestoneDefinition? nextDefinition(MilestoneCategory category, MilestoneTotals totals) {
    final current = totals.valueFor(category);
    for (final def in definitionsFor(category)) {
      if (current < def.threshold) return def;
    }
    return null;
  }

  /// Tier más alto desbloqueado (0 si ninguno).
  static int currentTier(MilestoneCategory category, MilestoneTotals totals) {
    var tier = 0;
    for (final entry in entriesFor(category, totals)) {
      if (entry.unlocked) tier = entry.definition.tier;
    }
    return tier;
  }

  /// Tier a mostrar en la UI (actual o 1 si aún no hay ninguno).
  static int displayTier(MilestoneCategory category, MilestoneTotals totals) {
    final tier = currentTier(category, totals);
    return tier > 0 ? tier : 1;
  }

  static bool hasUnlockedTier(MilestoneCategory category, MilestoneTotals totals) {
    return currentTier(category, totals) > 0;
  }

  /// Cuánto falta para la siguiente meta. Null si ya desbloqueó todas.
  static double? remainingToNext(MilestoneCategory category, MilestoneTotals totals) {
    final next = nextDefinition(category, totals);
    if (next == null) return null;
    return (next.threshold - totals.valueFor(category)).clamp(0, double.infinity);
  }
}
