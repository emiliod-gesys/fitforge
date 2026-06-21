import 'package:fitforge/core/utils/previous_set_utils.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreviousSetUtils', () {
    test('sortedMeaningfulSets ordena por setNumber ascendente', () {
      const sets = [
        WorkoutSet(id: 'a', setNumber: 3, weight: 30, reps: 8, completed: true),
        WorkoutSet(id: 'b', setNumber: 1, weight: 10, reps: 10, completed: true),
        WorkoutSet(id: 'c', setNumber: 2, weight: 20, reps: 9, completed: true),
      ];

      final sorted = PreviousSetUtils.sortedMeaningfulSets(sets);
      expect(sorted.map((s) => s.setNumber), [1, 2, 3]);
      expect(sorted.map((s) => s.weight), [10, 20, 30]);
    });

    test('forSetNumber empareja por numero de serie aunque la lista venga invertida', () {
      const previous = [
        WorkoutSet(id: 'a', setNumber: 3, weight: 30, reps: 8, completed: true),
        WorkoutSet(id: 'b', setNumber: 2, weight: 20, reps: 9, completed: true),
        WorkoutSet(id: 'c', setNumber: 1, weight: 10, reps: 10, completed: true),
      ];

      expect(PreviousSetUtils.forSetNumber(previous, 1)?.weight, 10);
      expect(PreviousSetUtils.forSetNumber(previous, 2)?.weight, 20);
      expect(PreviousSetUtils.forSetNumber(previous, 3)?.weight, 30);
    });

    test('forSetNumber reutiliza la ultima serie si hay mas series nuevas', () {
      const previous = [
        WorkoutSet(id: 'a', setNumber: 1, weight: 10, reps: 10, completed: true),
        WorkoutSet(id: 'b', setNumber: 2, weight: 20, reps: 9, completed: true),
      ];

      expect(PreviousSetUtils.forSetNumber(previous, 3)?.weight, 20);
    });

    test('resolveSetCount usa la cantidad del entreno anterior', () {
      const previous = [
        WorkoutSet(id: 'a', setNumber: 1, weight: 10, reps: 10),
        WorkoutSet(id: 'b', setNumber: 2, weight: 20, reps: 9),
        WorkoutSet(id: 'c', setNumber: 3, weight: 30, reps: 8),
        WorkoutSet(id: 'd', setNumber: 4, weight: 40, reps: 7),
      ];

      expect(
        PreviousSetUtils.resolveSetCount(templateCount: 3, previous: previous),
        4,
      );
      expect(
        PreviousSetUtils.resolveSetCount(templateCount: 3, previous: null),
        3,
      );
    });
  });
}
