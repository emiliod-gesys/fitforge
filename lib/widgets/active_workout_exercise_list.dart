import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/muscle_inference.dart';
import '../core/utils/unit_converter.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';
import '../models/workout.dart';
import 'exercise_thumbnail.dart';
import 'localized_exercise_name.dart';

class ActiveWorkoutExerciseList extends StatelessWidget {
  final Workout workout;
  final Set<String> removedExerciseIds;
  final String unitSystem;
  final void Function(int index) onOpenExercise;
  final VoidCallback onAddExercise;
  final void Function(WorkoutExercise exercise) onRemoveExercise;
  final void Function(WorkoutExercise exercise) onSwapExercise;

  const ActiveWorkoutExerciseList({
    super.key,
    required this.workout,
    required this.removedExerciseIds,
    required this.unitSystem,
    required this.onOpenExercise,
    required this.onAddExercise,
    required this.onRemoveExercise,
    required this.onSwapExercise,
  });

  List<WorkoutExercise> get _visibleExercises => workout.exercises
      .where((e) => !removedExerciseIds.contains(e.id))
      .toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  String _subtitle(WorkoutExercise exercise, AppLocalizations l10n) {
    final total = exercise.sets.length;
    final done = exercise.sets.where((s) => s.completed).length;
    if (total == 0) return l10n.noSets;
    if (done == total) return l10n.seriesCompleted(total);

    final lastCompleted = exercise.sets.where((s) => s.completed && s.weight != null).lastOrNull;
    if (lastCompleted != null) {
      final w = UnitConverter.kgToDisplay(lastCompleted.weight!, unitSystem);
      final label = UnitConverter.massLabel(unitSystem);
      return l10n.seriesWithWeight(
        total,
        '${w.toStringAsFixed(0)} $label',
        lastCompleted.reps,
      );
    }

    return l10n.seriesProgress(total, done);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final exercises = _visibleExercises;
    final muscleCount = exercises
        .expand((e) => MuscleInference.resolve(
              exerciseName: e.exerciseName,
              exerciseId: e.exerciseId,
            ))
        .toSet()
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          l10n.workoutDisplayName(workout.name),
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
        const SizedBox(height: 20),
        ...List.generate(exercises.length, (index) {
          final exercise = exercises[index];
          final isLast = index == exercises.length - 1;

          return _ExerciseListRow(
            exercise: exercise,
            subtitle: _subtitle(exercise, l10n),
            showConnector: !isLast,
            onTap: () => onOpenExercise(workout.exercises.indexOf(exercise)),
            onSwap: () => onSwapExercise(exercise),
            onRemove: () => onRemoveExercise(exercise),
          );
        }),
        const SizedBox(height: 8),
        _AddExerciseRow(onTap: onAddExercise),
      ],
    );
  }
}

class _ExerciseListRow extends ConsumerWidget {
  final WorkoutExercise exercise;
  final String subtitle;
  final bool showConnector;
  final VoidCallback onTap;
  final VoidCallback onSwap;
  final VoidCallback onRemove;

  const _ExerciseListRow({
    required this.exercise,
    required this.subtitle,
    required this.showConnector,
    required this.onTap,
    required this.onSwap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Dismissible(
      key: ValueKey('workout-ex-${exercise.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onRemove(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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
                      leading: const Icon(Icons.swap_horiz, color: AppColors.orange),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.orange.withValues(alpha: 0.5), width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: AppColors.orange),
            ),
            const SizedBox(width: 16),
            Text(
              l10n.addExercise,
              style: const TextStyle(
                color: AppColors.orange,
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
