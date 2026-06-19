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
  });
}
