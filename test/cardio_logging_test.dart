import 'package:fitforge/core/utils/cardio_format.dart';
import 'package:fitforge/core/utils/exercise_load.dart';
import 'package:fitforge/core/utils/exercise_logging_resolver.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:fitforge/models/exercise_logging.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Exercise logging inference', () {
    test('category Cardio infers cardio logging type', () {
      const exercise = Exercise(
        name: 'Cinta',
        category: 'Cardio',
        loggingType: ExerciseLoggingType.cardio,
      );
      expect(exercise.isCardio, isTrue);
      expect(ExerciseLoggingResolver.inferFromCategory('Cardio'), ExerciseLoggingType.cardio);
      expect(ExerciseLoggingResolver.inferFromCategory('Pecho'), ExerciseLoggingType.strength);
    });

    test('inferFromName detecta cardio en cinta', () {
      expect(ExerciseLoggingResolver.inferFromName('Cardio en cinta'), isTrue);
      expect(ExerciseLoggingResolver.isCardioExercise(
        exerciseId: 'missing',
        exerciseName: 'Cardio en cinta',
      ), isTrue);
    });

    test('inferFromName detecta caminando y corriendo (gerundios)', () {
      expect(ExerciseLoggingResolver.inferFromName('Caminando'), isTrue);
      expect(ExerciseLoggingResolver.inferFromName('Walking'), isTrue);
      expect(ExerciseLoggingResolver.inferFromName('Corriendo'), isTrue);
      expect(ExerciseLoggingResolver.inferFromName('Running'), isTrue);
      expect(
        ExerciseLoggingResolver.isCardioExercise(
          exerciseId: '123',
          exerciseName: 'Caminando',
        ),
        isTrue,
      );
    });

    test('Exercise catalog infiere cardio por nombre aunque categoria sea Piernas', () {
      final exercise = Exercise.fromWgerJson({
        'id': 99,
        'translations': [
          {'language': 4, 'name': 'Caminando', 'description': ''},
        ],
        'category': {'name': 'Legs'},
        'muscles': [{'name': 'Quadriceps femoris'}],
        'equipment': [],
      });
      expect(exercise.isCardio, isTrue);
      expect(exercise.category, 'Piernas');
    });

    test('no clasifica zancadas caminando como cardio', () {
      expect(ExerciseLoggingResolver.inferFromName('Zancadas Caminando con Barra'), isFalse);
      expect(ExerciseLoggingResolver.inferFromName('Walking Lunges'), isFalse);
    });

    test('no clasifica remos de fuerza como cardio', () {
      const rowNames = [
        'Remo con polea',
        'Remo con polea baja',
        'Remo sentado en polea',
        'Remo invertido',
        'Remo en T',
        'Dominadas australianas (remo invertido)',
        'Seated cable row',
        'Barbell row',
        'Remo con barra',
        'Remo inclinado con mancuerna',
      ];
      for (final name in rowNames) {
        expect(ExerciseLoggingResolver.inferFromName(name), isFalse, reason: name);
        expect(
          ExerciseLoggingResolver.isCardioExercise(
            exerciseId: '123',
            exerciseName: name,
            sets: const [
              WorkoutSet(
                id: 's1',
                setNumber: 1,
                loggingType: ExerciseLoggingType.cardio,
                durationSeconds: 600,
              ),
            ],
          ),
          isFalse,
          reason: '$name con sets cardio mal etiquetados',
        );
      }
    });

    test('no clasifica dominadas ni flexiones como cardio', () {
      const names = [
        'Dominadas',
        'Dominadas supinas',
        'Pull-ups',
        'Flexiones',
        'Flexiones de brazos',
        'Push-ups',
        'flexiones en TRX',
      ];
      for (final name in names) {
        expect(ExerciseLoggingResolver.inferFromName(name), isFalse, reason: name);
        expect(
          ExerciseLoggingResolver.isCardioExercise(
            exerciseId: '475',
            exerciseName: name,
          ),
          isFalse,
          reason: name,
        );
      }

      final trx = Exercise.fromWgerJson({
        'id': 927,
        'translations': [
          {'language': 4, 'name': 'flexiones en TRX', 'description': ''},
        ],
        'category': {'name': 'Cardio'},
        'muscles': [],
        'equipment': [],
      });
      expect(trx.isCardio, isFalse);
    });

    test('sigue detectando remo ergometro como cardio', () {
      expect(ExerciseLoggingResolver.inferFromName('Remo'), isTrue);
      expect(ExerciseLoggingResolver.inferFromName('Rowing machine'), isTrue);
      expect(ExerciseLoggingResolver.inferFromName('Maquina de remo'), isTrue);
    });
  });

  group('CardioLoggingConfig', () {
    test('inferPresetFromName asigna metricas por maquina', () {
      expect(
        ExerciseLoggingResolver.inferPresetFromName('Cardio en cinta'),
        CardioPreset.treadmill,
      );
      expect(
        ExerciseLoggingResolver.inferPresetFromName('Bicicleta estatica'),
        CardioPreset.bike,
      );
      expect(
        ExerciseLoggingResolver.inferPresetFromName('Eliptica'),
        CardioPreset.elliptical,
      );
    });

    test('bike preset usa dificultad en lugar de inclinacion', () {
      final config = CardioLoggingConfig.fromPreset(CardioPreset.bike);
      expect(config.tracksDuration, isTrue);
      expect(config.tracksDistance, isTrue);
      expect(config.tracksDifficulty, isTrue);
      expect(config.tracksIncline, isFalse);
      expect(config.tracksSteps, isFalse);
    });

    test('treadmill preset tracks duration distance incline', () {
      final config = CardioLoggingConfig.fromPreset(CardioPreset.treadmill);
      expect(config.tracksDuration, isTrue);
      expect(config.tracksDistance, isTrue);
      expect(config.tracksIncline, isTrue);
      expect(config.tracksSteps, isFalse);
    });

    test('set is complete with at least one enabled metric', () {
      final config = CardioLoggingConfig.fromPreset(CardioPreset.treadmill);
      expect(
        config.isSetComplete(durationSeconds: 600, distanceMeters: null),
        isTrue,
      );
      expect(config.isSetComplete(), isFalse);
    });
  });

  group('CardioFormat', () {
    test('parses mm:ss duration', () {
      expect(CardioFormat.parseDuration('20:30'), 1230);
      expect(CardioFormat.duration(1230), '20:30');
    });

    test('parses separate minute and second fields', () {
      expect(CardioFormat.durationFromPartStrings('20', '30'), 1230);
      expect(CardioFormat.durationFromPartStrings('5', ''), 300);
      expect(CardioFormat.durationFromPartStrings('', '45'), 45);
      expect(CardioFormat.durationParts(1230), (minutes: 20, seconds: 30));
      expect(CardioFormat.durationFromPartStrings('1', '90'), isNull);
    });

    test('parses km distance in metric system', () {
      expect(CardioFormat.parseDistanceMeters('3.2', 'metric'), closeTo(3200, 0.1));
    });

    test('cardio en cinta usa inclinacion', () {
      final config = ExerciseLoggingResolver.cardioConfigFor(
        exerciseId: 'x',
        exerciseName: 'Cardio en cinta',
      );
      expect(config.tracksIncline, isTrue);
      expect(config.tracksDifficulty, isFalse);
    });

    test('format difficulty omits percent sign', () {
      expect(CardioFormat.difficulty(12), '12');
      expect(CardioFormat.incline(12), '12.0%');
    });

    test('elevation net matches gain minus loss with two decimals', () {
      expect(
        CardioFormat.elevationNet(
          gainMeters: 3.6,
          lossMeters: 3.2,
          unitSystem: 'metric',
        ),
        '+0.40 m',
      );
      expect(
        CardioFormat.elevationLive(3.6, 'metric'),
        '3.60 m',
      );
      expect(
        CardioFormat.elevationLive(3.2, 'metric'),
        '3.20 m',
      );
      expect(
        CardioFormat.elevationLive(0, 'metric'),
        '0.00 m',
      );
    });
  });

  group('Strength regression', () {
    test('strength set volume unchanged', () {
      const set = WorkoutSet(
        id: 's1',
        setNumber: 1,
        weight: 50,
        reps: 10,
        completed: true,
        loggingType: ExerciseLoggingType.strength,
      );
      expect(
        ExerciseLoad.setVolumeKg(set, exerciseName: 'Press banca'),
        500,
      );
    });

    test('cardio set volume is zero', () {
      const set = WorkoutSet(
        id: 's1',
        setNumber: 1,
        completed: true,
        loggingType: ExerciseLoggingType.cardio,
        durationSeconds: 1200,
        distanceMeters: 3000,
      );
      expect(
        ExerciseLoad.setVolumeKg(set, exerciseName: 'Cinta'),
        0,
      );
    });

    test('assisted exercise volume ignores weight but reps still count elsewhere', () {
      const set = WorkoutSet(
        id: 's1',
        setNumber: 1,
        weight: 40,
        reps: 12,
        completed: true,
        loggingType: ExerciseLoggingType.strength,
      );
      expect(
        ExerciseLoad.setVolumeKg(
          set,
          exerciseName: 'Assisted Pull Up Machine',
          loadMode: ExerciseLoadMode.assistedBodyweight,
        ),
        0,
      );
      expect(
        ExerciseLoad.setVolumeKg(set, exerciseName: 'Dominada asistida en máquina'),
        0,
      );
      expect(
        ExerciseLoad.isAssistedExercise('Assisted Dip Machine'),
        isTrue,
      );
    });

    test('bodyweight exercise uses profile weight plus additional load', () {
      const set = WorkoutSet(
        id: 's1',
        setNumber: 1,
        weight: 10,
        reps: 8,
        completed: true,
        loggingType: ExerciseLoggingType.strength,
      );
      expect(
        ExerciseLoad.setVolumeKg(
          set,
          exerciseName: 'Pull Up',
          loadMode: ExerciseLoadMode.bodyweight,
          bodyWeightKg: 75,
        ),
        (75 + 10) * 8,
      );
      expect(
        ExerciseLoad.setVolumeKg(
          const WorkoutSet(
            id: 's2',
            setNumber: 1,
            weight: 0,
            reps: 10,
            completed: true,
            loggingType: ExerciseLoggingType.strength,
          ),
          exerciseName: 'Chin Up',
          loadMode: ExerciseLoadMode.bodyweight,
          bodyWeightKg: 80,
        ),
        800,
      );
      expect(ExerciseLoad.bodyweightFractionForExercise('Decline Bench Sit-Up'), 0.42);
      expect(
        ExerciseLoad.setVolumeKg(
          const WorkoutSet(
            id: 's3',
            setNumber: 1,
            weight: 5,
            reps: 12,
            completed: true,
            loggingType: ExerciseLoggingType.strength,
          ),
          exerciseName: 'Abdominales en banca declinada',
          loadMode: ExerciseLoadMode.bodyweight,
          bodyWeightKg: 80,
        ),
        (80 * 0.42 + 5) * 12,
      );
      expect(
        ExerciseLoad.setVolumeKg(
          const WorkoutSet(
            id: 's4',
            setNumber: 1,
            weight: 0,
            reps: 15,
            completed: true,
            loggingType: ExerciseLoggingType.strength,
          ),
          exerciseName: 'Crunch abdominal',
          loadMode: ExerciseLoadMode.bodyweight,
          bodyWeightKg: 80,
        ),
        (80 * 0.32) * 15,
      );
    });

    test('per-arm session toggle doubles volume when enabled', () {
      const set = WorkoutSet(
        id: 's1',
        setNumber: 1,
        weight: 20,
        reps: 10,
        completed: true,
        loggingType: ExerciseLoggingType.strength,
      );
      expect(
        ExerciseLoad.setVolumeKg(
          set,
          exerciseName: 'Curl con mancuernas',
          perArmWeight: true,
        ),
        400,
      );
      expect(
        ExerciseLoad.setVolumeKg(
          set,
          exerciseName: 'Curl con mancuernas',
          perArmWeight: false,
        ),
        200,
      );
      expect(ExerciseLoad.supportsPerArmToggle('x', const [], 'Curl con mancuernas'), isTrue);
      expect(ExerciseLoad.supportsPerArmToggle('x', const [], 'Ab Crunch Machine'), isTrue);
      expect(ExerciseLoad.supportsPerArmToggle('x', const [], 'Chest Press Machine'), isTrue);
      expect(ExerciseLoad.supportsPerArmToggle('x', const [], 'Cinta'), isFalse);
    });

    test('usesPerLegLabel for leg machines and not for chest', () {
      expect(
        ExerciseLoad.usesPerLegLabel(exerciseName: 'Prensa de piernas'),
        isTrue,
      );
      expect(
        ExerciseLoad.usesPerLegLabel(exerciseName: 'Leg press'),
        isTrue,
      );
      expect(
        ExerciseLoad.usesPerLegLabel(exerciseName: 'Extensión de cuádriceps en máquina'),
        isTrue,
      );
      expect(
        ExerciseLoad.usesPerLegLabel(exerciseName: 'Curl con mancuernas'),
        isFalse,
      );
      expect(
        ExerciseLoad.usesPerLegLabel(exerciseName: 'Chest Press Machine'),
        isFalse,
      );
      expect(
        ExerciseLoad.usesPerLegLabel(exerciseName: 'Prensa de hombro'),
        isFalse,
      );
    });
  });
}
