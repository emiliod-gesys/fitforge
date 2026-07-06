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
    test('hip thrust en categoria piernas aparece solo en filtro piernas', () {
      const exercise = Exercise(
        wgerId: 1234,
        name: 'Hip Thrust con Barra',
        category: 'Piernas',
        muscles: ['Cuádriceps', 'Glúteos'],
      );

      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Piernas'),
        isTrue,
      );
      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Glúteos'),
        isFalse,
      );
    });

    test('hip thrust sin categoria util se infiere por nombre', () {
      const exercise = Exercise(
        wgerId: 1235,
        name: 'Barbell Hip Thrust',
        category: '',
        muscles: const [],
      );

      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Glúteos'),
        isTrue,
      );
    });

    test('fondos asistidos solo aparecen en triceps, no en pecho', () {
      const exercise = Exercise(
        catalogId: 'ff_triceps_assisted_dip_machine',
        name: 'Assisted Dip Machine',
        category: 'Triceps',
        muscles: ['Triceps', 'Chest', 'Front delts'],
        isBundled: true,
      );

      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Tríceps'),
        isTrue,
      );
      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Pecho'),
        isFalse,
      );
    });

    test('pullover con barra en pecho no aparece en filtro espalda por lats secundarios', () {
      const exercise = Exercise(
        catalogId: 'ff_chest_barbell_pullover',
        name: 'Barbell Pullover',
        category: 'Chest',
        muscles: ['Chest', 'Lats', 'Triceps'],
        isBundled: true,
      );

      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Pecho'),
        isTrue,
      );
      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Espalda'),
        isFalse,
      );
    });

    test('caminata del granjero aparece en antebrazos por musculo secundario', () {
      const exercise = Exercise(
        catalogId: 'ff_cf_farmers_walk',
        name: "Farmer's Walk",
        category: 'Legs',
        muscles: ['Quads', 'Hamstrings', 'Glutes', 'Calves', 'Forearms', 'Abs'],
        isBundled: true,
      );

      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Piernas'),
        isTrue,
      );
      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Antebrazos'),
        isTrue,
      );
    });

    test('curl inverso en polea aparece en filtro antebrazos', () {
      const exercise = Exercise(
        catalogId: 'ff_biceps_reverse_cable_curl',
        name: 'Reverse Cable Curl',
        category: 'Forearms',
        muscles: ['Forearms', 'Brachialis', 'Biceps'],
        isBundled: true,
      );

      expect(
        MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: 'Antebrazos'),
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

    test('ejercicio de piernas con gluteos secundarios en catalogo afecta recuperacion', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_legs_belt_squat_machine',
          name: 'Sentadilla con cinturón en máquina',
          category: 'Piernas',
          muscles: ['Cuádriceps', 'Glúteos', 'Isquios'],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Sentadilla con cinturón en máquina',
        exerciseId: 'ff_legs_belt_squat_machine',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Glúteos'));
    });

    test('hack squat por nombre tambien etiqueta gluteos', () {
      expect(MuscleInference.fromExerciseName('Hack Squat Machine'), contains('Glúteos'));
      expect(MuscleInference.fromExerciseName('Hack Squat Machine'), contains('Piernas'));
    });

    test('dumbbell fly no etiqueta biceps por estabilizadores del catalogo', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_chest_dumbbell_fly',
          name: 'Dumbbell Fly',
          category: 'Pecho',
          muscles: ['Pecho', 'Deltoides anterior', 'Biceps stabilizers'],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Dumbbell Fly',
        exerciseId: 'ff_chest_dumbbell_fly',
        catalog: catalog,
      );

      expect(muscles, contains('Pecho'));
      expect(muscles, contains('Hombros'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('jalon de triceps no etiqueta espalda', () {
      expect(
        MuscleInference.fromExerciseName('Jalón de tríceps con barra V'),
        contains('Tríceps'),
      );
      expect(
        MuscleInference.fromExerciseName('Jalón de tríceps con barra V'),
        isNot(contains('Espalda')),
      );

      const catalog = [
        Exercise(
          catalogId: 'ff_triceps_v_bar_pushdown',
          name: 'Jalón de tríceps con barra V',
          category: 'Tríceps',
          muscles: ['Tríceps', 'Antebrazos'],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Jalón de tríceps con barra V',
        exerciseId: 'ff_triceps_v_bar_pushdown',
        catalog: catalog,
      );

      expect(muscles, contains('Tríceps'));
      expect(muscles, isNot(contains('Espalda')));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('rutina de pecho y hombros no etiqueta biceps', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_chest_dumbbell_fly',
          name: 'Dumbbell Fly',
          category: 'Pecho',
          muscles: ['Pecho', 'Deltoides anterior', 'Biceps stabilizers'],
          isBundled: true,
        ),
        Exercise(
          catalogId: 'ff_triceps_v_bar_pushdown',
          name: 'Jalón de tríceps con barra V',
          category: 'Tríceps',
          muscles: ['Tríceps', 'Antebrazos'],
          isBundled: true,
        ),
        Exercise(
          catalogId: 'ff_chest_chest_press_machine',
          name: 'Chest Press Machine',
          category: 'Pecho',
          muscles: ['Pecho', 'Tríceps', 'Deltoides anterior'],
          isBundled: true,
        ),
        Exercise(
          catalogId: 'ff_chest_cable_fly',
          name: 'Cable Fly',
          category: 'Pecho',
          muscles: ['Pecho', 'Deltoides anterior'],
          isBundled: true,
        ),
        Exercise(
          catalogId: 'ff_shoulders_dumbbell_shoulder_press',
          name: 'Press de hombro con mancuernas',
          category: 'Hombros',
          muscles: ['Deltoides anterior', 'Tríceps', 'Deltoides lateral'],
          isBundled: true,
        ),
        Exercise(
          catalogId: 'ff_shoulders_cable_lateral_raise',
          name: 'Elevación lateral en polea',
          category: 'Hombros',
          muscles: ['Deltoides lateral', 'Upper Traps'],
          isBundled: true,
        ),
      ];

      final trained = <String>{};
      for (final exercise in catalog) {
        trained.addAll(
          MuscleInference.resolve(
            exerciseName: exercise.name,
            exerciseId: exercise.catalogId,
            catalog: catalog,
          ),
        );
      }

      expect(trained, isNot(contains('Bíceps')));
      expect(trained, contains('Pecho'));
      expect(trained, contains('Hombros'));
      expect(trained, contains('Tríceps'));
    });

    test('musculos secundarios tienen menor impacto que primarios', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_chest_chest_press_machine',
          name: 'Chest Press Machine',
          category: 'Pecho',
          muscles: ['Pecho', 'Tríceps', 'Deltoides anterior'],
          isBundled: true,
        ),
      ];

      final impacts = MuscleInference.resolveImpacts(
        exerciseName: 'Chest Press Machine',
        exerciseId: 'ff_chest_chest_press_machine',
        catalog: catalog,
      );

      expect(impacts['Pecho'], 1.0);
      expect(impacts['Tríceps'], MuscleInference.secondaryImpactWeight);
      expect(impacts['Hombros'], MuscleInference.secondaryImpactWeight);
    });

    test('press militar con front delts afecta hombros como primario', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_shoulders_barbell_overhead_press',
          name: 'Barbell Standing Military Press',
          category: 'Shoulders',
          muscles: ['Front delts', 'Triceps', 'Side delts', 'Upper chest'],
          isBundled: true,
        ),
      ];

      final impacts = MuscleInference.resolveImpacts(
        exerciseName: 'Barbell Standing Military Press',
        exerciseId: 'ff_shoulders_barbell_overhead_press',
        catalog: catalog,
      );

      expect(impacts['Hombros'], 1.0);
      expect(impacts['Tríceps'], MuscleInference.secondaryImpactWeight);
    });

    test('burpee no etiqueta biceps y afecta piernas pecho y core', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_burpee',
          name: 'Burpee',
          category: 'Piernas',
          muscles: [
            'Cuádriceps',
            'Pecho',
            'Tríceps',
            'Deltoides anterior',
            'Abdominales',
            'Glúteos',
            'Pantorrillas',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Burpee',
        exerciseId: 'ff_cf_burpee',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Pecho'));
      expect(muscles, contains('Abdominales'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('box jump no etiqueta pecho ni biceps', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_box_jump',
          name: 'Box Jump',
          category: 'Piernas',
          muscles: [
            'Cuádriceps',
            'Glúteos',
            'Isquios',
            'Pantorrillas',
            'Abdominales',
            'Deltoides anterior',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Salto al cajón',
        exerciseId: 'ff_cf_box_jump',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Pecho')));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('box step over no etiqueta pecho ni biceps', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_box_step_over',
          name: 'Box Step Over',
          category: 'Piernas',
          muscles: [
            'Cuádriceps',
            'Glúteos',
            'Isquios',
            'Pantorrillas',
            'Abdominales',
            'Aductores',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Step-over en cajón',
        exerciseId: 'ff_cf_box_step_over',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Pecho')));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('wall ball etiqueta piernas y hombros sin biceps', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_wall_ball',
          name: 'Wall Ball Shot',
          category: 'Piernas',
          muscles: [
            'Cuádriceps',
            'Glúteos',
            'Deltoides anterior',
            'Tríceps',
            'Abdominales',
            'Pecho',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Wall ball',
        exerciseId: 'ff_cf_wall_ball',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Hombros'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('thruster etiqueta piernas hombros y gluteos sin biceps', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_thruster',
          name: 'Barbell Thruster',
          category: 'Piernas',
          muscles: [
            'Cuádriceps',
            'Glúteos',
            'Deltoides anterior',
            'Tríceps',
            'Abdominales',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Thruster con barra',
        exerciseId: 'ff_cf_thruster',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Hombros'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('dumbbell thruster etiqueta piernas hombros y gluteos', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_dumbbell_thruster',
          name: 'Dumbbell Thruster',
          category: 'Piernas',
          muscles: [
            'Cuádriceps',
            'Glúteos',
            'Deltoides anterior',
            'Tríceps',
            'Abdominales',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Thruster con mancuernas',
        exerciseId: 'ff_cf_dumbbell_thruster',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Hombros'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('power clean etiqueta piernas y gluteos sin fatiga espalda secundaria', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_power_clean',
          name: 'Power Clean',
          category: 'Piernas',
          muscles: [
            'Isquios',
            'Glúteos',
            'Cuádriceps',
            'Espalda alta',
            'Hombros',
            'Pantorrillas',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Cargada de potencia',
        exerciseId: 'ff_cf_power_clean',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, isNot(contains('Espalda')));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('hang power clean etiqueta piernas y gluteos sin espalda secundaria', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_hang_power_clean',
          name: 'Hang Power Clean',
          category: 'Piernas',
          muscles: [
            'Isquios',
            'Glúteos',
            'Cuádriceps',
            'Espalda alta',
            'Hombros',
            'Pantorrillas',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Hang power clean',
        exerciseId: 'ff_cf_hang_power_clean',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, isNot(contains('Espalda')));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('clean and jerk etiqueta piernas hombros y gluteos sin espalda secundaria', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_clean_and_jerk',
          name: 'Clean and Jerk',
          category: 'Piernas',
          muscles: [
            'Isquios',
            'Glúteos',
            'Cuádriceps',
            'Espalda alta',
            'Hombros',
            'Tríceps',
            'Pantorrillas',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Cargada y envión',
        exerciseId: 'ff_cf_clean_and_jerk',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, isNot(contains('Espalda')));
      expect(muscles, contains('Hombros'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('power snatch etiqueta piernas hombros y gluteos sin espalda secundaria', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_power_snatch',
          name: 'Power Snatch',
          category: 'Piernas',
          muscles: [
            'Isquios',
            'Glúteos',
            'Cuádriceps',
            'Espalda alta',
            'Hombros',
            'Tríceps',
            'Abdominales',
            'Pantorrillas',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Arrancada de potencia',
        exerciseId: 'ff_cf_power_snatch',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, isNot(contains('Espalda')));
      expect(muscles, contains('Hombros'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('barbell shrug etiqueta espalda no biceps', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_back_barbell_shrug',
          name: 'Barbell Shrug',
          category: 'Espalda',
          muscles: ['Espalda alta', 'Hombros'],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Encogimiento con barra',
        exerciseId: 'ff_back_barbell_shrug',
        catalog: catalog,
      );

      expect(muscles, contains('Espalda'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('standing military press etiqueta hombros y triceps secundario', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_shoulders_barbell_overhead_press',
          name: 'Barbell Standing Military Press',
          category: 'Hombros',
          muscles: ['Deltoides anterior', 'Tríceps', 'Deltoides lateral', 'Pecho superior'],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Press militar de pie con barra',
        exerciseId: 'ff_shoulders_barbell_overhead_press',
        catalog: catalog,
      );

      expect(muscles, contains('Hombros'));
      expect(muscles, contains('Tríceps'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('snatch deadlift etiqueta piernas y gluteos sin espalda primaria', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_snatch_deadlift',
          name: 'Barbell Snatch Deadlift',
          category: 'Espalda',
          muscles: [
            'Espalda',
            'Glúteos',
            'Isquios',
            'Cuádriceps',
            'Aductores',
            'Pantorrillas',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Peso muerto snatch',
        exerciseId: 'ff_cf_snatch_deadlift',
        catalog: catalog,
      );

      expect(muscles, isNot(contains('Espalda')));
      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('barbell romanian deadlift etiqueta piernas y gluteos sin espalda', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_back_romanian_deadlift',
          name: 'Barbell Romanian Deadlift',
          category: 'Espalda',
          muscles: ['Isquios', 'Glúteos', 'Erector Spinae', 'Espalda'],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Peso muerto rumano con barra',
        exerciseId: 'ff_back_romanian_deadlift',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Espalda')));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('conventional deadlift etiqueta piernas y gluteos sin espalda', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_back_deadlift',
          name: 'Deadlift',
          category: 'Espalda',
          muscles: ['Espalda', 'Glúteos', 'Isquios', 'Trapecios', 'Antebrazos'],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Peso muerto',
        exerciseId: 'ff_back_deadlift',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Espalda')));

      final impacts = MuscleInference.resolveImpacts(
        exerciseName: 'Peso muerto',
        exerciseId: 'ff_back_deadlift',
        catalog: catalog,
      );
      expect(impacts['Espalda'] ?? 0, lessThan(MuscleInference.minVisibleImpact));
      expect(impacts['Piernas'], 1.0);
      expect(impacts['Glúteos'], 1.0);
    });

    test('peso muerto sin catalogo no etiqueta espalda', () {
      final muscles = MuscleInference.fromExerciseName('Peso muerto convencional');

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Espalda')));
    });

    test('barbell front squat etiqueta piernas y gluteos', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_legs_front_squat',
          name: 'Barbell Front Squat',
          category: 'Piernas',
          muscles: ['Cuádriceps', 'Glúteos', 'Espalda alta', 'Core'],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Sentadilla frontal con barra',
        exerciseId: 'ff_legs_front_squat',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('overhead squat etiqueta piernas hombros y core', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_overhead_squat',
          name: 'Barbell Overhead Squat',
          category: 'Piernas',
          muscles: [
            'Cuádriceps',
            'Glúteos',
            'Isquios',
            'Hombros',
            'Abdominales',
            'Pantorrillas',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Overhead squat',
        exerciseId: 'ff_cf_overhead_squat',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Hombros'));
      expect(muscles, contains('Abdominales'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('kettlebell swing etiqueta gluteos piernas y abdominales', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_kettlebell_swing',
          name: 'Kettlebell Swing',
          category: 'Glúteos',
          muscles: ['Glúteos', 'Isquios', 'Abdominales', 'Hombros', 'Antebrazos'],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Swing con kettlebell',
        exerciseId: 'ff_cf_kettlebell_swing',
        catalog: catalog,
      );

      expect(muscles, contains('Glúteos'));
      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Abdominales'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('kettlebell snatch etiqueta hombros gluteos y piernas sin espalda secundaria', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_kettlebell_snatch',
          name: 'Kettlebell Snatch',
          category: 'Hombros',
          muscles: [
            'Deltoides anterior',
            'Glúteos',
            'Isquios',
            'Espalda alta',
            'Abdominales',
            'Antebrazos',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Snatch con kettlebell',
        exerciseId: 'ff_cf_kettlebell_snatch',
        catalog: catalog,
      );

      expect(muscles, contains('Hombros'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, contains('Piernas'));
      expect(muscles, isNot(contains('Espalda')));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('kettlebell clean and press etiqueta hombros piernas y gluteos', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_kettlebell_clean_and_press',
          name: 'Kettlebell Clean and Press',
          category: 'Hombros',
          muscles: [
            'Deltoides anterior',
            'Cuádriceps',
            'Glúteos',
            'Isquios',
            'Tríceps',
            'Abdominales',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Cargada y press con kettlebell',
        exerciseId: 'ff_cf_kettlebell_clean_and_press',
        catalog: catalog,
      );

      expect(muscles, contains('Hombros'));
      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, contains('Tríceps'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('barbell sumo deadlift etiqueta piernas y gluteos sin espalda', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_glutes_sumo_deadlift',
          name: 'Barbell Sumo Deadlift',
          category: 'Glúteos',
          muscles: ['Glúteos', 'Isquios', 'Cuádriceps', 'Aductores'],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Peso muerto sumo con barra',
        exerciseId: 'ff_glutes_sumo_deadlift',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Espalda')));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('sumo deadlift sin catalogo etiqueta piernas y gluteos', () {
      final muscles = MuscleInference.resolve(
        exerciseName: 'Sumo Deadlift',
        catalog: const [],
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, isNot(contains('Espalda')));
    });

    test('farmers walk etiqueta piernas gluteos antebrazos y core', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_farmers_walk',
          name: "Farmer's Walk",
          category: 'Piernas',
          muscles: [
            'Cuádriceps',
            'Isquios',
            'Glúteos',
            'Pantorrillas',
            'Antebrazos',
            'Abdominales',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Caminata del granjero',
        exerciseId: 'ff_cf_farmers_walk',
        catalog: catalog,
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, contains('Antebrazos'));
      expect(muscles, contains('Abdominales'));
      expect(muscles, isNot(contains('Bíceps')));
    });

    test('farmers walk sin catalogo etiqueta piernas gluteos y antebrazos', () {
      final muscles = MuscleInference.resolve(
        exerciseName: "Farmer's Walk",
        catalog: const [],
      );

      expect(muscles, contains('Piernas'));
      expect(muscles, contains('Glúteos'));
      expect(muscles, contains('Antebrazos'));
      expect(muscles, contains('Abdominales'));
    });

    test('kipping pull up etiqueta espalda biceps abdominales y antebrazos', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_kipping_pull_up',
          name: 'Kipping Pull Up',
          category: 'Espalda',
          muscles: [
            'Dorsales',
            'Bíceps',
            'Abdominales',
            'Antebrazos',
            'Pecho',
            'Espalda alta',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Dominada kipping',
        exerciseId: 'ff_cf_kipping_pull_up',
        catalog: catalog,
      );

      expect(muscles, contains('Espalda'));
      expect(muscles, contains('Bíceps'));
      expect(muscles, contains('Abdominales'));
      expect(muscles, contains('Antebrazos'));
      expect(muscles, isNot(contains('Tríceps')));
    });

    test('kipping pull up sin catalogo etiqueta espalda biceps y core', () {
      final muscles = MuscleInference.resolve(
        exerciseName: 'Kipping Pull Up',
        catalog: const [],
      );

      expect(muscles, contains('Espalda'));
      expect(muscles, contains('Bíceps'));
      expect(muscles, contains('Abdominales'));
    });

    test('muscle up etiqueta espalda biceps triceps hombros y core', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_muscle_up',
          name: 'Muscle Up',
          category: 'Espalda',
          muscles: [
            'Dorsales',
            'Bíceps',
            'Tríceps',
            'Abdominales',
            'Pecho',
            'Deltoides anterior',
            'Antebrazos',
            'Espalda alta',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Muscle up',
        exerciseId: 'ff_cf_muscle_up',
        catalog: catalog,
      );

      expect(muscles, contains('Espalda'));
      expect(muscles, contains('Bíceps'));
      expect(muscles, contains('Tríceps'));
      expect(muscles, contains('Hombros'));
      expect(muscles, contains('Abdominales'));
    });

    test('muscle up sin catalogo etiqueta espalda biceps triceps y hombros', () {
      final muscles = MuscleInference.resolve(
        exerciseName: 'Muscle Up',
        catalog: const [],
      );

      expect(muscles, contains('Espalda'));
      expect(muscles, contains('Bíceps'));
      expect(muscles, contains('Tríceps'));
      expect(muscles, contains('Hombros'));
      expect(muscles, contains('Abdominales'));
    });

    test('bar pull over etiqueta espalda biceps abdominales y antebrazos', () {
      const catalog = [
        Exercise(
          catalogId: 'ff_cf_bar_pullover',
          name: 'Bar Pull Over',
          category: 'Espalda',
          muscles: [
            'Dorsales',
            'Bíceps',
            'Abdominales',
            'Pecho',
            'Deltoides posterior',
            'Antebrazos',
            'Espalda alta',
          ],
          isBundled: true,
        ),
      ];

      final muscles = MuscleInference.resolve(
        exerciseName: 'Pull over en barra',
        exerciseId: 'ff_cf_bar_pullover',
        catalog: catalog,
      );

      expect(muscles, contains('Espalda'));
      expect(muscles, contains('Bíceps'));
      expect(muscles, contains('Abdominales'));
      expect(muscles, contains('Antebrazos'));
      expect(muscles, isNot(contains('Tríceps')));
    });

    test('bar pull over sin catalogo etiqueta espalda biceps y core', () {
      final muscles = MuscleInference.resolve(
        exerciseName: 'Bar Pull Over',
        catalog: const [],
      );

      expect(muscles, contains('Espalda'));
      expect(muscles, contains('Bíceps'));
      expect(muscles, contains('Abdominales'));
    });
  });
}
