import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/supabase_datetime.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../services/rest_preferences.dart';
import '../../services/rest_sound_service.dart';
import '../../widgets/exercise_history_sheet.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/rest_time_selector.dart';
import '../../widgets/rest_timer.dart';
import '../../widgets/set_log_tile.dart';
import '../../widgets/workout_elapsed_timer.dart';
import '../../widgets/workout_exercise_picker_sheet.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  int _currentExerciseIndex = 0;
  bool _showRestTimer = false;
  int _restSeconds = 90;
  int _restTimerKey = 0;
  final Set<String> _removedSetIds = {};

  @override
  void initState() {
    super.initState();
    RestPreferences.getDefaultRestSeconds().then((seconds) {
      if (mounted) setState(() => _restSeconds = seconds);
    });
  }

  List<WorkoutSet> _sortedSets(WorkoutExercise exercise) {
    return [...exercise.sets]..sort((a, b) => a.setNumber.compareTo(b.setNumber));
  }

  void _clampExerciseIndex(int total) {
    if (total == 0) {
      _currentExerciseIndex = 0;
    } else if (_currentExerciseIndex >= total) {
      _currentExerciseIndex = total - 1;
    }
  }

  Future<void> _completeWorkout(Workout workout) async {
    final duration = SupabaseDateTime.nowUtc.difference(workout.startedAt.toUtc()).inMinutes;
    final volume = workout.exercises.fold<double>(
      0,
      (sum, ex) => sum + ex.totalVolume,
    );

    await ref.read(workoutServiceProvider).completeWorkout(
          workout.id,
          durationMinutes: duration,
          totalVolume: volume,
        );

    ref.invalidate(workoutsProvider);
    ref.invalidate(recentWorkoutsProvider);
    ref.invalidate(workoutHistoryProvider);
    ref.invalidate(progressWorkoutsProvider);
    ref.invalidate(activeWorkoutProvider);
    ref.invalidate(personalRecordsProvider);
    ref.invalidate(muscleRecoveryProvider);
    ref.invalidate(workoutWeeklyStatsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Entrenamiento completado!')),
      );
      context.pop();
    }
  }

  void _onRestSecondsChanged(int seconds) {
    setState(() => _restSeconds = seconds);
    RestPreferences.setDefaultRestSeconds(seconds);
  }

  void _startRestTimer() {
    unawaited(RestSoundService.cancelBell());
    setState(() {
      _restTimerKey++;
      _showRestTimer = true;
    });
  }

  void _dismissRestTimer(int sessionId) {
    if (sessionId != _restTimerKey) return;
    setState(() => _showRestTimer = false);
  }

  Future<void> _pickAndAddExercise(Workout workout) async {
    final existingIds = workout.exercises.map((e) => e.exerciseId).toSet();
    final picked = await WorkoutExercisePickerSheet.show(
      context,
      excludeExerciseIds: existingIds,
    );
    if (picked == null || !mounted) return;

    await ref.read(workoutServiceProvider).addExerciseToWorkout(
          workout.id,
          exerciseId: picked.id,
          exerciseName: picked.name,
          imageUrl: picked.imageUrl,
        );

    ref.invalidate(activeWorkoutProvider);
    final updated = await ref.read(activeWorkoutProvider.future);
    if (!mounted || updated == null) return;

    setState(() => _currentExerciseIndex = updated.exercises.length - 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${picked.name} añadido')),
    );
  }

  Future<void> _removeCurrentExercise(Workout workout, WorkoutExercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar ejercicio'),
        content: Text('¿Quitar "${exercise.exerciseName}" de este entrenamiento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(workoutServiceProvider).removeExerciseFromWorkout(exercise.id);
    ref.invalidate(activeWorkoutProvider);
    final updated = await ref.read(activeWorkoutProvider.future);
    if (!mounted) return;

    setState(() => _clampExerciseIndex(updated?.exercises.length ?? 0));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ejercicio eliminado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(activeWorkoutProvider);
    final unitSystem = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: FitForgeAppBar(
        title: 'Entrenando',
        actions: [
          activeAsync.whenOrNull(
            data: (workout) => workout != null
                ? IconButton(
                    tooltip: 'Añadir ejercicio',
                    onPressed: () => _pickAndAddExercise(workout),
                    icon: const Icon(Icons.add_circle_outline),
                  )
                : null,
          ) ?? const SizedBox.shrink(),
          activeAsync.whenOrNull(
            data: (workout) => workout != null
                ? TextButton(
                    onPressed: () => _completeWorkout(workout),
                    child: const Text('Finalizar'),
                  )
                : null,
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: activeAsync.when(
        data: (workout) {
          if (workout == null) {
            return const Center(child: Text('No hay entrenamiento activo'));
          }

          if (workout.exercises.isEmpty) {
            return Column(
              children: [
                WorkoutElapsedTimer(startedAt: workout.startedAt),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'La rutina es solo una base.\nAñade los ejercicios que quieras.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _pickAndAddExercise(workout),
                            icon: const Icon(Icons.add),
                            label: const Text('Añadir ejercicio'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final exerciseIndex = _currentExerciseIndex.clamp(0, workout.exercises.length - 1);
          if (exerciseIndex != _currentExerciseIndex) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _currentExerciseIndex = exerciseIndex);
            });
          }
          final exercise = workout.exercises[exerciseIndex];
          final sortedSets = _sortedSets(exercise)
              .where((s) => !_removedSetIds.contains(s.id))
              .toList();
          final restSession = _restTimerKey;

          return Column(
            children: [
              WorkoutElapsedTimer(startedAt: workout.startedAt),
              if (_showRestTimer)
                RestTimer(
                  key: ValueKey(restSession),
                  sessionId: restSession,
                  seconds: _restSeconds,
                  onComplete: () => _dismissRestTimer(restSession),
                  onSkip: () => _dismissRestTimer(restSession),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (exercise.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          exercise.imageUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            exercise.exerciseName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Quitar ejercicio',
                          onPressed: () => _removeCurrentExercise(workout, exercise),
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RestTimeSelector(
                            selectedSeconds: _restSeconds,
                            onChanged: _onRestSecondsChanged,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: IconButton.filledTonal(
                            tooltip: 'Historial del ejercicio',
                            onPressed: () => ExerciseHistorySheet.show(
                              context,
                              exerciseId: exercise.exerciseId,
                              exerciseName: exercise.exerciseName,
                              excludeWorkoutId: workout.id,
                            ),
                            icon: const Icon(Icons.history),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...sortedSets.map(
                      (set) => SetLogTile(
                        key: ValueKey(set.id),
                        set: set,
                        unitSystem: unitSystem,
                        onChanged: (updated) => _logSet(
                          workout,
                          exercise,
                          updated,
                          wasAlreadyCompleted: set.completed,
                        ),
                        onDelete: () {
                          setState(() => _removedSetIds.add(set.id));
                          unawaited(_deleteSet(workout, exercise, set));
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _addSet(workout, exercise),
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir serie'),
                    ),
                  ],
                ),
              ),
              _ExerciseNavigator(
                currentIndex: exerciseIndex,
                total: workout.exercises.length,
                onPrevious: exerciseIndex > 0
                    ? () => setState(() => _currentExerciseIndex--)
                    : null,
                onNext: exerciseIndex < workout.exercises.length - 1
                    ? () => setState(() => _currentExerciseIndex++)
                    : null,
                onAddExercise: () => _pickAndAddExercise(workout),
              ),
            ],
          );
        },
        loading: () => const FitForgeLoadingScreen(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _logSet(
    Workout workout,
    WorkoutExercise exercise,
    WorkoutSet set, {
    required bool wasAlreadyCompleted,
  }) async {
    await ref.read(workoutServiceProvider).logSet(exercise.id, set.copyWith(completed: true));
    ref.invalidate(activeWorkoutProvider);

    if (!wasAlreadyCompleted) {
      _startRestTimer();
    }
  }

  Future<void> _deleteSet(
    Workout workout,
    WorkoutExercise exercise,
    WorkoutSet set,
  ) async {
    try {
      await ref.read(workoutServiceProvider).deleteSet(exercise.id, set.id);
      ref.invalidate(activeWorkoutProvider);
      if (mounted) {
        setState(() => _removedSetIds.remove(set.id));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _removedSetIds.remove(set.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar la serie: $e')),
        );
      }
    }
  }

  Future<void> _addSet(Workout workout, WorkoutExercise exercise) async {
    final sorted = _sortedSets(exercise);
    final previous = await ref.read(workoutServiceProvider).getPreviousSetsForExercise(
          exercise.exerciseId,
          excludeWorkoutId: workout.id,
        );
    final setIndex = sorted.length;
    final prevSet = sorted.isNotEmpty
        ? sorted.last
        : (previous != null && previous.isNotEmpty
            ? (setIndex < previous.length ? previous[setIndex] : previous.last)
            : null);

    final newSet = WorkoutSet(
      id: const Uuid().v4(),
      setNumber: sorted.length + 1,
      weight: prevSet?.weight,
      reps: prevSet?.reps ?? 10,
    );
    await ref.read(workoutServiceProvider).logSet(exercise.id, newSet);
    ref.invalidate(activeWorkoutProvider);
  }
}

class _ExerciseNavigator extends StatelessWidget {
  final int currentIndex;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onAddExercise;

  const _ExerciseNavigator({
    required this.currentIndex,
    required this.total,
    required this.onAddExercise,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ejercicio ${currentIndex + 1} de $total',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Anterior'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Siguiente'),
                    iconAlignment: IconAlignment.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAddExercise,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Añadir ejercicio'),
            ),
          ],
        ),
      ),
    );
  }
}
