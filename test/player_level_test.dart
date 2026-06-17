import 'package:fitforge/core/utils/player_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('xpRequiredToAdvance', () {
    test('levels 1-10 cost 100 XP each', () {
      for (var level = 1; level <= 10; level++) {
        expect(PlayerLevelCalculator.xpRequiredToAdvance(level), 100);
      }
    });

    test('levels 11-20 cost 110 XP each', () {
      for (var level = 11; level <= 20; level++) {
        expect(PlayerLevelCalculator.xpRequiredToAdvance(level), 110);
      }
    });

    test('levels 21-30 cost 120 XP each', () {
      for (var level = 21; level <= 30; level++) {
        expect(PlayerLevelCalculator.xpRequiredToAdvance(level), 120);
      }
    });
  });

  group('fromTotalXp', () {
    test('starts at level 1 with zero XP', () {
      final p = PlayerLevelCalculator.fromTotalXp(0);
      expect(p.level, 1);
      expect(p.xpInCurrentLevel, 0);
      expect(p.xpToNextLevel, 100);
    });

    test('reaches level 2 at 100 XP', () {
      final p = PlayerLevelCalculator.fromTotalXp(100);
      expect(p.level, 2);
      expect(p.xpInCurrentLevel, 0);
      expect(p.xpToNextLevel, 100);
    });

    test('reaches level 11 at 1000 XP', () {
      final p = PlayerLevelCalculator.fromTotalXp(1000);
      expect(p.level, 11);
      expect(p.xpInCurrentLevel, 0);
      expect(p.xpToNextLevel, 110);
    });
  });

  group('streakMultiplier', () {
    test('scales with weeks up to 1.99', () {
      expect(PlayerLevelCalculator.streakMultiplier(0), 1.0);
      expect(PlayerLevelCalculator.streakMultiplier(3), closeTo(1.03, 0.001));
      expect(PlayerLevelCalculator.streakMultiplier(7), closeTo(1.07, 0.001));
      expect(PlayerLevelCalculator.streakMultiplier(24), closeTo(1.24, 0.001));
      expect(PlayerLevelCalculator.streakMultiplier(99), closeTo(1.99, 0.001));
      expect(PlayerLevelCalculator.streakMultiplier(150), closeTo(1.99, 0.001));
    });
  });

  group('xpFromWorkoutVolume', () {
    test('awards 5 XP per 1000 lb without streak', () {
      // 1000 lb ≈ 453.592 kg
      final xp = PlayerLevelCalculator.xpFromWorkoutVolume(
        volumeKg: 453.592,
        streakWeeks: 0,
      );
      expect(xp, 5);
    });

    test('applies streak multiplier', () {
      const volumeKg = 4535.92; // ~10 000 lb → 50 XP base
      final base = PlayerLevelCalculator.xpFromWorkoutVolume(
        volumeKg: volumeKg,
        streakWeeks: 0,
      );
      final boosted = PlayerLevelCalculator.xpFromWorkoutVolume(
        volumeKg: volumeKg,
        streakWeeks: 10,
      );
      expect(base, 50);
      expect(boosted, 55);
    });
  });
}
