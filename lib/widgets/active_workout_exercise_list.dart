import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/muscle_inference.dart';
import '../core/utils/gym_weight.dart';
import '../core/utils/superset_groups.dart';
import '../core/utils/unit_converter.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';
import '../models/workout.dart';
import 'exercise_thumbnail.dart';
import 'localized_exercise_name.dart';
import '../core/theme/app_accent.dart';
import '../core/tutorials/tutorial_targets.dart';

class ActiveWorkoutExerciseList extends StatefulWidget {
  final Workout workout;
  final Set<String> removedExerciseIds;
  final String unitSystem;
  final void Function(int index) onOpenExercise;
  final VoidCallback onAddExercise;
  final void Function(WorkoutExercise exercise) onRemoveExercise;
  final void Function(WorkoutExercise exercise) onSwapExercise;
  final void Function(List<String> orderedExerciseIds)? onReorderExercises;
  final bool Function(WorkoutExercise exercise)? isCardioExercise;
  final void Function(int blockIndex, List<WorkoutExercise> orderedExercises)?
      onJoinSuperset;
  final void Function(WorkoutExercise exercise)? onLeaveSuperset;

  const ActiveWorkoutExerciseList({
    super.key,
    required this.workout,
    required this.removedExerciseIds,
    required this.unitSystem,
    required this.onOpenExercise,
    required this.onAddExercise,
    required this.onRemoveExercise,
    required this.onSwapExercise,
    this.onReorderExercises,
    this.isCardioExercise,
    this.onJoinSuperset,
    this.onLeaveSuperset,
  });

  @override
  State<ActiveWorkoutExerciseList> createState() =>
      _ActiveWorkoutExerciseListState();
}

class _ActiveWorkoutExerciseListState extends State<ActiveWorkoutExerciseList> {
  late List<WorkoutExercise> _orderedExercises;
  List<String>? _pendingOrderIds;

  @override
  void initState() {
    super.initState();
    _orderedExercises = _visibleFromWidget();
  }

  @override
  void didUpdateWidget(ActiveWorkoutExerciseList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final fromWorkout = _visibleFromWidget();
    final workoutIds = fromWorkout.map((e) => e.id).toList();
    final localIds = _orderedExercises.map((e) => e.id).toList();

    if (_exerciseIdsChanged(localIds, workoutIds)) {
      setState(() {
        _orderedExercises = fromWorkout;
        _pendingOrderIds = null;
      });
      return;
    }

    if (_pendingOrderIds != null) {
      if (_idsEqual(workoutIds, _pendingOrderIds!)) {
        setState(() {
          _pendingOrderIds = null;
          _orderedExercises = fromWorkout;
        });
      }
      return;
    }

    if (!_idsEqual(workoutIds, localIds)) {
      setState(() => _orderedExercises = fromWorkout);
    } else {
      final merged = _mergeExerciseData(fromWorkout);
      if (merged != _orderedExercises) {
        setState(() => _orderedExercises = merged);
      }
    }
  }

  List<WorkoutExercise> _mergeExerciseData(List<WorkoutExercise> fromWorkout) {
    final byId = {for (final e in fromWorkout) e.id: e};
    return _orderedExercises
        .map((e) => byId[e.id])
        .whereType<WorkoutExercise>()
        .toList();
  }

  List<WorkoutExercise> _visibleFromWidget() {
    return widget.workout.exercises
        .where((e) => !widget.removedExerciseIds.contains(e.id))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  bool _idsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _exerciseIdsChanged(List<String> localIds, List<String> workoutIds) {
    final localSet = localIds.toSet();
    final workoutSet = workoutIds.toSet();
    return localSet.length != workoutSet.length ||
        !localSet.containsAll(workoutSet) ||
        !workoutSet.containsAll(localSet);
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    final blocks = SupersetGroups.workoutBlocks(_orderedExercises);
    if (oldIndex < 0 || oldIndex >= blocks.length) return;
    if (newIndex < 0 || newIndex >= blocks.length) return;

    setState(() {
      final moved = blocks.removeAt(oldIndex);
      blocks.insert(newIndex, moved);
      _orderedExercises = [for (final block in blocks) ...block];
      _pendingOrderIds = _orderedExercises.map((e) => e.id).toList();
    });

    widget.onReorderExercises?.call(_pendingOrderIds!);
  }

  String _subtitle(WorkoutExercise exercise, AppLocalizations l10n) {
    final total = exercise.sets.length;
    final done = exercise.sets.where((s) => s.completed).length;
    if (total == 0) return l10n.noSets;
    if (done == total) return l10n.seriesCompleted(total);

    final lastCompleted =
        exercise.sets.where((s) => s.completed && s.weight != null).lastOrNull;
    if (lastCompleted != null) {
      final w =
          GymWeight.formatDisplay(lastCompleted.weight!, widget.unitSystem);
      final label = UnitConverter.massLabel(widget.unitSystem);
      return l10n.seriesWithWeight(
        total,
        '$w $label',
        lastCompleted.reps,
      );
    }

    return l10n.seriesProgress(total, done);
  }

  bool _isExerciseCompleted(WorkoutExercise exercise) {
    final total = exercise.sets.length;
    if (total == 0) return false;
    return exercise.sets.where((s) => s.completed).length == total;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final exercises = _orderedExercises;
    final blocks = SupersetGroups.workoutBlocks(exercises);
    final muscleCount = exercises
        .expand((e) => MuscleInference.resolve(
              exerciseName: e.exerciseName,
              exerciseId: e.exerciseId,
            ))
        .toSet()
        .length;
    final canReorder = widget.onReorderExercises != null && blocks.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.workoutDisplayName(widget.workout.name),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                muscleCount > 0
                    ? l10n.exercisesAndMuscles(exercises.length, muscleCount)
                    : l10n.exercisesInRoutine(exercises.length),
                style: const TextStyle(color: AppColors.textMuted),
              ),
              if (canReorder) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.reorderExercise,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: canReorder
              ? ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      color: AppColors.card,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    );
                  },
                  itemCount: blocks.length,
                  onReorderItem: _handleReorder,
                  itemBuilder: (context, index) => _buildBlockRow(
                    context,
                    l10n: l10n,
                    block: blocks[index],
                    listIndex: index,
                    isLast: index == blocks.length - 1,
                    showDragHandle: true,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: blocks.length,
                  itemBuilder: (context, index) => _buildBlockRow(
                    context,
                    l10n: l10n,
                    block: blocks[index],
                    listIndex: index,
                    isLast: index == blocks.length - 1,
                    showDragHandle: false,
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: KeyedSubtree(
              key: TutorialTargets.workoutAddExerciseKey,
              child: _AddExerciseRow(onTap: widget.onAddExercise),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockRow(
    BuildContext context, {
    required AppLocalizations l10n,
    required List<WorkoutExercise> block,
    required int listIndex,
    required bool isLast,
    required bool showDragHandle,
  }) {
    final canJoin = widget.onJoinSuperset != null &&
        SupersetGroups.canJoinWorkoutBlockWithNext(
          _orderedExercises,
          listIndex,
          isCardio: widget.isCardioExercise,
        );

    if (block.length < 2) {
      final exercise = block.first;
      final done = exercise.sets.where((s) => s.completed).length;
      return _ExerciseListRow(
        key: ValueKey(exercise.id),
        listIndex: listIndex,
        exercise: exercise,
        subtitle: _subtitle(exercise, l10n),
        doneSets: done,
        totalSets: exercise.sets.length,
        isCompleted: _isExerciseCompleted(exercise),
        showConnector: !isLast,
        showDragHandle: showDragHandle,
        onTap: () {
          final index =
              widget.workout.exercises.indexWhere((e) => e.id == exercise.id);
          if (index >= 0) widget.onOpenExercise(index);
        },
        onSwap: () => widget.onSwapExercise(exercise),
        onRemove: () => widget.onRemoveExercise(exercise),
        onJoin: canJoin
            ? () => widget.onJoinSuperset!(listIndex, _orderedExercises)
            : null,
      );
    }

    return _SupersetListRow(
      key: ValueKey(block.first.supersetGroupId ?? block.first.id),
      listIndex: listIndex,
      members: block,
      showConnector: !isLast,
      showDragHandle: showDragHandle,
      onTap: () {
        final active = SupersetGroups.activeMember(block) ?? block.first;
        final index =
            widget.workout.exercises.indexWhere((e) => e.id == active.id);
        if (index >= 0) widget.onOpenExercise(index);
      },
      onRemoveMember: widget.onRemoveExercise,
      onJoin: canJoin
          ? () => widget.onJoinSuperset!(listIndex, _orderedExercises)
          : null,
      onLeaveMember: widget.onLeaveSuperset,
    );
  }
}

class _ExerciseListRow extends ConsumerWidget {
  static const _completedGreen = Color(0xFF22C55E);

  final int listIndex;
  final WorkoutExercise exercise;
  final String subtitle;
  final int doneSets;
  final int totalSets;
  final bool isCompleted;
  final bool showConnector;
  final bool showDragHandle;
  final VoidCallback onTap;
  final VoidCallback onSwap;
  final VoidCallback onRemove;
  final VoidCallback? onJoin;

  const _ExerciseListRow({
    super.key,
    required this.listIndex,
    required this.exercise,
    required this.subtitle,
    required this.doneSets,
    required this.totalSets,
    required this.isCompleted,
    required this.showConnector,
    required this.showDragHandle,
    required this.onTap,
    required this.onSwap,
    required this.onRemove,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final progress =
        totalSets <= 0 ? 0.0 : (doneSets / totalSets).clamp(0.0, 1.0);
    final ringColor = isCompleted ? _completedGreen : context.accentColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      splashColor: context.accentColor.withValues(alpha: 0.08),
      highlightColor: context.accentColor.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showDragHandle)
              ReorderableDragStartListener(
                index: listIndex,
                child: KeyedSubtree(
                  key:
                      listIndex == 0 ? TutorialTargets.workoutReorderKey : null,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.drag_handle,
                      color: AppColors.textMuted.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: 58,
              child: Column(
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: Stack(
                      clipBehavior: Clip.none,
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.45),
                              width: 3,
                            ),
                          ),
                        ),
                        CustomPaint(
                          painter: _RoundedRectProgressPainter(
                            progress: totalSets == 0 ? 0 : progress,
                            strokeWidth: 3,
                            borderRadius: 11,
                            color: ringColor,
                          ),
                        ),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ExerciseThumbnail(
                              exerciseId: exercise.exerciseId,
                              exerciseName: exercise.exerciseName,
                              width: 50,
                              height: 50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: _completedGreen,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (showConnector)
                    Container(
                      width: 2,
                      height: 14,
                      margin: const EdgeInsets.only(top: 4),
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedExerciseName(
                    exercise.exerciseName,
                    exerciseId: exercise.exerciseId,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                  if (onJoin != null)
                    TextButton.icon(
                      onPressed: onJoin,
                      icon: const Icon(Icons.link, size: 16),
                      label: Text(l10n.joinSuperset),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              key: listIndex == 0 ? TutorialTargets.workoutSwapKey : null,
              icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
              onSelected: (value) {
                switch (value) {
                  case 'join':
                    onJoin?.call();
                  case 'swap':
                    onSwap();
                  case 'remove':
                    onRemove();
                }
              },
              itemBuilder: (_) => [
                if (onJoin != null)
                  PopupMenuItem(
                    value: 'join',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.link, color: context.accentColor),
                      title: Text(l10n.joinSuperset),
                    ),
                  ),
                PopupMenuItem(
                  value: 'swap',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.swap_horiz, color: context.accentColor),
                    title: Text(l10n.swapSimilar),
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    title: Text(l10n.remove),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Progreso como trazo alrededor de un rectángulo redondeado (misma forma que la miniatura).
class _RoundedRectProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final double borderRadius;
  final Color color;

  const _RoundedRectProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.borderRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || progress <= 0) return;

    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
        inset, inset, size.width - strokeWidth, size.height - strokeWidth);
    final radius = borderRadius.clamp(0.0, rect.shortestSide / 2);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    if (progress >= 1) {
      canvas.drawRRect(rrect, fgPaint);
      return;
    }

    final path = Path()..addRRect(rrect);
    // PathMetrics es de un solo uso: materializar antes de leer.
    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) return;

    final end = metrics.first.length * progress.clamp(0.0, 1.0);
    if (end <= 0) return;

    canvas.drawPath(metrics.first.extractPath(0, end), fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RoundedRectProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _SupersetListRow extends ConsumerWidget {
  static const _completedGreen = Color(0xFF22C55E);

  final int listIndex;
  final List<WorkoutExercise> members;
  final bool showConnector;
  final bool showDragHandle;
  final VoidCallback onTap;
  final void Function(WorkoutExercise exercise) onRemoveMember;
  final VoidCallback? onJoin;
  final void Function(WorkoutExercise exercise)? onLeaveMember;

  const _SupersetListRow({
    super.key,
    required this.listIndex,
    required this.members,
    required this.showConnector,
    required this.showDragHandle,
    required this.onTap,
    required this.onRemoveMember,
    this.onJoin,
    this.onLeaveMember,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final totalRounds = SupersetGroups.roundCount(members);
    final doneRounds = SupersetGroups.completedRounds(members);
    final progress =
        totalRounds <= 0 ? 0.0 : (doneRounds / totalRounds).clamp(0.0, 1.0);
    final isCompleted = totalRounds > 0 && doneRounds == totalRounds;
    final ringColor = isCompleted ? _completedGreen : context.accentColor;
    final names = members.map((m) => m.exerciseName).join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      splashColor: context.accentColor.withValues(alpha: 0.08),
      highlightColor: context.accentColor.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showDragHandle)
              ReorderableDragStartListener(
                index: listIndex,
                child: KeyedSubtree(
                  key:
                      listIndex == 0 ? TutorialTargets.workoutReorderKey : null,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.drag_handle,
                      color: AppColors.textMuted.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: 58,
              child: Column(
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: Stack(
                      clipBehavior: Clip.none,
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.45),
                              width: 3,
                            ),
                          ),
                        ),
                        CustomPaint(
                          painter: _RoundedRectProgressPainter(
                            progress: totalRounds == 0 ? 0 : progress,
                            strokeWidth: 3,
                            borderRadius: 11,
                            color: ringColor,
                          ),
                        ),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < members.length; i++)
                                Padding(
                                  padding:
                                      EdgeInsets.only(left: i == 0 ? 0 : 2),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        SupersetGroups.slotLetter(
                                            members[i].supersetSlot ?? (i + 1)),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: context.accentColor,
                                        ),
                                      ),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: ExerciseThumbnail(
                                          exerciseId: members[i].exerciseId,
                                          exerciseName: members[i].exerciseName,
                                          width: 16,
                                          height: 16,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isCompleted)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: _completedGreen,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (showConnector)
                    Container(
                      width: 2,
                      height: 14,
                      margin: const EdgeInsets.only(top: 4),
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.groupedSetKind(members.length),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    names,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalRounds == 0
                        ? l10n.noSets
                        : l10n.supersetRound(
                            SupersetGroups.currentRound(members),
                            totalRounds,
                          ),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                  if (onJoin != null)
                    TextButton.icon(
                      onPressed: onJoin,
                      icon: const Icon(Icons.link, size: 16),
                      label: Text(l10n.joinSuperset),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              key: listIndex == 0 ? TutorialTargets.workoutSwapKey : null,
              icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
              onSelected: (value) {
                if (value == 'join') {
                  onJoin?.call();
                  return;
                }
                if (value.startsWith('leave:')) {
                  final id = value.substring(6);
                  for (final member in members) {
                    if (member.id == id) {
                      onLeaveMember?.call(member);
                      break;
                    }
                  }
                  return;
                }
                if (value.startsWith('remove:')) {
                  final id = value.substring(7);
                  for (final member in members) {
                    if (member.id == id) {
                      onRemoveMember(member);
                      break;
                    }
                  }
                }
              },
              itemBuilder: (_) => [
                if (onJoin != null)
                  PopupMenuItem(
                    value: 'join',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.link, color: context.accentColor),
                      title: Text(l10n.joinSuperset),
                    ),
                  ),
                if (onLeaveMember != null)
                  for (final member in members)
                    PopupMenuItem(
                      value: 'leave:${member.id}',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.link_off),
                        title: Text(
                            '${l10n.leaveGroupedSet(members.length)}: ${member.exerciseName}'),
                      ),
                    ),
                for (final member in members)
                  PopupMenuItem(
                    value: 'remove:${member.id}',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                      title: Text('${l10n.remove} ${member.exerciseName}'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExerciseRow extends StatelessWidget {
  final VoidCallback onTap;

  const _AddExerciseRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(
                    color: context.accentColor.withValues(alpha: 0.5),
                    width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add, color: context.accentColor),
            ),
            const SizedBox(width: 16),
            Text(
              l10n.addExercise,
              style: TextStyle(
                color: context.accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
