import 'package:uuid/uuid.dart';

import '../../models/exercise_logging.dart';
import '../../models/routine.dart';
import 'runner_exercise_ids.dart';
import 'runner_standards.dart';

abstract final class RunnerRoutineBuilder {
  static const _uuid = Uuid();

  static List<Routine> buildAll({required String userId}) {
    return [
      for (final type in RunnerType.values) build(userId: userId, type: type),
    ];
  }

  static Routine build({
    required String userId,
    required RunnerType type,
  }) {
    final (name, description, exerciseId, exerciseName) = switch (type) {
      RunnerType.outdoor => (
          'Salir a correr',
          'Carrera outdoor con GPS, ritmo y splits automáticos.',
          RunnerExerciseIds.outdoorRunning,
          'Carrera outdoor',
        ),
      RunnerType.outdoorWalk => (
          'Salir a caminar',
          'Caminata outdoor con GPS, ritmo y splits automáticos.',
          RunnerExerciseIds.outdoorWalking,
          'Caminata outdoor',
        ),
      RunnerType.treadmill => (
          'Correr en cinta',
          'Carrera en cinta con inclinación, distancia y ritmo.',
          RunnerExerciseIds.treadmill,
          'Cinta de correr',
        ),
    };

    return Routine(
      id: '',
      userId: userId,
      name: name,
      description: description,
      targetMuscles: const ['Cardio'],
      exercises: [
        RoutineExercise(
          id: _uuid.v4(),
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          orderIndex: 0,
          targetSets: 1,
          targetReps: 0,
          loggingType: ExerciseLoggingType.cardio,
          targetInclinePercent: type == RunnerType.treadmill ? 0 : null,
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isRunnerSystem: true,
      runnerType: type,
    );
  }
}
