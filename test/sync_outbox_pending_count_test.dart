import 'package:fitforge/services/offline/sync_outbox.dart';
import 'package:flutter_test/flutter_test.dart';

SyncOperation _op({
  required String id,
  required String workoutId,
  SyncOperationType type = SyncOperationType.logSet,
}) {
  return SyncOperation(
    id: id,
    type: type,
    workoutId: workoutId,
    payload: const {},
    createdAt: DateTime.utc(2026, 1, 1),
    occurredAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  test('pending count ignores cancel ops and the live workout', () {
    final ops = [
      _op(id: '1', workoutId: 'active'),
      _op(id: '2', workoutId: 'done'),
      _op(id: '3', workoutId: 'done', type: SyncOperationType.completeWorkout),
      _op(id: '4', workoutId: 'gone', type: SyncOperationType.cancelWorkout),
    ];

    expect(SyncOutbox.distinctPendingWorkoutCount(ops), 2);
    expect(
      SyncOutbox.distinctPendingWorkoutCount(ops, excludeWorkoutId: 'active'),
      1,
    );
  });
}
