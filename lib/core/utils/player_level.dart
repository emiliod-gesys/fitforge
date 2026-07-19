import 'player_level_badge.dart';
import 'unit_converter.dart';

/// Sistema de niveles tipo juego (1–10 000).
abstract final class PlayerLevelCalculator {
  static const maxLevel = 10000;

  /// XP necesaria para pasar de [level] a [level + 1].
  static int xpRequiredToAdvance(int level) {
    if (level < 1 || level >= maxLevel) return 0;
    final group = ((level - 1) ~/ 10) + 1;
    return 90 + 10 * group;
  }

  /// Multiplicador por racha semanal: 1.03 con 3 semanas, máx. 1.99 (99 semanas).
  static double streakMultiplier(int streakWeeks) {
    final weeks = streakWeeks.clamp(0, 99);
    return 1.0 + weeks * 0.01;
  }

  /// 5 XP por cada 1000 lb levantadas, con bonus de racha.
  static int xpFromWorkoutVolume({
    required double volumeKg,
    required int streakWeeks,
  }) {
    if (volumeKg <= 0) return 0;
    final volumeLb = volumeKg * UnitConverter.lbPerKg;
    final baseXp = (volumeLb / 1000) * 5;
    final multiplier = streakMultiplier(streakWeeks);
    return (baseXp * multiplier).round();
  }

  /// ~12 XP por km recorrido (carrera outdoor o cinta), con bonus de racha.
  /// Equivalente aproximado a una sesión de gym moderada (~5 km ≈ 60 XP).
  static const xpPerRunKm = 12;
  static const minRunDistanceForXpMeters = 200.0;
  static const maxRunXpPerWorkout = 360;

  /// Bonus XP for the two built-in runner routines (outdoor + treadmill).
  static const runnerRoutineXpMultiplier = 2.5;

  static int xpFromRunDistance({
    required double distanceMeters,
    required int streakWeeks,
    bool isRunnerRoutine = false,
  }) {
    if (distanceMeters < minRunDistanceForXpMeters) return 0;
    final perKm =
        isRunnerRoutine ? xpPerRunKm * runnerRoutineXpMultiplier : xpPerRunKm.toDouble();
    final maxXp = isRunnerRoutine
        ? (maxRunXpPerWorkout * runnerRoutineXpMultiplier).round()
        : maxRunXpPerWorkout;
    final baseXp = ((distanceMeters / 1000) * perKm).round();
    final capped = baseXp.clamp(0, maxXp);
    final multiplier = streakMultiplier(streakWeeks);
    return (capped * multiplier).round();
  }

  static PlayerLevelProgress fromTotalXp(int totalXp) {
    final safeXp = totalXp < 0 ? 0 : totalXp;
    var level = 1;
    var xpIntoLevel = safeXp;

    while (level < maxLevel) {
      final cost = xpRequiredToAdvance(level);
      if (xpIntoLevel < cost) {
        return PlayerLevelProgress(
          level: level,
          totalXp: safeXp,
          xpInCurrentLevel: xpIntoLevel,
          xpToNextLevel: cost,
        );
      }
      xpIntoLevel -= cost;
      level++;
    }

    return PlayerLevelProgress(
      level: maxLevel,
      totalXp: safeXp,
      xpInCurrentLevel: xpIntoLevel,
      xpToNextLevel: 0,
    );
  }
}

class PlayerLevelProgress {
  final int level;
  final int totalXp;
  final int xpInCurrentLevel;
  final int xpToNextLevel;

  const PlayerLevelProgress({
    required this.level,
    required this.totalXp,
    required this.xpInCurrentLevel,
    required this.xpToNextLevel,
  });

  bool get isMaxLevel => level >= PlayerLevelCalculator.maxLevel;

  double get progressFraction {
    if (isMaxLevel || xpToNextLevel <= 0) return 1;
    return (xpInCurrentLevel / xpToNextLevel).clamp(0.0, 1.0);
  }
}

class XpAwardResult {
  final int xpEarned;
  final int streakWeeks;
  final double streakMultiplier;
  final PlayerLevelProgress before;
  final PlayerLevelProgress after;

  const XpAwardResult({
    required this.xpEarned,
    required this.streakWeeks,
    required this.streakMultiplier,
    required this.before,
    required this.after,
  });

  bool get leveledUp => after.level > before.level;

  /// Subida de rango (emblema + título), no cada nivel numérico.
  bool get rankTierIncreased =>
      PlayerLevelBadge.tierIncreased(before.level, after.level);
}
