import 'package:fitforge/core/utils/exercise_load.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:fitforge/models/exercise_logging.dart';
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
        ExerciseLoad.weightOptionalForExerciseId('bw1', catalog, exerciseName: 'Plank hold'),
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
