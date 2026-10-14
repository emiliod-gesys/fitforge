import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exercise.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../workout/routine_to_workout_exercises.dart';

bool isWorkoutTutorialRoutine(Routine routine) {
  return !routine.isHyroxSystem &&
      !routine.isRunnerSystem &&
      routine.exercises.isNotEmpty;
}

Routine? firstWorkoutTutorialRoutine(Iterable<Routine> routines) {
  for (final routine in routines) {
    if (isWorkoutTutorialRoutine(routine)) return routine;
  }
  return null;
}

/// ID of a workout this tour created. Null if the tour reused a live session.
class TutorialWorkoutSession extends Notifier<String?> {
  Future<void>? _inFlight;

  @override
  String? build() => null;

  Future<void> ensure() {
    final existing = _inFlight;
    if (existing != null) return existing;
    final future = _ensure();
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
  }

  Future<void> _ensure() async {
    Workout? active;
    try {
      active = await ref.read(activeWorkoutProvider.future);
    } catch (_) {
      active = null;
    }
    if (active != null) return;

    List<Routine> routines = const [];
    try {
      routines = await ref.read(routinesProvider.future);
    } catch (_) {}

    final routine = firstWorkoutTutorialRoutine(routines);
    if (routine == null) return;

    final workout = await ref.read(workoutServiceProvider).startWorkout(
          name: routine.name,
          routineId: routine.id,
          exercises: workoutExercisesFromRoutine(routine),
        );
    if (!ref.exists(tutorialWorkoutSessionProvider)) return;
    state = workout.id;
    ref.invalidate(activeWorkoutProvider);
    try {
      await ref.read(activeWorkoutProvider.future);
    } catch (_) {}
  }

  /// Cancels only a workout this tour created. Returns true if one was discarded.
  Future<bool> discard() async {
    await _inFlight;
    final id = state;
    if (id == null) return false;
    state = null;
    try {
      await ref.read(workoutServiceProvider).cancelWorkout(id);
    } catch (_) {}
    try {
      await ref.read(watchWorkoutCoordinatorProvider).clear();
    } catch (_) {}
    ref.invalidate(activeWorkoutProvider);
    ref.invalidate(pendingSyncCountProvider);
    ref.invalidate(workoutsProvider);
    ref.invalidate(recentWorkoutsProvider);
    ref.invalidate(workoutHistoryProvider);
    return true;
  }
}

final tutorialWorkoutSessionProvider =
    NotifierProvider<TutorialWorkoutSession, String?>(
  TutorialWorkoutSession.new,
);

List<WorkoutExercise> tutorialDemoExercises(List<Exercise> catalog) {
  final strength = catalog
      .where((exercise) => !exercise.isCardio && exercise.id.isNotEmpty)
      .take(2)
      .toList();
  return [
    for (var i = 0; i < strength.length; i++)
      WorkoutExercise(
        id: '',
        exerciseId: strength[i].id,
        exerciseName: strength[i].name,
        imageUrl: strength[i].imageUrl,
        orderIndex: i,
        sets: [
          for (var setNumber = 1; setNumber <= 3; setNumber++)
            WorkoutSet(id: '', setNumber: setNumber, reps: 10),
        ],
      ),
  ];
}
