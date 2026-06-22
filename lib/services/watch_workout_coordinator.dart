import 'dart:async';

import '../models/watch_session.dart';
import '../models/workout.dart';
import 'watch_session_bridge.dart';

typedef WatchWorkoutActionHandler = Future<void> Function(
  WatchWorkoutAction action,
);

/// Keeps the watch companion in sync with the active workout on the phone.
class WatchWorkoutCoordinator {
  WatchWorkoutCoordinator(this._bridge);

  final WatchSessionBridge _bridge;
  StreamSubscription<WatchWorkoutAction>? _subscription;
  WatchWorkoutActionHandler? _handler;
  WatchWorkoutSnapshot? _lastSnapshot;
  WatchWorkoutSnapshot? get lastSnapshot => _lastSnapshot;

  void attach(WatchWorkoutActionHandler handler) {
    _handler = handler;
    _subscription ??= _bridge.actions.listen(_onAction);
  }

  void detach() {
    _handler = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(clear());
  }

  Future<void> _onAction(WatchWorkoutAction action) async {
    final handler = _handler;
    if (handler == null) return;
    await handler(action);
  }

  Future<void> syncFromWorkout({
    required Workout workout,
    required WorkoutExercise exercise,
    required String unitSystem,
    required Set<String> removedSetIds,
    DateTime? restEndsAt,
    int? restTotalSeconds,
  }) async {
    final sets = [...exercise.sets]
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    final visibleSets =
        sets.where((s) => !removedSetIds.contains(s.id)).toList();
    if (visibleSets.isEmpty) {
      await clear();
      return;
    }

    final currentSet = visibleSets.firstWhere(
      (s) => !s.completed,
      orElse: () => visibleSets.last,
    );

    final snapshot = WatchWorkoutSnapshot(
      workoutId: workout.id,
      exerciseId: exercise.id,
      exerciseName: exercise.exerciseName,
      setId: currentSet.id,
      setNumber: currentSet.setNumber,
      weight: currentSet.weight,
      reps: currentSet.reps,
      unitSystem: unitSystem,
      isCardio: currentSet.isCardio,
      restEndsAtEpochMs: restEndsAt?.millisecondsSinceEpoch,
      restTotalSeconds: restTotalSeconds,
      updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );

    if (_lastSnapshot?.encode() == snapshot.encode()) return;
    _lastSnapshot = snapshot;
    await _bridge.publishSession(snapshot);
  }

  Future<void> clear() async {
    _lastSnapshot = null;
    await _bridge.clearSession();
  }

  Future<bool> isWatchAvailable() => _bridge.isWatchAvailable();
}
