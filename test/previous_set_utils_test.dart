import 'package:fitforge/core/utils/previous_set_utils.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreviousSetUtils', () {
    test('sortedMeaningfulSets ordena por setNumber ascendente', () {
      const sets = [
        WorkoutSet(id: 'a', setNumber: 3, weight: 30, reps: 8, completed: true),
        WorkoutSet(
            id: 'b', setNumber: 1, weight: 10, reps: 10, completed: true),
        WorkoutSet(id: 'c', setNumber: 2, weight: 20, reps: 9, completed: true),
      ];

      final sorted = PreviousSetUtils.sortedMeaningfulSets(sets);
      expect(sorted.map((s) => s.setNumber), [1, 2, 3]);
      expect(sorted.map((s) => s.weight), [10, 20, 30]);
    });

    test('sortedMeaningfulSets descarta series pre-rellenadas sin completar',
        () {
      // Plantilla guardada sin entrenar: solo reps, sin peso ni completed.
      const prefilled = [
        WorkoutSet(id: 'a', setNumber: 1, reps: 10),
        WorkoutSet(id: 'b', setNumber: 2, reps: 10),
        WorkoutSet(id: 'c', setNumber: 3, reps: 10),
      ];
      expect(PreviousSetUtils.sortedMeaningfulSets(prefilled), isEmpty);
    });

    test(
        'sortedMeaningfulSets conserva series completadas solo con reps (peso corporal)',
        () {
      const bodyweight = [
        WorkoutSet(id: 'a', setNumber: 1, reps: 12, completed: true),
        WorkoutSet(id: 'b', setNumber: 2, reps: 10, completed: true),
      ];
      expect(PreviousSetUtils.sortedMeaningfulSets(bodyweight).length, 2);
    });

    test(
        'sortedMeaningfulSets conserva series sin completar con peso registrado',
        () {
      const legacy = [
        WorkoutSet(id: 'a', setNumber: 1, weight: 50, reps: 10),
        WorkoutSet(id: 'b', setNumber: 2, reps: 10),
      ];
      final result = PreviousSetUtils.sortedMeaningfulSets(legacy);
      expect(result.length, 1);
      expect(result.first.weight, 50);
    });

    test(
        'forSetNumber empareja por numero de serie aunque la lista venga invertida',
        () {
      const previous = [
        WorkoutSet(id: 'a', setNumber: 3, weight: 30, reps: 8, completed: true),
        WorkoutSet(id: 'b', setNumber: 2, weight: 20, reps: 9, completed: true),
        WorkoutSet(
            id: 'c', setNumber: 1, weight: 10, reps: 10, completed: true),
      ];

      expect(PreviousSetUtils.forSetNumber(previous, 1)?.weight, 10);
      expect(PreviousSetUtils.forSetNumber(previous, 2)?.weight, 20);
      expect(PreviousSetUtils.forSetNumber(previous, 3)?.weight, 30);
    });

    test('forSetNumber reutiliza la ultima serie si hay mas series nuevas', () {
      const previous = [
        WorkoutSet(
            id: 'a', setNumber: 1, weight: 10, reps: 10, completed: true),
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

    test('el último entreno manda si es posterior a la rutina', () {
      final routineUpdated = DateTime.utc(2026, 10, 1);
      final performed = DateTime.utc(2026, 10, 6);

      expect(
        PreviousSetUtils.useLastPerformance(
          routineUpdatedAt: routineUpdated,
          lastPerformedAt: performed,
        ),
        isTrue,
      );
      expect(
        PreviousSetUtils.useLastPerformance(
          routineUpdatedAt: performed,
          lastPerformedAt: routineUpdated,
        ),
        isFalse,
      );
      expect(
        PreviousSetUtils.useLastPerformance(
          routineUpdatedAt: routineUpdated,
          lastPerformedAt: null,
        ),
        isFalse,
      );
    });

    test('al iniciar una rutina conserva series y pesos de la plantilla', () {
      const template = [
        WorkoutSet(id: 't1', setNumber: 1, weight: 40, reps: 12),
        WorkoutSet(id: 't2', setNumber: 2, weight: 42.5, reps: 10),
        WorkoutSet(id: 't3', setNumber: 3, weight: 42.5, reps: 10),
        WorkoutSet(id: 't4', setNumber: 4, weight: 45, reps: 8),
        WorkoutSet(id: 't5', setNumber: 5, weight: 45, reps: 8),
      ];
      const previous = [
        WorkoutSet(
            id: 'a', setNumber: 1, weight: 20, reps: 10, completed: true),
        WorkoutSet(
            id: 'b', setNumber: 2, weight: 20, reps: 10, completed: true),
        WorkoutSet(
            id: 'c', setNumber: 3, weight: 20, reps: 10, completed: true),
      ];

      final merged = PreviousSetUtils.mergeTemplateWithHistory(
        template: template,
        previous: previous,
        isCardio: false,
        isLoadedDistance: false,
        preserveTemplate: true,
      );

      expect(merged.length, 5);
      expect(merged.map((s) => s.weight), [40, 42.5, 42.5, 45, 45]);
      expect(merged.map((s) => s.reps), [12, 10, 10, 8, 8]);
    });

    test('sin plantilla de rutina sigue el último entreno', () {
      const template = [
        WorkoutSet(id: 't1', setNumber: 1, weight: 40, reps: 12),
        WorkoutSet(id: 't2', setNumber: 2, weight: 40, reps: 12),
        WorkoutSet(id: 't3', setNumber: 3, weight: 40, reps: 12),
        WorkoutSet(id: 't4', setNumber: 4, weight: 40, reps: 12),
        WorkoutSet(id: 't5', setNumber: 5, weight: 40, reps: 12),
      ];
      const previous = [
        WorkoutSet(id: 'a', setNumber: 1, weight: 20, reps: 8, completed: true),
        WorkoutSet(id: 'b', setNumber: 2, weight: 22, reps: 8, completed: true),
        WorkoutSet(id: 'c', setNumber: 3, weight: 22, reps: 8, completed: true),
      ];

      final merged = PreviousSetUtils.mergeTemplateWithHistory(
        template: template,
        previous: previous,
        isCardio: false,
        isLoadedDistance: false,
      );

      expect(merged.length, 3);
      expect(merged.map((s) => s.weight), [20, 22, 22]);
      expect(merged.map((s) => s.reps), [8, 8, 8]);
    });

    test('la rutina sin peso rellena con el último entreno', () {
      const template = [
        WorkoutSet(id: 't1', setNumber: 1, reps: 10),
        WorkoutSet(id: 't2', setNumber: 2, reps: 10),
        WorkoutSet(id: 't3', setNumber: 3, reps: 10),
        WorkoutSet(id: 't4', setNumber: 4, reps: 10),
      ];
      const previous = [
        WorkoutSet(id: 'a', setNumber: 1, weight: 30, reps: 8, completed: true),
        WorkoutSet(id: 'b', setNumber: 2, weight: 30, reps: 8, completed: true),
        WorkoutSet(id: 'c', setNumber: 3, weight: 30, reps: 8, completed: true),
      ];

      final merged = PreviousSetUtils.mergeTemplateWithHistory(
        template: template,
        previous: previous,
        isCardio: false,
        isLoadedDistance: false,
        preserveTemplate: true,
      );

      expect(merged.length, 4);
      expect(merged.map((s) => s.weight), [30, 30, 30, 30]);
      expect(merged.map((s) => s.reps), [10, 10, 10, 10]);
    });
  });
}
