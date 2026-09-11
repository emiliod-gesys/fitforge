import 'package:fitforge/core/utils/superset_groups.dart';
import 'package:fitforge/models/exercise_logging.dart';
import 'package:fitforge/models/routine.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

RoutineExercise _re({
  required String id,
  required int order,
  String? groupId,
  int? slot,
  int sets = 3,
  bool cardio = false,
}) {
  return RoutineExercise(
    id: id,
    exerciseId: 'cat-$id',
    exerciseName: id.toUpperCase(),
    orderIndex: order,
    targetSets: sets,
    targetReps: 10,
    targetSetDetails: List.generate(sets, (_) => const RoutineSetTarget(reps: 10)),
    loggingType: cardio ? ExerciseLoggingType.cardio : ExerciseLoggingType.strength,
    supersetGroupId: groupId,
    supersetSlot: slot,
  );
}

WorkoutExercise _we({
  required String id,
  required int order,
  String? groupId,
  int? slot,
  required List<bool> completed,
}) {
  return WorkoutExercise(
    id: id,
    exerciseId: 'cat-$id',
    exerciseName: id.toUpperCase(),
    orderIndex: order,
    supersetGroupId: groupId,
    supersetSlot: slot,
    sets: [
      for (var i = 0; i < completed.length; i++)
        WorkoutSet(
          id: '$id-${i + 1}',
          setNumber: i + 1,
          reps: 8,
          weight: 50,
          completed: completed[i],
        ),
    ],
  );
}

void main() {
  group('SupersetGroups editor', () {
    test('groups consecutive members with the same id', () {
      final exercises = [
        _re(id: 'a', order: 0, groupId: 'g1', slot: 1),
        _re(id: 'b', order: 1, groupId: 'g1', slot: 2),
        _re(id: 'c', order: 2),
      ];
      final blocks = SupersetGroups.routineBlocks(exercises);
      expect(blocks, hasLength(2));
      expect(blocks[0].map((e) => e.id), ['a', 'b']);
      expect(blocks[1].map((e) => e.id), ['c']);
    });

    test('joins two singles and aligns shorter set lists', () {
      final exercises = [
        _re(id: 'a', order: 0, sets: 3),
        _re(id: 'b', order: 1, sets: 1),
      ];
      final joined = SupersetGroups.joinRoutineBlockWithNext(
        exercises,
        0,
        newGroupId: 'g-new',
      );
      expect(joined.every((e) => e.supersetGroupId == 'g-new'), isTrue);
      expect(joined[0].supersetSlot, 1);
      expect(joined[1].supersetSlot, 2);
      expect(joined[1].resolvedSetDetails, hasLength(3));
    });

    test('refuses joining cardio or a fourth member', () {
      expect(
        SupersetGroups.canJoinRoutineBlockWithNext(
          [_re(id: 'a', order: 0), _re(id: 'run', order: 1, cardio: true)],
          0,
        ),
        isFalse,
      );
      final trio = [
        _re(id: 'a', order: 0, groupId: 'g', slot: 1),
        _re(id: 'b', order: 1, groupId: 'g', slot: 2),
        _re(id: 'c', order: 2, groupId: 'g', slot: 3),
        _re(id: 'd', order: 3),
      ];
      expect(SupersetGroups.canJoinRoutineBlockWithNext(trio, 0), isFalse);
    });

    test('appends a singleton as slot C', () {
      final exercises = [
        _re(id: 'a', order: 0, groupId: 'g', slot: 1),
        _re(id: 'b', order: 1, groupId: 'g', slot: 2),
        _re(id: 'c', order: 2),
      ];
      final joined = SupersetGroups.joinRoutineBlockWithNext(
        exercises,
        0,
        newGroupId: 'unused',
      );
      expect(joined.map((e) => e.supersetSlot), [1, 2, 3]);
      expect(joined.every((e) => e.supersetGroupId == 'g'), isTrue);
    });

    test('leaving the middle member keeps the rest consecutive', () {
      final exercises = [
        _re(id: 'a', order: 0, groupId: 'g', slot: 1),
        _re(id: 'b', order: 1, groupId: 'g', slot: 2),
        _re(id: 'c', order: 2, groupId: 'g', slot: 3),
      ];
      final left = SupersetGroups.leaveRoutineSuperset(exercises, 'b');
      expect(left[0].id, 'a');
      expect(left[1].id, 'c');
      expect(left[2].id, 'b');
      expect(left[0].supersetGroupId, 'g');
      expect(left[1].supersetGroupId, 'g');
      expect(left[2].supersetGroupId, isNull);
    });

    test('leaving a pair clears both members', () {
      final exercises = [
        _re(id: 'a', order: 0, groupId: 'g', slot: 1),
        _re(id: 'b', order: 1, groupId: 'g', slot: 2),
      ];
      final left = SupersetGroups.leaveRoutineSuperset(exercises, 'a');
      expect(left.every((e) => e.supersetGroupId == null), isTrue);
    });

    test('reorders the whole block and inner slots', () {
      final exercises = [
        _re(id: 'a', order: 0, groupId: 'g', slot: 1),
        _re(id: 'b', order: 1, groupId: 'g', slot: 2),
        _re(id: 'c', order: 2),
      ];
      final moved = SupersetGroups.reorderRoutineBlocks(exercises, 0, 1);
      expect(moved.map((e) => e.id), ['c', 'a', 'b']);
      final swapped = SupersetGroups.reorderRoutineSlots(moved, 'g', 0, 1);
      expect(swapped.map((e) => e.id), ['c', 'b', 'a']);
      expect(swapped[1].supersetSlot, 1);
      expect(swapped[2].supersetSlot, 2);
    });
  });

  group('SupersetGroups workout', () {
    test('current round advances only after A and B of that round are done', () {
      const gid = 'g';
      final members = [
        _we(id: 'a', order: 0, groupId: gid, slot: 1, completed: [true, false, false]),
        _we(id: 'b', order: 1, groupId: gid, slot: 2, completed: [false, false, false]),
      ];
      expect(SupersetGroups.currentRound(members), 1);
      expect(SupersetGroups.activeMember(members)?.id, 'b');
      expect(SupersetGroups.isRoundComplete(members, 1), isFalse);

      final afterB = [
        members[0],
        _we(id: 'b', order: 1, groupId: gid, slot: 2, completed: [true, false, false]),
      ];
      expect(SupersetGroups.currentRound(afterB), 2);
      expect(SupersetGroups.activeMember(afterB)?.id, 'a');
      expect(SupersetGroups.nextMemberInRound(members, 'a', 1)?.id, 'b');
    });

    test('block navigation skips sibling members', () {
      const gid = 'g';
      final visible = [
        _we(id: 'a', order: 0, groupId: gid, slot: 1, completed: [false]),
        _we(id: 'b', order: 1, groupId: gid, slot: 2, completed: [false]),
        _we(id: 'c', order: 2, completed: [false]),
      ];
      expect(SupersetGroups.hasNextBlock(visible, 'a'), isTrue);
      expect(
        SupersetGroups.resolveNextBlockWorkoutIndex(
          workoutExercises: visible,
          visibleExercises: visible,
          currentExerciseId: 'a',
        ),
        2,
      );
      expect(SupersetGroups.hasPreviousBlock(visible, 'b'), isFalse);
      expect(
        SupersetGroups.resolvePreviousBlockWorkoutIndex(
          workoutExercises: visible,
          visibleExercises: visible,
          currentExerciseId: 'c',
        ),
        0,
      );
    });

    test('aligns workout group set counts to the first member', () {
      const gid = 'g';
      final exercises = [
        _we(id: 'a', order: 0, groupId: gid, slot: 1, completed: [false, false, false]),
        _we(id: 'b', order: 1, groupId: gid, slot: 2, completed: [false]),
      ];
      final aligned = SupersetGroups.alignWorkoutGroupSetCounts(exercises);
      expect(aligned[1].sets, hasLength(3));
      expect(aligned[1].sets.last.setNumber, 3);
    });

    test('watch label prefixes the slot letter', () {
      final exercise = WorkoutExercise(
        id: 'a',
        exerciseId: 'press',
        exerciseName: 'Press',
        orderIndex: 0,
        supersetGroupId: 'g',
        supersetSlot: 1,
        sets: const [WorkoutSet(id: 's1', setNumber: 1, reps: 8)],
      );
      expect(SupersetGroups.watchExerciseName(exercise), 'A Press');
    });

    test('joins two singles and aligns set counts', () {
      final exercises = [
        _we(id: 'a', order: 0, completed: [false, false, false]),
        _we(id: 'b', order: 1, completed: [false]),
      ];
      final joined = SupersetGroups.joinWorkoutBlockWithNext(
        exercises,
        0,
        newGroupId: 'g-new',
      );
      expect(joined.every((e) => e.supersetGroupId == 'g-new'), isTrue);
      expect(joined.map((e) => e.supersetSlot), [1, 2]);
      expect(joined[1].sets, hasLength(3));
    });

    test('leaving a pair splits them back into singles', () {
      final exercises = [
        _we(id: 'a', order: 0, groupId: 'g', slot: 1, completed: [false]),
        _we(id: 'b', order: 1, groupId: 'g', slot: 2, completed: [false]),
      ];
      final left = SupersetGroups.leaveWorkoutSuperset(exercises, 'a');
      expect(left.every((e) => e.supersetGroupId == null), isTrue);
      expect(left.every((e) => e.supersetSlot == null), isTrue);
      expect(SupersetGroups.workoutBlocks(left), hasLength(2));
    });

    test('cannot shrink rounds below a completed set', () {
      const gid = 'g';
      final exercises = [
        _we(id: 'a', order: 0, groupId: gid, slot: 1, completed: [true, true, false]),
        _we(id: 'b', order: 1, groupId: gid, slot: 2, completed: [true, false, false]),
      ];
      expect(SupersetGroups.minAllowedRounds(exercises), 2);
      final shrunk = SupersetGroups.setGroupRoundCount(exercises, gid, 1);
      expect(shrunk[0].sets, hasLength(2));
      expect(shrunk[1].sets, hasLength(2));
    });

    test('pads every member when raising the round count', () {
      const gid = 'g';
      final exercises = [
        _we(id: 'a', order: 0, groupId: gid, slot: 1, completed: [false, false]),
        _we(id: 'b', order: 1, groupId: gid, slot: 2, completed: [false, false]),
      ];
      final grown = SupersetGroups.setGroupRoundCount(exercises, gid, 4);
      expect(grown[0].sets.map((s) => s.setNumber), [1, 2, 3, 4]);
      expect(grown[1].sets, hasLength(4));
    });
  });

  group('SupersetGroups routine rounds', () {
    test('sets the same target set count on every member', () {
      final exercises = [
        _re(id: 'a', order: 0, groupId: 'g', slot: 1, sets: 3),
        _re(id: 'b', order: 1, groupId: 'g', slot: 2, sets: 3),
      ];
      final updated = SupersetGroups.setRoutineGroupRoundCount(exercises, 'g', 5);
      expect(updated.every((e) => e.targetSets == 5), isTrue);
      expect(updated[1].resolvedSetDetails, hasLength(5));
    });
  });
}
