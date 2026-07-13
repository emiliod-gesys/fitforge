import 'package:uuid/uuid.dart';

import '../../models/exercise_logging.dart';
import '../../models/routine.dart';
import 'runner_exercise_ids.dart';
import 'runner_standards.dart';

abstract final class RunnerRoutineBuilder {
  static const _uuid = Uuid();

  static List<Routine> buildAll({required String userId}) {
    return [
      build(userId: userId, type: RunnerType.outdoor),
      build(userId: userId, type: RunnerType.treadmill),
    ];
  }

  static Routine build({
    required String userId,
    required RunnerType type,
  }) {
    final isOutdoor = type == RunnerType.outdoor;
    return Routine(
      id: '',
      userId: userId,
      name: isOutdoor ? 'Salir a correr' : 'Correr en cinta',
      description: isOutdoor
          ? 'Carrera outdoor con GPS, ritmo y splits automáticos.'
          : 'Carrera en cinta con inclinación, distancia y ritmo.',
      targetMuscles: const ['Cardio'],
      exercises: [
        RoutineExercise(
          id: _uuid.v4(),
          exerciseId: isOutdoor ? RunnerExerciseIds.outdoorRunning : RunnerExerciseIds.treadmill,
          exerciseName: isOutdoor ? 'Carrera outdoor' : 'Cinta de correr',
          orderIndex: 0,
          targetSets: 1,
          targetReps: 0,
          loggingType: ExerciseLoggingType.cardio,
          targetInclinePercent: isOutdoor ? null : 0,
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isRunnerSystem: true,
      runnerType: type,
    );
  }
}
