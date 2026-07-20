import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/muscle_inference.dart';
import '../core/utils/gym_weight.dart';
import '../core/utils/unit_converter.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';
import '../models/workout.dart';
import 'exercise_thumbnail.dart';
import 'localized_exercise_name.dart';
import '../core/theme/app_accent.dart';

class ActiveWorkoutExerciseList extends StatefulWidget {
  final Workout workout;
  final Set<String> removedExerciseIds;
  final String unitSystem;
  final void Function(int index) onOpenExercise;
  final VoidCallback onAddExercise;
  final void Function(WorkoutExercise exercise) onRemoveExercise;
  final void Function(WorkoutExercise exercise) onSwapExercise;
  final void Function(List<String> orderedExerciseIds)? onReorderExercises;

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
  });

  @override
  State<ActiveWorkoutExerciseList> createState() => _ActiveWorkoutExerciseListState();
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

    // onReorderItem (Flutter 3.41+) already adjusts newIndex after removal.
    setState(() {
      final moved = _orderedExercises.removeAt(oldIndex);
      _orderedExercises.insert(newIndex, moved);
      _pendingOrderIds = _orderedExercises.map((e) => e.id).toList();
    });

    widget.onReorderExercises?.call(_pendingOrderIds!);
  }

  String _subtitle(WorkoutExercise exercise, AppLocalizations l10n) {
    final total = exercise.sets.length;
    final done = exercise.sets.where((s) => s.completed).length;
    if (total == 0) return l10n.noSets;
    if (done == total) return l10n.seriesCompleted(total);

    final lastCompleted = exercise.sets.where((s) => s.completed && s.weight != null).lastOrNull;
    if (lastCompleted != null) {
      final w = GymWeight.formatDisplay(lastCompleted.weight!, widget.unitSystem);
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
    final muscleCount = exercises
        .expand((e) => MuscleInference.resolve(
              exerciseName: e.exerciseName,
              exerciseId: e.exerciseId,
            ))
        .toSet()
        .length;
    final canReorder = widget.onReorderExercises != null && exercises.length > 1;

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
                  itemCount: exercises.length,
                  onReorderItem: _handleReorder,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    final isLast = index == exercises.length - 1;
                    return _ExerciseListRow(
                      key: ValueKey(exercise.id),
                      listIndex: index,
                      exercise: exercise,
                      subtitle: _subtitle(exercise, l10n),
                      isCompleted: _isExerciseCompleted(exercise),
                      showConnector: !isLast,
                      showDragHandle: true,
                      onTap: () {
                        final index = widget.workout.exercises.indexWhere((e) => e.id == exercise.id);
                        if (index >= 0) widget.onOpenExercise(index);
                      },
                      onSwap: () => widget.onSwapExercise(exercise),
                      onRemove: () => widget.onRemoveExercise(exercise),
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    final isLast = index == exercises.length - 1;
                    return _ExerciseListRow(
                      key: ValueKey(exercise.id),
                      listIndex: index,
                      exercise: exercise,
                      subtitle: _subtitle(exercise, l10n),
                      isCompleted: _isExerciseCompleted(exercise),
                      showConnector: !isLast,
                      showDragHandle: false,
                      onTap: () {
                        final index = widget.workout.exercises.indexWhere((e) => e.id == exercise.id);
                        if (index >= 0) widget.onOpenExercise(index);
                      },
                      onSwap: () => widget.onSwapExercise(exercise),
                      onRemove: () => widget.onRemoveExercise(exercise),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _AddExerciseRow(onTap: widget.onAddExercise),
          ),
        ),
      ],
    );
  }
}

class _ExerciseListRow extends ConsumerWidget {
  static const _completedGreen = Color(0xFF22C55E);

  final int listIndex;
  final WorkoutExercise exercise;
  final String subtitle;
  final bool isCompleted;
  final bool showConnector;
  final bool showDragHandle;
  final VoidCallback onTap;
  final VoidCallback onSwap;
  final VoidCallback onRemove;

  const _ExerciseListRow({
    super.key,
    required this.listIndex,
    required this.exercise,
    required this.subtitle,
    required this.isCompleted,
    required this.showConnector,
    required this.showDragHandle,
    required this.onTap,
    required this.onSwap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDragHandle)
                ReorderableDragStartListener(
                  index: listIndex,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, right: 4),
                    child: Icon(
                      Icons.drag_handle,
                      color: AppColors.textMuted.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              SizedBox(
                width: 64,
                child: Column(
                  children: [
                    ExerciseThumbnail(
                      exerciseId: exercise.exerciseId,
                      exerciseName: exercise.exerciseName,
                      width: 56,
                      height: 56,
                    ),
                    if (showConnector)
                      Container(
                        width: 2,
                        height: 28,
                        margin: const EdgeInsets.only(top: 4),
                        color: AppColors.border,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedExerciseName(
                        exercise.exerciseName,
                        exerciseId: exercise.exerciseId,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              subtitle,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ),
                          if (isCompleted) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: _completedGreen,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
                onSelected: (value) {
                  switch (value) {
                    case 'swap':
                      onSwap();
                    case 'remove':
                      onRemove();
                  }
                },
                itemBuilder: (_) => [
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
                      leading: const Icon(Icons.delete_outline, color: AppColors.error),
                      title: Text(l10n.remove),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                border: Border.all(color: context.accentColor.withValues(alpha: 0.5), width: 1.5),
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
