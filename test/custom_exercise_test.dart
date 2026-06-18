import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge/core/utils/exercise_load.dart';
import 'package:fitforge/models/custom_exercise.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:fitforge/models/workout.dart';
import 'package:fitforge/services/custom_exercise_repository.dart';

void main() {
  test('CustomExercise genera id con prefijo custom:', () {
    final custom = CustomExercise(
      id: 'abc-123',
      name: 'Prensa Matrix',
      muscles: ['Piernas'],
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

    final exercise = custom.toExercise();
    expect(exercise.id, 'custom:abc-123');
    expect(exercise.isUserCustom, isTrue);
    expect(CustomExerciseRepository.isCustomExerciseId(exercise.id), isTrue);
    expect(CustomExerciseRepository.parseCustomId(exercise.id), 'abc-123');
  });

  test('CustomExercise perArmWeight se serializa y aplica al volumen', () {
    final custom = CustomExercise(
      id: 'curl-id',
      name: 'Curl en máquina',
      muscles: ['Bíceps'],
      perArmWeight: true,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

    final json = custom.toJson();
    expect(json['per_arm_weight'], isTrue);

    final restored = CustomExercise.fromJson(json);
    expect(restored.perArmWeight, isTrue);

    final exercise = restored.toExercise();
    expect(ExerciseLoad.perArmWeightOverride(exercise), isTrue);
    expect(ExerciseLoad.volumeMultiplier(exercise.name, perArmWeight: true), 2);

    const set = WorkoutSet(
      id: 's1',
      setNumber: 1,
      weight: 10,
      reps: 8,
      completed: true,
    );
    expect(
      ExerciseLoad.setVolumeKg(set, exerciseName: exercise.name, perArmWeight: true),
      160,
    );
  });
}
