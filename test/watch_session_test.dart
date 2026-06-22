import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:fitforge/models/watch_session.dart';

void main() {
  group('WatchWorkoutSnapshot', () {
    test('roundtrips through json', () {
      const snapshot = WatchWorkoutSnapshot(
        workoutId: 'w1',
        exerciseId: 'e1',
        exerciseName: 'Bench Press',
        setId: 's1',
        setNumber: 2,
        weight: 80,
        reps: 8,
        unitSystem: 'kg',
        isCardio: false,
        restEndsAtEpochMs: 1700000000000,
        restTotalSeconds: 90,
        updatedAtEpochMs: 1699999000000,
      );

      final decoded = WatchWorkoutSnapshot.decode(snapshot.encode());
      expect(decoded, isNotNull);
      expect(decoded!.exerciseName, 'Bench Press');
      expect(decoded.setNumber, 2);
      expect(decoded.weight, 80);
      expect(decoded.restTotalSeconds, 90);
    });
  });

  group('WatchWorkoutAction', () {
    test('decodes complete_set action', () {
      final action = WatchWorkoutAction.decode(
        jsonEncode({'type': 'complete_set'}),
      );
      expect(action?.type, WatchActionType.completeSet);
    });

    test('decodes adjust_rest action', () {
      final action = WatchWorkoutAction.decode(
        jsonEncode({'type': 'adjust_rest', 'deltaSeconds': -15}),
      );
      expect(action?.type, WatchActionType.adjustRest);
      expect(action?.deltaSeconds, -15);
    });
  });
}
