import 'package:fitforge/models/exercise.dart';
import 'package:fitforge/models/exercise_logging.dart';
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

    test('chest supported rows tag back not chest', () {
      for (final name in [
        'Chest Supported Dumbbell Row',
        'Chest Supported Row Machine',
        'Remo con mancuernas pecho apoyado',
        'Remo con pecho apoyado en máquina',
      ]) {
        expect(MuscleInference.fromExerciseName(name), contains('Espalda'), reason: name);
        expect(MuscleInference.fromExerciseName(name), isNot(contains('Pecho')), reason: name);
      }
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

  group('MuscleInference.matchesMuscleGroup', () {
    test('hip thrust de wger en piernas aparece en filtro de gluteos', () {
      const exercise = Exercise(
        wgerId: 1234,
        name: 'Hip Thrust con Barra',
        category: 'Piernas',
        muscles: ['Cuádriceps', 'Glúteos'],
      );

      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Glúteos'),
        isTrue,
      );
    });

    test('hip thrust sin metadatos de gluteos se infiere por nombre', () {
      const exercise = Exercise(
        wgerId: 1235,
        name: 'Barbell Hip Thrust',
        category: 'Piernas',
        muscles: ['Cuádriceps'],
      );

      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Glúteos'),
        isTrue,
      );
    });

    test('biceps en categoria Brazos aparece en filtro Biceps', () {
      const exercise = Exercise(
        wgerId: 98,
        name: 'Curl con barra',
        category: 'Brazos',
        muscles: ['Bíceps'],
      );

      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Bíceps'),
        isTrue,
      );
      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Tríceps'),
        isFalse,
      );
    });

    test('triceps en categoria Brazos aparece en filtro Triceps', () {
      const exercise = Exercise(
        wgerId: 101,
        name: 'Extension de triceps en polea',
        category: 'Brazos',
        muscles: ['Tríceps'],
      );

      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Tríceps'),
        isTrue,
      );
      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Bíceps'),
        isFalse,
      );
    });

    test('pantorrillas en categoria Pantorrillas aparece en filtro Piernas', () {
      const exercise = Exercise(
        wgerId: 102,
        name: 'Elevacion de gemelos de pie',
        category: 'Pantorrillas',
        muscles: ['Gastrocnemius'],
      );

      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Piernas'),
        isTrue,
      );
    });

    test('ejercicios cardio aparecen en filtro Cardio', () {
      const exercise = Exercise(
        name: 'Cardio en cinta',
        category: 'Cardio',
        loggingType: ExerciseLoggingType.cardio,
      );

      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Cardio'),
        isTrue,
      );
    });

    test('sentadilla con core secundario no aparece en filtro Abdominales', () {
      const exercise = Exercise(
        catalogId: 'ff_legs_goblet_squat',
        name: 'Goblet Squat',
        category: 'Piernas',
        muscles: ['Cuádriceps', 'Core'],
        isBundled: true,
      );

      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Abdominales'),
        isFalse,
      );
    });

    test('crunch del catalogo aparece en filtro Abdominales', () {
      const exercise = Exercise(
        catalogId: 'ff_abs_crunch',
        name: 'Crunch abdominal',
        category: 'Abdominales',
        muscles: ['Abdominales'],
        isBundled: true,
      );

      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Abdominales'),
        isTrue,
      );
    });
  });

  group('MuscleInference.resolve recovery tags', () {
    test('ejercicio Brazos sin músculos mapeados infiere bíceps por nombre', () {
      const catalog = [
        Exercise(
          wgerId: 99,
          name: 'Curl de predicador',
          category: 'Brazos',
          muscles: ['Brachialis'],
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Curl de predicador',
        exerciseId: '99',
        catalog: catalog,
      );

      expect(muscles, contains('Bíceps'));
    });

    test('curl femoral no etiqueta bíceps', () {
      expect(MuscleInference.fromExerciseName('Curl femoral sentado'), isNot(contains('Bíceps')));
      expect(MuscleInference.fromExerciseName('Curl femoral sentado'), contains('Piernas'));
    });

    test('hand grip registra antebrazos', () {
      expect(MuscleInference.fromExerciseName('Hand grip'), contains('Antebrazos'));
    });

    test('antebrazo de cuerda registra antebrazos', () {
      expect(MuscleInference.fromExerciseName('Antebrazo de cuerda de pie'), contains('Antebrazos'));
    });

    test('curl de triceps no etiqueta biceps', () {
      expect(MuscleInference.fromExerciseName('Curl de triceps en polea'), contains('Tríceps'));
      expect(MuscleInference.fromExerciseName('Curl de triceps en polea'), isNot(contains('Bíceps')));
    });

    test('curl de biceps no etiqueta triceps', () {
      expect(MuscleInference.fromExerciseName('Curl de biceps alterno'), contains('Bíceps'));
      expect(MuscleInference.fromExerciseName('Curl de biceps alterno'), isNot(contains('Tríceps')));
    });

    test('biceps femoris del catalogo no etiqueta biceps del brazo', () {
      expect(
        MuscleInference.fromExerciseMuscles(['Biceps femoris'], 'Piernas'),
        contains('Piernas'),
      );
      expect(
        MuscleInference.fromExerciseMuscles(['Biceps femoris'], 'Piernas'),
        isNot(contains('Bíceps')),
      );
    });

    test('triceps sural del catalogo no etiqueta triceps del brazo', () {
      expect(
        MuscleInference.fromExerciseMuscles(['Triceps surae'], 'Pantorrillas'),
        contains('Piernas'),
      );
      expect(
        MuscleInference.fromExerciseMuscles(['Triceps surae'], 'Pantorrillas'),
        isNot(contains('Tríceps')),
      );
    });

    test('catalogo triceps no mezcla biceps inferido por curl', () {
      const catalog = [
        Exercise(
          wgerId: 101,
          name: 'Extension de triceps en polea',
          category: 'Brazos',
          muscles: ['Tríceps'],
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Curl de triceps en polea',
        exerciseId: '101',
        catalog: catalog,
      );

      expect(muscles, contains('Tríceps'));
      expect(muscles, isNot(contains('Bíceps')));
    });
  });
}
