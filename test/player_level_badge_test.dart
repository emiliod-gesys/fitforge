import 'package:fitforge/core/utils/player_level_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assetForLevel usa medallita 1-9 en ese rango', () {
    expect(
      PlayerLevelBadge.assetForLevel(1),
      'assets/images/player_levels/transparent/level_1_9.png',
    );
    expect(
      PlayerLevelBadge.assetForLevel(9),
      'assets/images/player_levels/transparent/level_1_9.png',
    );
    expect(PlayerLevelBadge.assetForLevel(10), 'assets/images/player_levels/transparent/level_10_24.png');
    expect(PlayerLevelBadge.assetForLevel(24), 'assets/images/player_levels/transparent/level_10_24.png');
    expect(PlayerLevelBadge.assetForLevel(25), 'assets/images/player_levels/transparent/level_25_49.png');
    expect(PlayerLevelBadge.assetForLevel(49), 'assets/images/player_levels/transparent/level_25_49.png');
    expect(PlayerLevelBadge.assetForLevel(50), 'assets/images/player_levels/transparent/level_50_74.png');
    expect(PlayerLevelBadge.assetForLevel(74), 'assets/images/player_levels/transparent/level_50_74.png');
    expect(PlayerLevelBadge.assetForLevel(75), 'assets/images/player_levels/transparent/level_75_99.png');
    expect(PlayerLevelBadge.assetForLevel(99), 'assets/images/player_levels/transparent/level_75_99.png');
    expect(PlayerLevelBadge.assetForLevel(100), 'assets/images/player_levels/transparent/level_100_149.png');
    expect(PlayerLevelBadge.assetForLevel(149), 'assets/images/player_levels/transparent/level_100_149.png');
    expect(PlayerLevelBadge.assetForLevel(150), 'assets/images/player_levels/transparent/level_150_199.png');
    expect(PlayerLevelBadge.assetForLevel(199), 'assets/images/player_levels/transparent/level_150_199.png');
    expect(PlayerLevelBadge.assetForLevel(200), 'assets/images/player_levels/transparent/level_200_299.png');
    expect(PlayerLevelBadge.assetForLevel(299), 'assets/images/player_levels/transparent/level_200_299.png');
    expect(PlayerLevelBadge.assetForLevel(300), 'assets/images/player_levels/transparent/level_300_499.png');
    expect(PlayerLevelBadge.assetForLevel(499), 'assets/images/player_levels/transparent/level_300_499.png');
    expect(PlayerLevelBadge.assetForLevel(500), 'assets/images/player_levels/transparent/level_500_plus.png');
    expect(PlayerLevelBadge.assetForLevel(10000), 'assets/images/player_levels/transparent/level_500_plus.png');
  });

  test('tierIncreased solo al cambiar emblema', () {
    expect(PlayerLevelBadge.tierIncreased(8, 9), isFalse);
    expect(PlayerLevelBadge.tierIncreased(9, 10), isTrue);
    expect(PlayerLevelBadge.tierIncreased(24, 25), isTrue);
    expect(PlayerLevelBadge.tierIncreased(25, 26), isFalse);
    expect(PlayerLevelBadge.tierIncreased(499, 500), isTrue);
  });
}
