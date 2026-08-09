import 'package:fitforge/core/runner/runner_exercise_ids.dart';
import 'package:fitforge/core/runner/runner_routine_builder.dart';
import 'package:fitforge/core/runner/runner_standards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds outdoor walk as GPS clone of outdoor run', () {
    final walk = RunnerRoutineBuilder.build(
      userId: 'user-1',
      type: RunnerType.outdoorWalk,
    );

    expect(walk.isRunnerSystem, isTrue);
    expect(walk.runnerType, RunnerType.outdoorWalk);
    expect(walk.runnerType!.usesOutdoorGps, isTrue);
    expect(walk.runnerType!.isWalk, isTrue);
    expect(walk.name, 'Salir a caminar');
    expect(walk.exercises, hasLength(1));
    expect(walk.exercises.first.exerciseId, RunnerExerciseIds.outdoorWalking);
  });

  test('buildAll seeds run, walk, and treadmill', () {
    final all = RunnerRoutineBuilder.buildAll(userId: 'user-1');
    expect(all.map((r) => r.runnerType), [
      RunnerType.outdoor,
      RunnerType.outdoorWalk,
      RunnerType.treadmill,
    ]);
  });
}
