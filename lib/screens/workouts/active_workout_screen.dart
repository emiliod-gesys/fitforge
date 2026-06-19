import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/supabase_datetime.dart';
import '../../core/utils/workout_streak.dart';
import '../../core/utils/exercise_load.dart';
import '../../core/utils/exercise_logging_resolver.dart';
import '../../core/utils/milestones.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/exercise_logging.dart';
import '../../models/workout.dart';
import '../../models/workout_summary.dart';
import '../../providers/app_providers.dart';
import '../../services/rest_preferences.dart';
import '../../services/rest_sound_service.dart';
import '../../services/exercise_service.dart';
import '../../widgets/exercise_history_sheet.dart';
import '../../widgets/exercise_image_viewer.dart';
import '../../widgets/exercise_thumbnail.dart';
import '../../widgets/localized_exercise_name.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/rest_time_selector.dart';
import '../../widgets/rest_timer.dart';
import '../../widgets/cardio_set_log_tile.dart';
import '../../widgets/set_log_tile.dart';
import '../../widgets/workout_elapsed_timer.dart';
import '../../widgets/active_workout_exercise_list.dart';
import '../../widgets/similar_exercise_picker_sheet.dart';
import '../../widgets/workout_exercise_picker_sheet.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  bool _showExerciseList = true;
  int _currentExerciseIndex = 0;
  bool _showRestTimer = false;
  int _restSeconds = 90;
  int _restTimerKey = 0;
  final Set<String> _removedSetIds = {};
  final Set<String> _removedExerciseIds = {};
  bool _completing = false;
  int _workoutSyncGeneration = 0;

  Future<void> _syncActiveWorkout() async {
    final generation = ++_workoutSyncGeneration;
    ref.invalidate(activeWorkoutProvider);
    await ref.read(activeWorkoutProvider.future);
    if (!mounted || generation != _workoutSyncGeneration) return;
    _pruneRemovedIds(ref.read(activeWorkoutProvider).valueOrNull);
  }

  void _pruneRemovedIds(Workout? workout) {
    if (workout == null) return;
    final exerciseIds = workout.exercises.map((e) => e.id).toSet();
    final setIds = workout.exercises.expand((e) => e.sets).map((s) => s.id).toSet();
    setState(() {
      _removedExerciseIds.removeWhere((id) => !exerciseIds.contains(id));
      _removedSetIds.removeWhere((id) => !setIds.contains(id));
    });
  }

  Future<bool> _confirmLeaveActiveWorkout() async {
    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.leaveActiveWorkoutTitle),
        content: Text(l10n.leaveActiveWorkoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.leaveActiveWorkoutConfirm),
          ),
        ],
      ),
    );
    return leave == true;
  }

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
    if (_completing) return;
    setState(() => _completing = true);

    try {
      final duration = SupabaseDateTime.nowUtc.difference(workout.startedAt.toUtc()).inMinutes;
      final catalog = ref.read(exercisesProvider).valueOrNull ?? [];
      final volume = workout.exercises.fold<double>(
        0,
        (sum, ex) => sum +
            ex.totalVolume(
              perArmWeight: ExerciseLoad.perArmWeightForExerciseId(ex.exerciseId, catalog),
            ),
      );

      final completedDates = await ref.read(workoutServiceProvider).getCompletedWorkoutTimestamps();
      final streakWeeks = WorkoutStreakCalculator.weeklyStreak([
        DateTime.now(),
        ...completedDates,
      ]);

      final profile = ref.read(profileProvider).valueOrNull;
      final bodyMetrics = await ref.read(bodyMetricSnapshotsProvider.future);
      final milestoneTotalsBefore = await ref
          .read(workoutServiceProvider)
          .getMilestoneTotals(profile: profile);

      await ref.read(workoutServiceProvider).completeWorkout(
            workout.id,
            durationMinutes: duration,
            totalVolume: volume,
          );

      final xpAward = await ref.read(profileServiceProvider).awardWorkoutXp(
            workoutId: workout.id,
            totalVolumeKg: volume,
            streakWeeks: streakWeeks,
          );

      final milestoneTotalsAfter = await ref
          .read(workoutServiceProvider)
          .getMilestoneTotals(profile: profile);
      final newMilestones = MilestonesCalculator.newlyUnlocked(
        milestoneTotalsBefore,
        milestoneTotalsAfter,
      );

      final previous = await ref.read(workoutServiceProvider).getPreviousRoutineWorkout(
            routineId: workout.routineId,
            excludeWorkoutId: workout.id,
          );

      final summary = WorkoutSummaryBuilder.build(
        workout: workout,
        durationMinutes: duration,
        previousSameRoutine: previous,
        xpAward: xpAward,
        exerciseCatalog: catalog,
        profile: profile,
        bodyMetrics: bodyMetrics,
        newMilestoneUnlocks: newMilestones,
      );

      ref.invalidate(workoutsProvider);
      ref.invalidate(recentWorkoutsProvider);
      ref.invalidate(workoutHistoryProvider);
      ref.invalidate(milestoneTotalsProvider);
      ref.invalidate(activeWorkoutProvider);
      ref.invalidate(personalRecordsProvider);
      ref.invalidate(muscleRecoveryProvider);
      ref.invalidate(workoutWeeklyStatsProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(friendRankingProvider);

      if (mounted) {
        context.pushReplacement('/workout/summary', extra: summary);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.finishFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _completing = false);
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

    final l10n = context.l10n;
    Workout? updated;

    try {
      updated = await FitForgeLoadingOverlay.run<Workout?>(
        context,
        message: l10n.addingExercise,
        task: () async {
          String? imageUrl;
          if (!picked.isUserCustom) {
            imageUrl = picked.imageUrl ??
                await ref.read(exerciseServiceProvider).resolveImageUrl(
                      ExerciseImageLookup(
                        exerciseId: picked.id,
                        exerciseName: picked.name,
                      ),
                    );
          }

          await ref.read(workoutServiceProvider).addExerciseToWorkout(
                workout.id,
                exerciseId: picked.id,
                exerciseName: picked.name,
                imageUrl: imageUrl,
                loggingType: picked.loggingType,
              );

          await _syncActiveWorkout();
          return ref.read(activeWorkoutProvider).valueOrNull;
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric('$e'))),
        );
      }
      return;
    }

    if (!mounted || updated == null) return;

    final newIndex = updated.exercises.length - 1;
    setState(() {
      _currentExerciseIndex = newIndex;
      _showExerciseList = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.exerciseAdded(picked.name))),
    );
  }

  Future<void> _removeExercise(WorkoutExercise exercise) async {
    try {
      await ref.read(workoutServiceProvider).removeExerciseFromWorkout(exercise.id);
      await _syncActiveWorkout();
      if (mounted) {
        setState(() {
          _clampExerciseIndex(
            ref.read(activeWorkoutProvider).valueOrNull?.exercises.length ?? 0,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.exerciseRemoved)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _removedExerciseIds.remove(exercise.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.exerciseDeleteFailed('$e'))),
        );
      }
    }
  }

  Future<void> _swapExercise(Workout workout, WorkoutExercise exercise) async {
    final excludeIds = workout.exercises
        .where((e) => e.id != exercise.id)
        .map((e) => e.exerciseId)
        .toSet();

    final picked = await SimilarExercisePickerSheet.show(
      context,
      current: exercise,
      excludeExerciseIds: excludeIds,
    );
    if (picked == null || !mounted) return;

    String? imageUrl;
    if (!picked.isUserCustom) {
      imageUrl = picked.imageUrl ??
          await ref.read(exerciseServiceProvider).resolveImageUrl(
                ExerciseImageLookup(
                  exerciseId: picked.id,
                  exerciseName: picked.name,
                ),
              );
    }

    await ref.read(workoutServiceProvider).swapExerciseInWorkout(
          exercise.id,
          workout.id,
          newExerciseId: picked.id,
          newExerciseName: picked.name,
          newImageUrl: imageUrl,
        );

    await _syncActiveWorkout();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.changedTo(picked.name))),
      );
    }
  }

  void _openExercise(int index) {
    setState(() {
      _currentExerciseIndex = index;
      _showExerciseList = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activeAsync = ref.watch(activeWorkoutProvider);
    final unitSystem = ref.watch(unitSystemProvider);
    final exerciseCatalog = ref.watch(exercisesProvider).valueOrNull ?? [];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmLeaveActiveWorkout() && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
      appBar: activeAsync.whenOrNull(
        data: (workout) {
          if (workout == null) return null;
          final visibleCount =
              workout.exercises.where((e) => !_removedExerciseIds.contains(e.id)).length;
          final inExerciseView = !_showExerciseList && visibleCount > 0;

          return FitForgeAppBar(
            title: l10n.training,
            showWordmark: !inExerciseView,
            automaticallyImplyLeading: false,
            leading: inExerciseView
                ? IconButton(
                    icon: const Icon(Icons.list),
                    tooltip: l10n.viewList,
                    onPressed: () => setState(() => _showExerciseList = true),
                  )
                : null,
            actions: [
              if (!_showExerciseList)
                IconButton(
                  tooltip: l10n.exerciseList,
                  onPressed: () => setState(() => _showExerciseList = true),
                  icon: const Icon(Icons.view_list_outlined),
                ),
              TextButton(
                onPressed: _completing ? null : () => _completeWorkout(workout),
                child: _completing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.finish),
              ),
            ],
          );
        },
      ) ?? FitForgeAppBar(title: l10n.training, automaticallyImplyLeading: false),
      body: activeAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        data: (workout) {
          if (workout == null) {
            if (activeAsync.isLoading || activeAsync.isRefreshing) {
              return const FitForgeLoadingScreen();
            }
            return Center(child: Text(l10n.noActiveWorkout));
          }

          final visibleExercises = workout.exercises
              .where((e) => !_removedExerciseIds.contains(e.id))
              .toList();

          if (_showExerciseList || visibleExercises.isEmpty) {
            return Column(
              children: [
                WorkoutElapsedTimer(startedAt: workout.startedAt),
                Expanded(
                  child: ActiveWorkoutExerciseList(
                    workout: workout,
                    removedExerciseIds: _removedExerciseIds,
                    unitSystem: unitSystem,
                    onOpenExercise: _openExercise,
                    onAddExercise: () => _pickAndAddExercise(workout),
                    onRemoveExercise: (exercise) {
                      setState(() => _removedExerciseIds.add(exercise.id));
                      unawaited(_removeExercise(exercise));
                    },
                    onSwapExercise: (exercise) => _swapExercise(workout, exercise),
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
          if (_removedExerciseIds.contains(exercise.id)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _showExerciseList = true);
            });
            return const FitForgeLoadingScreen();
          }
          final sortedSets = _sortedSets(exercise)
              .where((s) => !_removedSetIds.contains(s.id))
              .toList();
          final restSession = _restTimerKey;
          final isCardio = ExerciseLoggingResolver.isCardioExercise(
            exerciseId: exercise.exerciseId,
            exerciseName: exercise.exerciseName,
            catalog: exerciseCatalog,
            sets: sortedSets,
          );
          final cardioConfig = ExerciseLoggingResolver.cardioConfigFor(
            exerciseId: exercise.exerciseId,
            exerciseName: exercise.exerciseName,
            catalog: exerciseCatalog,
          );

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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    ExerciseThumbnail(
                      exerciseId: exercise.exerciseId,
                      exerciseName: exercise.exerciseName,
                      height: 160,
                      fullWidth: true,
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => ExerciseImageViewer.open(
                        context,
                        exerciseId: exercise.exerciseId,
                        exerciseName: exercise.exerciseName,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LocalizedExerciseName(
                      exercise.exerciseName,
                      exerciseId: exercise.exerciseId,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (!isCardio) ...[
                      RestTimeSelector(
                        selectedSeconds: _restSeconds,
                        onChanged: _onRestSecondsChanged,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton.filledTonal(
                        tooltip: l10n.exerciseHistory,
                        onPressed: () => ExerciseHistorySheet.show(
                          context,
                          exerciseId: exercise.exerciseId,
                          exerciseName: exercise.exerciseName,
                          excludeWorkoutId: workout.id,
                        ),
                        icon: const Icon(Icons.history),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...sortedSets.asMap().entries.map(
                      (entry) {
                        if (isCardio) {
                          return CardioSetLogTile(
                            key: ValueKey(entry.value.id),
                            set: entry.value,
                            unitSystem: unitSystem,
                            config: cardioConfig,
                            isLast: entry.key == sortedSets.length - 1,
                            onValidationError: (message) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            },
                            onChanged: (updated) => _logSet(
                              workout,
                              exercise,
                              updated,
                              wasAlreadyCompleted: entry.value.completed,
                              isCardio: true,
                              cardioConfig: cardioConfig,
                            ),
                            onDelete: () {
                              setState(() => _removedSetIds.add(entry.value.id));
                              unawaited(_deleteSet(workout, exercise, entry.value));
                            },
                          );
                        }
                        return SetLogTile(
                          key: ValueKey(entry.value.id),
                          set: entry.value,
                          unitSystem: unitSystem,
                          exerciseName: exercise.exerciseName,
                          perArmWeight: ExerciseLoad.perArmWeightForExerciseId(
                            exercise.exerciseId,
                            exerciseCatalog,
                          ),
                          isLast: entry.key == sortedSets.length - 1,
                          onValidationError: (message) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          },
                          onChanged: (updated) => _logSet(
                            workout,
                            exercise,
                            updated,
                            wasAlreadyCompleted: entry.value.completed,
                            isCardio: false,
                          ),
                          onDelete: () {
                            setState(() => _removedSetIds.add(entry.value.id));
                            unawaited(_deleteSet(workout, exercise, entry.value));
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _addSet(workout, exercise),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addSet),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: AppColors.orange),
                        foregroundColor: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              _ExerciseNavigator(
                l10n: l10n,
                currentIndex: visibleExercises.indexOf(exercise).clamp(0, visibleExercises.length - 1),
                total: visibleExercises.length,
                onPrevious: () {
                  final vi = visibleExercises.indexOf(exercise);
                  if (vi > 0) {
                    setState(() {
                      _currentExerciseIndex = workout.exercises.indexOf(visibleExercises[vi - 1]);
                    });
                  }
                },
                onNext: () {
                  final vi = visibleExercises.indexOf(exercise);
                  if (vi >= 0 && vi < visibleExercises.length - 1) {
                    setState(() {
                      _currentExerciseIndex = workout.exercises.indexOf(visibleExercises[vi + 1]);
                    });
                  }
                },
                hasPrevious: visibleExercises.indexOf(exercise) > 0,
                hasNext: visibleExercises.indexOf(exercise) < visibleExercises.length - 1,
              ),
            ],
          );
        },
        loading: () => const FitForgeLoadingScreen(),
        error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
      ),
    ),
    );
  }

  Future<void> _logSet(
    Workout workout,
    WorkoutExercise exercise,
    WorkoutSet set, {
    required bool wasAlreadyCompleted,
    required bool isCardio,
    CardioLoggingConfig? cardioConfig,
  }) async {
    if (!wasAlreadyCompleted) {
      if (isCardio) {
        final config = cardioConfig ??
            ExerciseLoggingResolver.cardioConfigFor(
              exerciseId: exercise.exerciseId,
              exerciseName: exercise.exerciseName,
              catalog: ref.read(exercisesProvider).valueOrNull ?? [],
            );
        if (!config.isSetComplete(
          durationSeconds: set.durationSeconds,
          distanceMeters: set.distanceMeters,
          inclinePercent: set.inclinePercent,
          steps: set.steps,
        )) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.cardioMetricRequired)),
            );
          }
          return;
        }
      } else {
        if (set.weight == null || set.weight! <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.weightRequired)),
            );
          }
          return;
        }
        if (set.reps <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.repsRequired)),
            );
          }
          return;
        }
      }
    }

    await ref.read(workoutServiceProvider).logSet(
          exercise.id,
          set.copyWith(
            completed: true,
            loggingType: isCardio ? ExerciseLoggingType.cardio : ExerciseLoggingType.strength,
          ),
        );
    await _syncActiveWorkout();

    if (!wasAlreadyCompleted && !isCardio) {
      _startRestTimer();
    }
  }

  Future<void> _deleteSet(
    Workout workout,
    WorkoutExercise exercise,
    WorkoutSet set,
  ) async {
    final setId = set.id;
    try {
      await ref.read(workoutServiceProvider).deleteSet(exercise.id, setId);
      await _syncActiveWorkout();
    } catch (e) {
      if (mounted) {
        setState(() => _removedSetIds.remove(setId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.setDeleteFailed('$e'))),
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

    final catalog = ref.read(exercisesProvider).valueOrNull ?? [];
    final isCardio = ExerciseLoggingResolver.isCardioExercise(
      exerciseId: exercise.exerciseId,
      exerciseName: exercise.exerciseName,
      catalog: catalog,
      sets: sorted,
    );

    final newSet = WorkoutSet(
      id: const Uuid().v4(),
      setNumber: sorted.length + 1,
      weight: isCardio ? null : prevSet?.weight,
      reps: isCardio ? 0 : (prevSet?.reps ?? 10),
      durationSeconds: isCardio ? prevSet?.durationSeconds : null,
      distanceMeters: isCardio ? prevSet?.distanceMeters : null,
      inclinePercent: isCardio ? prevSet?.inclinePercent : null,
      steps: isCardio ? prevSet?.steps : null,
      loggingType: isCardio ? ExerciseLoggingType.cardio : ExerciseLoggingType.strength,
    );
    await ref.read(workoutServiceProvider).logSet(exercise.id, newSet);
    await _syncActiveWorkout();
  }
}

class _ExerciseNavigator extends StatelessWidget {
  final AppLocalizations l10n;
  final int currentIndex;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool hasPrevious;
  final bool hasNext;

  const _ExerciseNavigator({
    required this.l10n,
    required this.currentIndex,
    required this.total,
    required this.hasPrevious,
    required this.hasNext,
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
              l10n.exerciseProgress(currentIndex + 1, total),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasPrevious ? onPrevious : null,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(l10n.previous),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasNext ? onNext : null,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(l10n.next),
                    iconAlignment: IconAlignment.end,
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
