import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge/core/utils/muscle_inference.dart';

void main() {
  group('MuscleInference.fromExerciseName', () {
    test('chest exercises do not tag back', () {
      expect(MuscleInference.fromExerciseName('Press de banca con barra'), contains('Pecho'));
      expect(MuscleInference.fromExerciseName('Press de banca con barra'), isNot(contains('Espalda')));

      expect(MuscleInference.fromExerciseName('Press inclinado con mancuernas'), contains('Pecho'));
      expect(MuscleInference.fromExerciseName('Press inclinado con mancuernas'), isNot(contains('Espalda')));

      expect(MuscleInference.fromExerciseName('Aperturas con mancuernas (peck deck)'), contains('Pecho'));
      expect(MuscleInference.fromExerciseName('Aperturas con mancuernas (peck deck)'), isNot(contains('Espalda')));

      expect(MuscleInference.fromExerciseName('Barbell bench press'), contains('Pecho'));
      expect(MuscleInference.fromExerciseName('Barbell bench press'), isNot(contains('Espalda')));

      expect(MuscleInference.fromExerciseName('Narrow grip bench press'), contains('Pecho'));
      expect(MuscleInference.fromExerciseName('Narrow grip bench press'), isNot(contains('Espalda')));
    });

    test('lateral raises do not tag back via lat substring', () {
      expect(MuscleInference.fromExerciseName('Elevaciones laterales con mancuernas'), contains('Hombros'));
      expect(MuscleInference.fromExerciseName('Elevaciones laterales con mancuernas'), isNot(contains('Espalda')));
    });

    test('back squat tags legs not back', () {
      expect(MuscleInference.fromExerciseName('Sentadilla con barra (back squat)'), contains('Piernas'));
      expect(MuscleInference.fromExerciseName('Sentadilla con barra (back squat)'), isNot(contains('Espalda')));
    });

    test('lat pulldown tags back not chest', () {
      expect(MuscleInference.fromExerciseName('Jalón al pecho (polea)'), contains('Espalda'));
      expect(MuscleInference.fromExerciseName('Jalón al pecho (polea)'), isNot(contains('Pecho')));
    });

    test('true back exercises still tag back', () {
      expect(MuscleInference.fromExerciseName('Remo con barra'), contains('Espalda'));
      expect(MuscleInference.fromExerciseName('Dominadas'), contains('Espalda'));
    });
  });

  group('MuscleInference.resolve with supplemental catalog', () {
    test('uses catalog muscles for supplemental bench press', () {
      final muscles = MuscleInference.resolve(
        exerciseName: 'Press de banca con barra',
        exerciseId: '-1001',
      );
      expect(muscles, contains('Pecho'));
      expect(muscles, isNot(contains('Espalda')));
    });
  });
}
