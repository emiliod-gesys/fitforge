import 'package:fitforge/core/utils/proactive_workout_ai_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProactiveWorkoutAiRules.warmupSetsAllowed', () {
    test('allows warmups for heavy compounds with history', () {
      expect(
        ProactiveWorkoutAiRules.warmupSetsAllowed(
          isCompound: true,
          isCardio: false,
          recoveryPercent: 80,
          hasWorkingHistory: true,
          fitnessGoal: 'Fuerza',
        ),
        isTrue,
      );
    });

    test('blocks warmups for isolation exercises', () {
      expect(
        ProactiveWorkoutAiRules.warmupSetsAllowed(
          isCompound: false,
          isCardio: false,
          recoveryPercent: 90,
          hasWorkingHistory: true,
          fitnessGoal: 'Hipertrofia',
        ),
        isFalse,
      );
    });

    test('blocks warmups for fat loss goal', () {
      expect(
        ProactiveWorkoutAiRules.warmupSetsAllowed(
          isCompound: true,
          isCardio: false,
          recoveryPercent: 90,
          hasWorkingHistory: true,
          fitnessGoal: 'Pérdida de grasa',
        ),
        isFalse,
      );
    });

    test('blocks warmups when recovery is low', () {
      expect(
        ProactiveWorkoutAiRules.warmupSetsAllowed(
          isCompound: true,
          isCardio: false,
          recoveryPercent: 50,
          hasWorkingHistory: true,
          fitnessGoal: 'Fuerza',
        ),
        isFalse,
      );
    });
  });

  group('ProactiveWorkoutAiRules.weightIncrementBlock', () {
    test('requires whole lb for lb users', () {
      final block = ProactiveWorkoutAiRules.weightIncrementBlock('lb');
      expect(block, contains('ENTEROS'));
      expect(block, contains('unit_system=lb'));
    });

    test('requires half-kg steps for kg users', () {
      final block = ProactiveWorkoutAiRules.weightIncrementBlock('kg');
      expect(block, contains('0.5 kg'));
      expect(block, contains('unit_system=kg'));
    });
  });
}
