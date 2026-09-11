import '../../models/routine.dart';
import '../../models/workout.dart';

/// Bloques de superserie (2–3 ejercicios consecutivos con el mismo `superset_group_id`).
abstract final class SupersetGroups {
  static const maxMembers = 3;
  static const minRounds = 1;
  static const maxRounds = 8;

  static String slotLetter(int slot) {
    return switch (slot) {
      1 => 'A',
      2 => 'B',
      _ => 'C',
    };
  }

  static String watchExerciseName(WorkoutExercise exercise) {
    final slot = exercise.supersetSlot;
    if (slot == null) return exercise.exerciseName;
    return '${slotLetter(slot)} ${exercise.exerciseName}';
  }

  static List<List<T>> blocksOf<T>(
    List<T> exercises, {
    required String? Function(T e) groupId,
    required int Function(T e) orderIndex,
    required int Function(T e) slot,
  }) {
    final sorted = [...exercises]..sort((a, b) {
        final byOrder = orderIndex(a).compareTo(orderIndex(b));
        if (byOrder != 0) return byOrder;
        return slot(a).compareTo(slot(b));
      });

    final blocks = <List<T>>[];
    var i = 0;
    while (i < sorted.length) {
      final gid = groupId(sorted[i]);
      if (gid == null) {
        blocks.add([sorted[i]]);
        i++;
        continue;
      }
      final group = <T>[sorted[i]];
      i++;
      while (i < sorted.length && groupId(sorted[i]) == gid) {
        group.add(sorted[i]);
        i++;
      }
      group.sort((a, b) => slot(a).compareTo(slot(b)));
      blocks.add(group);
    }
    return blocks;
  }

  static List<List<RoutineExercise>> routineBlocks(List<RoutineExercise> exercises) {
    return blocksOf(
      exercises,
      groupId: (e) => e.supersetGroupId,
      orderIndex: (e) => e.orderIndex,
      slot: (e) => e.supersetSlot ?? 0,
    );
  }

  static List<List<WorkoutExercise>> workoutBlocks(List<WorkoutExercise> exercises) {
    return blocksOf(
      exercises,
      groupId: (e) => e.supersetGroupId,
      orderIndex: (e) => e.orderIndex,
      slot: (e) => e.supersetSlot ?? 0,
    );
  }

  static bool isGroup(List<dynamic> block) => block.length >= 2;

  static List<RoutineExercise> flattenRoutineBlocks(List<List<RoutineExercise>> blocks) {
    final out = <RoutineExercise>[];
    var order = 0;
    for (final block in blocks) {
      for (var i = 0; i < block.length; i++) {
        final ex = block[i];
        if (block.length >= 2) {
          final gid = ex.supersetGroupId ?? block.first.supersetGroupId;
          out.add(ex.copyWith(
            orderIndex: order,
            supersetGroupId: gid,
            supersetSlot: i + 1,
          ));
        } else {
          out.add(ex.copyWith(orderIndex: order, clearSuperset: true));
        }
        order++;
      }
    }
    return out;
  }

  static List<RoutineExercise> reindexRoutine(List<RoutineExercise> exercises) {
    return flattenRoutineBlocks(routineBlocks(exercises));
  }

  static bool canJoinRoutineBlockWithNext(List<RoutineExercise> exercises, int blockIndex) {
    final blocks = routineBlocks(exercises);
    if (blockIndex < 0 || blockIndex >= blocks.length - 1) return false;
    final current = blocks[blockIndex];
    final next = blocks[blockIndex + 1];
    if (current.length + next.length > maxMembers) return false;
    if (current.any((e) => e.isCardio) || next.any((e) => e.isCardio)) return false;
    return true;
  }

  static List<RoutineExercise> joinRoutineBlockWithNext(
    List<RoutineExercise> exercises,
    int blockIndex, {
    required String newGroupId,
  }) {
    if (!canJoinRoutineBlockWithNext(exercises, blockIndex)) return exercises;
    final blocks = routineBlocks(exercises);
    final current = blocks[blockIndex];
    final next = blocks[blockIndex + 1];
    final gid = current.first.supersetGroupId ?? next.first.supersetGroupId ?? newGroupId;
    final rest = current.first.restSeconds;
    final merged = alignRoutineSetCounts([...current, ...next])
        .map((e) => e.copyWith(supersetGroupId: gid, restSeconds: rest))
        .toList();
    blocks[blockIndex] = merged;
    blocks.removeAt(blockIndex + 1);
    return flattenRoutineBlocks(blocks);
  }

  static List<RoutineExercise> alignRoutineSetCounts(List<RoutineExercise> members) {
    if (members.isEmpty) return members;
    final target = members.first.resolvedSetDetails;
    if (target.isEmpty) return members;
    return members.map((ex) {
      var details = [...ex.resolvedSetDetails];
      if (details.isEmpty) {
        details = List<RoutineSetTarget>.from(target);
      } else {
        while (details.length < target.length) {
          details.add(details.last);
        }
        if (details.length > target.length) {
          details = details.take(target.length).toList();
        }
      }
      return ex.copyWith(targetSetDetails: details, targetSets: details.length).withSyncedLegacyFields();
    }).toList();
  }

  static List<RoutineExercise> leaveRoutineSuperset(
    List<RoutineExercise> exercises,
    String exerciseId,
  ) {
    final blocks = routineBlocks(exercises);
    final blockIndex = indexOfBlockContaining(blocks, exerciseId, (e) => e.id);
    if (blockIndex == null) return exercises;
    final block = blocks[blockIndex];
    if (block.length < 2) return exercises;

    final leaveIndex = block.indexWhere((e) => e.id == exerciseId);
    final leaving = block[leaveIndex].copyWith(clearSuperset: true);
    final remaining = [
      for (var i = 0; i < block.length; i++)
        if (i != leaveIndex) block[i],
    ];

    if (remaining.length < 2) {
      blocks.removeAt(blockIndex);
      var insertAt = blockIndex;
      for (final e in block) {
        blocks.insert(insertAt, [e.copyWith(clearSuperset: true)]);
        insertAt++;
      }
    } else {
      blocks[blockIndex] = remaining;
      if (leaveIndex == 0) {
        blocks.insert(blockIndex, [leaving]);
      } else {
        blocks.insert(blockIndex + 1, [leaving]);
      }
    }
    return flattenRoutineBlocks(blocks);
  }

  static List<RoutineExercise> reorderRoutineBlocks(
    List<RoutineExercise> exercises,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex == newIndex) return reindexRoutine(exercises);
    final blocks = routineBlocks(exercises);
    if (oldIndex < 0 || oldIndex >= blocks.length) return exercises;
    if (newIndex < 0 || newIndex >= blocks.length) return exercises;
    final moved = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, moved);
    return flattenRoutineBlocks(blocks);
  }

  static List<RoutineExercise> reorderRoutineSlots(
    List<RoutineExercise> exercises,
    String groupId,
    int oldSlotIndex,
    int newSlotIndex,
  ) {
    if (oldSlotIndex == newSlotIndex) return reindexRoutine(exercises);
    final blocks = routineBlocks(exercises);
    final blockIndex = blocks.indexWhere(
      (b) => b.length >= 2 && b.first.supersetGroupId == groupId,
    );
    if (blockIndex < 0) return exercises;
    final block = [...blocks[blockIndex]];
    if (oldSlotIndex < 0 || oldSlotIndex >= block.length) return exercises;
    if (newSlotIndex < 0 || newSlotIndex >= block.length) return exercises;
    final moved = block.removeAt(oldSlotIndex);
    block.insert(newSlotIndex, moved);
    blocks[blockIndex] = block;
    return flattenRoutineBlocks(blocks);
  }

  static bool _isWorkoutCardio(WorkoutExercise exercise) {
    return exercise.sets.any((s) => s.isCardio);
  }

  static List<WorkoutExercise> flattenWorkoutBlocks(List<List<WorkoutExercise>> blocks) {
    final out = <WorkoutExercise>[];
    var order = 0;
    for (final block in blocks) {
      for (var i = 0; i < block.length; i++) {
        final ex = block[i];
        if (block.length >= 2) {
          final gid = ex.supersetGroupId ?? block.first.supersetGroupId;
          out.add(ex.copyWith(
            orderIndex: order,
            supersetGroupId: gid,
            supersetSlot: i + 1,
          ));
        } else {
          out.add(ex.copyWith(orderIndex: order, clearSuperset: true));
        }
        order++;
      }
    }
    return out;
  }

  static bool canJoinWorkoutBlockWithNext(
    List<WorkoutExercise> exercises,
    int blockIndex, {
    bool Function(WorkoutExercise e)? isCardio,
  }) {
    final cardioOf = isCardio ?? _isWorkoutCardio;
    final blocks = workoutBlocks(exercises);
    if (blockIndex < 0 || blockIndex >= blocks.length - 1) return false;
    final current = blocks[blockIndex];
    final next = blocks[blockIndex + 1];
    if (current.length + next.length > maxMembers) return false;
    if (current.any(cardioOf) || next.any(cardioOf)) return false;
    return true;
  }

  static List<WorkoutExercise> joinWorkoutBlockWithNext(
    List<WorkoutExercise> exercises,
    int blockIndex, {
    required String newGroupId,
    bool Function(WorkoutExercise e)? isCardio,
  }) {
    if (!canJoinWorkoutBlockWithNext(exercises, blockIndex, isCardio: isCardio)) {
      return exercises;
    }
    final blocks = workoutBlocks(exercises);
    final current = blocks[blockIndex];
    final next = blocks[blockIndex + 1];
    final gid = current.first.supersetGroupId ?? next.first.supersetGroupId ?? newGroupId;
    final merged = [...current, ...next]
        .map((e) => e.copyWith(supersetGroupId: gid))
        .toList();
    blocks[blockIndex] = merged;
    blocks.removeAt(blockIndex + 1);
    return alignWorkoutGroupSetCounts(flattenWorkoutBlocks(blocks));
  }

  static List<WorkoutExercise> leaveWorkoutSuperset(
    List<WorkoutExercise> exercises,
    String exerciseId,
  ) {
    final blocks = workoutBlocks(exercises);
    final blockIndex = indexOfBlockContaining(blocks, exerciseId, (e) => e.id);
    if (blockIndex == null) return exercises;
    final block = blocks[blockIndex];
    if (block.length < 2) return exercises;

    final leaveIndex = block.indexWhere((e) => e.id == exerciseId);
    final leaving = block[leaveIndex].copyWith(clearSuperset: true);
    final remaining = [
      for (var i = 0; i < block.length; i++)
        if (i != leaveIndex) block[i],
    ];

    if (remaining.length < 2) {
      blocks.removeAt(blockIndex);
      var insertAt = blockIndex;
      for (final e in block) {
        blocks.insert(insertAt, [e.copyWith(clearSuperset: true)]);
        insertAt++;
      }
    } else {
      blocks[blockIndex] = remaining;
      if (leaveIndex == 0) {
        blocks.insert(blockIndex, [leaving]);
      } else {
        blocks.insert(blockIndex + 1, [leaving]);
      }
    }
    return flattenWorkoutBlocks(blocks);
  }

  static int minAllowedRounds(List<WorkoutExercise> members) {
    var min = minRounds;
    for (final member in members) {
      for (final set in member.sets) {
        if (set.completed && set.setNumber > min) min = set.setNumber;
      }
    }
    return min.clamp(minRounds, maxRounds);
  }

  static List<WorkoutExercise> setGroupRoundCount(
    List<WorkoutExercise> exercises,
    String groupId,
    int rounds,
  ) {
    final members = membersOf(exercises, groupId);
    if (members.isEmpty) return exercises;
    var target = rounds.clamp(minRounds, maxRounds);
    final floor = minAllowedRounds(members);
    if (target < floor) target = floor;
    return [
      for (final ex in exercises)
        if (ex.supersetGroupId == groupId)
          _resizeSets(ex, target)
        else
          ex,
    ];
  }

  static WorkoutExercise _resizeSets(WorkoutExercise exercise, int rounds) {
    var sets = [...exercise.sets]..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    if (sets.isEmpty) return exercise;
    while (sets.length < rounds) {
      final last = sets.last;
      sets.add(
        WorkoutSet(
          id: '',
          setNumber: sets.length + 1,
          weight: last.weight,
          reps: last.reps,
          loggingType: last.loggingType,
        ),
      );
    }
    if (sets.length > rounds) {
      sets = sets.take(rounds).toList();
    }
    return exercise.copyWith(sets: sets);
  }

  static List<RoutineExercise> setRoutineGroupRoundCount(
    List<RoutineExercise> exercises,
    String groupId,
    int rounds,
  ) {
    final target = rounds.clamp(minRounds, maxRounds);
    return exercises.map((e) {
      if (e.supersetGroupId != groupId) return e;
      var details = [...e.resolvedSetDetails];
      if (details.isEmpty) {
        details = [const RoutineSetTarget(reps: 10)];
      }
      while (details.length < target) {
        details.add(details.last);
      }
      if (details.length > target) {
        details = details.take(target).toList();
      }
      return e
          .copyWith(targetSetDetails: details, targetSets: details.length)
          .withSyncedLegacyFields();
    }).toList();
  }

  static List<WorkoutExercise> alignWorkoutGroupSetCounts(
    List<WorkoutExercise> exercises,
  ) {
    if (exercises.isEmpty) return exercises;
    final blocks = workoutBlocks(exercises);
    final out = <WorkoutExercise>[];
    for (final block in blocks) {
      if (block.length < 2) {
        out.addAll(block);
        continue;
      }
      final target = block.first.sets.length;
      if (target <= 0) {
        out.addAll(block);
        continue;
      }
      for (final member in block) {
        var sets = [...member.sets]..sort((a, b) => a.setNumber.compareTo(b.setNumber));
        if (sets.isEmpty) {
          out.add(member);
          continue;
        }
        while (sets.length < target) {
          final last = sets.last;
          sets.add(
            WorkoutSet(
              id: '',
              setNumber: sets.length + 1,
              weight: last.weight,
              reps: last.reps,
              loggingType: last.loggingType,
            ),
          );
        }
        if (sets.length > target) {
          sets = sets.take(target).toList();
        }
        out.add(member.copyWith(sets: sets));
      }
    }
    return out;
  }

  static List<RoutineExercise> setRoutineGroupRestSeconds(
    List<RoutineExercise> exercises,
    String groupId,
    int restSeconds,
  ) {
    return exercises
        .map(
          (e) => e.supersetGroupId == groupId ? e.copyWith(restSeconds: restSeconds) : e,
        )
        .toList();
  }

  static int? indexOfBlockContaining<T>(
    List<List<T>> blocks,
    String id,
    String Function(T e) idOf,
  ) {
    for (var i = 0; i < blocks.length; i++) {
      if (blocks[i].any((e) => idOf(e) == id)) return i;
    }
    return null;
  }

  static List<WorkoutExercise> membersOf(
    List<WorkoutExercise> exercises,
    String? groupId,
  ) {
    if (groupId == null) return const [];
    return [
      for (final block in workoutBlocks(exercises))
        if (block.length >= 2 && block.first.supersetGroupId == groupId) ...block,
    ];
  }

  static WorkoutSet? setForRound(WorkoutExercise exercise, int round) {
    for (final set in exercise.sets) {
      if (set.setNumber == round) return set;
    }
    return null;
  }

  static bool _memberRoundDone(WorkoutExercise exercise, int round) {
    final set = setForRound(exercise, round);
    if (set == null) return true;
    return set.completed;
  }

  static int roundCount(List<WorkoutExercise> members) {
    if (members.isEmpty) return 0;
    var maxRounds = 0;
    for (final member in members) {
      if (member.sets.length > maxRounds) maxRounds = member.sets.length;
    }
    return maxRounds;
  }

  static int currentRound(List<WorkoutExercise> members) {
    final total = roundCount(members);
    if (total <= 0) return 1;
    for (var round = 1; round <= total; round++) {
      if (!members.every((m) => _memberRoundDone(m, round))) return round;
    }
    return total;
  }

  static int completedRounds(List<WorkoutExercise> members) {
    final total = roundCount(members);
    var done = 0;
    for (var round = 1; round <= total; round++) {
      if (members.every((m) => _memberRoundDone(m, round))) {
        done++;
      } else {
        break;
      }
    }
    return done;
  }

  static bool isRoundComplete(List<WorkoutExercise> members, int round) {
    if (members.isEmpty) return false;
    return members.every((m) => _memberRoundDone(m, round));
  }

  static WorkoutExercise? activeMember(List<WorkoutExercise> members) {
    if (members.isEmpty) return null;
    final round = currentRound(members);
    for (final member in members) {
      if (!_memberRoundDone(member, round)) return member;
    }
    return members.first;
  }

  static WorkoutExercise? nextMemberInRound(
    List<WorkoutExercise> members,
    String currentId,
    int round,
  ) {
    final start = members.indexWhere((e) => e.id == currentId);
    if (start < 0) return null;
    for (var i = start + 1; i < members.length; i++) {
      if (!_memberRoundDone(members[i], round)) return members[i];
    }
    return null;
  }

  static int? resolvePreviousBlockWorkoutIndex({
    required List<WorkoutExercise> workoutExercises,
    required List<WorkoutExercise> visibleExercises,
    required String currentExerciseId,
  }) {
    final blocks = workoutBlocks(visibleExercises);
    final blockIndex = indexOfBlockContaining(blocks, currentExerciseId, (e) => e.id);
    if (blockIndex == null || blockIndex <= 0) return null;
    final previousId = blocks[blockIndex - 1].first.id;
    final index = workoutExercises.indexWhere((e) => e.id == previousId);
    return index >= 0 ? index : null;
  }

  static int? resolveNextBlockWorkoutIndex({
    required List<WorkoutExercise> workoutExercises,
    required List<WorkoutExercise> visibleExercises,
    required String currentExerciseId,
  }) {
    final blocks = workoutBlocks(visibleExercises);
    final blockIndex = indexOfBlockContaining(blocks, currentExerciseId, (e) => e.id);
    if (blockIndex == null || blockIndex >= blocks.length - 1) return null;
    final nextId = blocks[blockIndex + 1].first.id;
    final index = workoutExercises.indexWhere((e) => e.id == nextId);
    return index >= 0 ? index : null;
  }

  static bool hasPreviousBlock(List<WorkoutExercise> visible, String currentExerciseId) {
    final blocks = workoutBlocks(visible);
    final blockIndex = indexOfBlockContaining(blocks, currentExerciseId, (e) => e.id);
    return blockIndex != null && blockIndex > 0;
  }

  static bool hasNextBlock(List<WorkoutExercise> visible, String currentExerciseId) {
    final blocks = workoutBlocks(visible);
    final blockIndex = indexOfBlockContaining(blocks, currentExerciseId, (e) => e.id);
    return blockIndex != null && blockIndex < blocks.length - 1;
  }

  static int blockIndexOf(List<WorkoutExercise> visible, String currentExerciseId) {
    final blocks = workoutBlocks(visible);
    return indexOfBlockContaining(blocks, currentExerciseId, (e) => e.id) ?? 0;
  }
}
