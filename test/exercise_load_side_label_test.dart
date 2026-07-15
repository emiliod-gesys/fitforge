import 'package:fitforge/core/utils/exercise_load.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:fitforge/models/exercise_logging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseLoad.isLowerBodySideLoad', () {
    test('detects leg machines by name', () {
      expect(
        ExerciseLoad.isLowerBodySideLoad(exerciseName: 'Prensa de piernas'),
        isTrue,
      );
      expect(
        ExerciseLoad.isLowerBodySideLoad(exerciseName: 'Extensión de cuádriceps'),
        isTrue,
      );
      expect(
        ExerciseLoad.isLowerBodySideLoad(exerciseName: 'Leg curl'),
        isTrue,
      );
    });

    test('does not flag arm exercises', () {
      expect(
        ExerciseLoad.isLowerBodySideLoad(exerciseName: 'Curl de bíceps con mancuernas'),
        isFalse,
      );
      expect(
        ExerciseLoad.isLowerBodySideLoad(exerciseName: 'Press militar'),
        isFalse,
      );
    });

    test('uses category from catalog exercise', () {
      const legs = Exercise(
        name: 'Máquina desconocida',
        category: 'Piernas',
        loadMode: ExerciseLoadMode.machineStack,
        isBundled: true,
      );
      expect(
        ExerciseLoad.isLowerBodySideLoad(
          exerciseName: legs.name,
          exercise: legs,
        ),
        isTrue,
      );
    });

    test('weightLabel picks leg suffix when requested', () {
      expect(
        ExerciseLoad.weightLabel(
          'kg',
          'Prensa',
          perArmWeight: true,
          useLegLabel: true,
          perLegSuffix: '(por pierna)',
        ),
        'kg (por pierna)',
      );
      expect(
        ExerciseLoad.weightLabel(
          'kg',
          'Curl',
          perArmWeight: true,
          useLegLabel: false,
        ),
        'kg (por brazo)',
      );
    });
  });
}
