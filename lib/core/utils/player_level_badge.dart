import 'player_level.dart';

/// Medallas de nivel del jugador. Añade entradas conforme se suban nuevas imágenes.
abstract final class PlayerLevelBadge {
  static const _tiers = <_LevelBadgeTier>[
    _LevelBadgeTier(minLevel: 1, maxLevel: 9, assetPath: 'assets/images/player_levels/transparent/level_1_9.png'),
    _LevelBadgeTier(minLevel: 10, maxLevel: 24, assetPath: 'assets/images/player_levels/transparent/level_10_24.png'),
    _LevelBadgeTier(minLevel: 25, maxLevel: 49, assetPath: 'assets/images/player_levels/transparent/level_25_49.png'),
    _LevelBadgeTier(minLevel: 50, maxLevel: 74, assetPath: 'assets/images/player_levels/transparent/level_50_74.png'),
    _LevelBadgeTier(minLevel: 75, maxLevel: 99, assetPath: 'assets/images/player_levels/transparent/level_75_99.png'),
    _LevelBadgeTier(minLevel: 100, maxLevel: 149, assetPath: 'assets/images/player_levels/transparent/level_100_149.png'),
    _LevelBadgeTier(minLevel: 150, maxLevel: 199, assetPath: 'assets/images/player_levels/transparent/level_150_199.png'),
    _LevelBadgeTier(minLevel: 200, maxLevel: 299, assetPath: 'assets/images/player_levels/transparent/level_200_299.png'),
    _LevelBadgeTier(minLevel: 300, maxLevel: 499, assetPath: 'assets/images/player_levels/transparent/level_300_499.png'),
    _LevelBadgeTier(
      minLevel: 500,
      maxLevel: PlayerLevelCalculator.maxLevel,
      assetPath: 'assets/images/player_levels/transparent/level_500_plus.png',
    ),
  ];

  static String? assetForLevel(int level) {
    final safeLevel = level.clamp(1, PlayerLevelCalculator.maxLevel);
    for (final tier in _tiers) {
      if (safeLevel >= tier.minLevel && safeLevel <= tier.maxLevel) {
        return tier.assetPath;
      }
    }
    return null;
  }
}

class _LevelBadgeTier {
  final int minLevel;
  final int maxLevel;
  final String assetPath;

  const _LevelBadgeTier({
    required this.minLevel,
    required this.maxLevel,
    required this.assetPath,
  });
}
