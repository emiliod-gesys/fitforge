import 'package:fitforge/core/utils/exercise_load.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:fitforge/models/exercise_logging.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weightOptionalForExerciseId', () {
    test('treats catalog bodyweight load mode as optional', () {
      final catalog = [
        const Exercise(
          catalogId: 'bw1',
          name: 'Plank hold',
          isBundled: true,
          weightOptional: true,
          loadMode: ExerciseLoadMode.bodyweight,
        ),
      ];
      expect(
        ExerciseLoad.weightOptionalForExerciseId('bw1', catalog,
            exerciseName: 'Plank hold'),
        isTrue,
      );
    });

    test('overrides mis-tagged single_load when name is bodyweight', () {
      final catalog = [
        const Exercise(
          catalogId: 'cloud_burpee',
          name: 'Burpees',
          isBundled: true,
          weightOptional: false,
          loadMode: ExerciseLoadMode.singleLoad,
        ),
      ];
      expect(
        ExerciseLoad.weightOptionalForExerciseId(
          'cloud_burpee',
          catalog,
          exerciseName: 'Burpees',
        ),
        isTrue,
      );
    });

    test('treats bodyweight-only equipment as optional', () {
      final catalog = [
        const Exercise(
          catalogId: 'core1',
          name: 'Hollow hold variation',
          isBundled: true,
          weightOptional: false,
          loadMode: ExerciseLoadMode.singleLoad,
          equipment: ['body weight', 'none'],
        ),
      ];
      expect(
        ExerciseLoad.weightOptionalForExerciseId(
          'core1',
          catalog,
          exerciseName: 'Hollow hold variation',
        ),
        isTrue,
      );
    });

    test('crunch en máquina no usa peso corporal', () {
      final catalog = [
        const Exercise(
          catalogId: 'ff_abs_ab_crunch_machine',
          name: 'Crunch abdominal en máquina',
          isBundled: true,
          weightOptional: false,
          loadMode: ExerciseLoadMode.machineStack,
          equipment: ['Máquina'],
        ),
        const Exercise(
          catalogId: 'ff_abs_machine_seated_leg_raise_crunch',
          name: 'Crunch con elevación de piernas en máquina',
          isBundled: true,
          weightOptional: false,
          loadMode: ExerciseLoadMode.machineStack,
          equipment: ['Máquina'],
        ),
        const Exercise(
          catalogId: 'cloud_lever_seated_crunch',
          name: 'Lever Seated Crunch',
          isBundled: true,
          weightOptional: true,
          loadMode: ExerciseLoadMode.bodyweight,
          equipment: ['Machine'],
        ),
      ];

      for (final exercise in catalog) {
        expect(
          ExerciseLoad.weightOptionalForExerciseId(
            exercise.id,
            catalog,
            exerciseName: exercise.name,
          ),
          isFalse,
          reason: exercise.name,
        );
        expect(
          ExerciseLoad.isBodyweightLoad(exercise.id, catalog, exercise.name),
          isFalse,
          reason: exercise.name,
        );
        expect(
          ExerciseLoad.loadModeForExerciseId(
            exercise.id,
            catalog,
            exerciseName: exercise.name,
          ),
          ExerciseLoadMode.machineStack,
          reason: exercise.name,
        );
        expect(
          ExerciseLoad.effectiveWeightKg(
            const WorkoutSet(id: 's', setNumber: 1, weight: 25, reps: 12),
            exerciseName: exercise.name,
            loadMode: ExerciseLoadMode.bodyweight,
            bodyWeightKg: 80,
          ),
          25,
          reason: exercise.name,
        );
        expect(
          ExerciseLoad.weightLabel('kg', exercise.name, weightOptional: true),
          'kg',
          reason: exercise.name,
        );
      }

      for (final name in [
        'Ab Crunch Machine',
        'Machine Seated Leg Raise Crunch',
        'Lever Seated Crunch',
      ]) {
        expect(ExerciseLoad.isBodyweightLoad('x', catalog, name), isFalse,
            reason: name);
        expect(
          ExerciseLoad.effectiveWeightKg(
            const WorkoutSet(id: 's', setNumber: 1, weight: 40, reps: 10),
            exerciseName: name,
            loadMode: ExerciseLoadMode.bodyweight,
            bodyWeightKg: 75,
          ),
          40,
          reason: name,
        );
      }
    });

    test('el crunch de suelo sigue contando peso corporal', () {
      final catalog = [
        const Exercise(
          catalogId: 'ff_abs_crunch',
          name: 'Crunch abdominal',
          isBundled: true,
          weightOptional: true,
          loadMode: ExerciseLoadMode.bodyweight,
          equipment: ['Peso corporal'],
        ),
      ];
      expect(
        ExerciseLoad.isBodyweightLoad(
            'ff_abs_crunch', catalog, 'Crunch abdominal'),
        isTrue,
      );
      expect(
        ExerciseLoad.effectiveWeightKg(
          const WorkoutSet(id: 's', setNumber: 1, weight: 5, reps: 12),
          exerciseName: 'Crunch abdominal',
          loadMode: ExerciseLoadMode.bodyweight,
          bodyWeightKg: 80,
        ),
        closeTo(80 * 0.32 + 5, 0.01),
      );
    });

    test('keeps weighted barbell lifts required', () {
      final catalog = [
        const Exercise(
          catalogId: 'sq1',
          name: 'Back squat',
          isBundled: true,
          weightOptional: false,
          loadMode: ExerciseLoadMode.singleLoad,
          equipment: ['barbell'],
        ),
      ];
      expect(
        ExerciseLoad.weightOptionalForExerciseId(
          'sq1',
          catalog,
          exerciseName: 'Back squat',
        ),
        isFalse,
      );
    });
  });
}
