import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/supabase_datetime.dart';
import '../../core/utils/workout_exercise_navigation.dart';
import '../../core/utils/workout_calorie_estimator.dart';
import '../../core/utils/workout_streak.dart';
import '../../core/utils/exercise_load.dart';
import '../../core/utils/exercise_logging_resolver.dart';
import '../../core/utils/milestones.dart';
import '../../core/utils/session_personal_records.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/exercise_logging.dart';
import '../../models/watch_session.dart';
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
import '../../widgets/rir_picker_sheet.dart';
import '../../widgets/cardio_set_log_tile.dart';
import '../../widgets/set_log_tile.dart';
import '../../widgets/workout_exercise_picker_sheet.dart';
import '../../widgets/workout_elapsed_timer.dart';
import '../../widgets/active_workout_exercise_list.dart';
import '../../widgets/similar_exercise_picker_sheet.dart';
import '../../services/exercise_report_service.dart';
import '../../widgets/exercise_load_controls.dart';
import '../../widgets/exercise_report_sheet.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen>
    with WidgetsBindingObserver {
  bool _showExerciseList = true;
  int _currentExerciseIndex = 0;
  bool _showRestTimer = false;
  int _restSeconds = 90;
  int _restTimerKey = 0;
  final Set<String> _removedSetIds = {};
  final Set<String> _removedExerciseIds = {};
  bool _completing = false;
  int _workoutSyncGeneration = 0;
  final RestTimerController _restTimerController = RestTimerController();
  DateTime? _restEndsAt;
  int? _restTotalSeconds;
  final Map<String, WorkoutSet> _setOverrides = {};
  final Map<String, List<WorkoutSet>> _insertedSets = {};
  final Set<String> _savingSetIds = {};
  final Map<String, bool> _perArmOverrides = {};

  Workout _mergedWorkout(Workout workout) {
    if (_setOverrides.isEmpty && _insertedSets.isEmpty) return workout;

    final exercises = workout.exercises.map((exercise) {
      var sets = exercise.sets
          .map((set) => _setOverrides[set.id] ?? set)
          .toList();
      final pending = _insertedSets[exercise.id];
      if (pending != null) {
        for (final set in pending) {
          if (!sets.any((s) => s.id == set.id)) sets.add(set);
        }
        sets.sort((a, b) => a.setNumber.compareTo(b.setNumber));
      }
      return WorkoutExercise(
        id: exercise.id,
        exerciseId: exercise.exerciseId,
        exerciseName: exercise.exerciseName,
        imageUrl: exercise.imageUrl,
        orderIndex: exercise.orderIndex,
        sets: sets,
        notes: exercise.notes,
      );
    }).toList();

    return Workout(
      id: workout.id,
      userId: workout.userId,
      routineId: workout.routineId,
      routineName: workout.routineName,
      name: workout.name,
      startedAt: workout.startedAt,
      completedAt: workout.completedAt,
      durationMinutes: workout.durationMinutes,
      activeCaloriesKcal: workout.activeCaloriesKcal,
      exercises: exercises,
      notes: workout.notes,
      totalVolume: workout.totalVolume,
    );
  }

  void _clearSetOptimism(String setId, {String? exerciseId}) {
    _setOverrides.remove(setId);
    _savingSetIds.remove(setId);
    if (exerciseId != null) {
      final pending = _insertedSets[exerciseId];
      if (pending != null) {
        pending.removeWhere((s) => s.id == setId);
        if (pending.isEmpty) _insertedSets.remove(exerciseId);
      }
    }
  }

  Future<void> _refreshActiveWorkoutAfterSet(String setId, {String? exerciseId}) async {
    final generation = ++_workoutSyncGeneration;
    ref.invalidate(activeWorkoutProvider);
    try {
      await ref.read(activeWorkoutProvider.future);
      if (!mounted || generation != _workoutSyncGeneration) return;
      setState(() => _clearSetOptimism(setId, exerciseId: exerciseId));
      final workout = ref.read(activeWorkoutProvider).valueOrNull;
      _pruneRemovedIds(workout);
      if (workout != null) {
        await _publishWatchSession(_mergedWorkout(workout));
      }
    } catch (_) {
      // La UI optimista sigue visible; el guardado en servidor ya se intentó.
    }
  }

  Future<void> _persistSet(
    WorkoutExercise exercise,
    WorkoutSet completedSet, {
    required String setId,
  }) async {
    try {
      await ref.read(workoutServiceProvider).logSet(exercise.id, completedSet);
      if (!mounted) return;
      setState(() => _savingSetIds.remove(setId));
      unawaited(_refreshActiveWorkoutAfterSet(setId, exerciseId: exercise.id));
    } catch (e) {
      if (!mounted) return;
      setState(() => _clearSetOptimism(setId, exerciseId: exercise.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorGeneric('$e'))),
      );
    }
  }

  Future<void> _publishWatchSession([Workout? workout]) async {
    final coordinator = ref.read(watchWorkoutCoordinatorProvider);
    workout ??= ref.read(activeWorkoutProvider).valueOrNull;
    if (workout != null) workout = _mergedWorkout(workout);
    if (workout == null || _showExerciseList) {
      await coordinator.clear();
      return;
    }

    if (workout.exercises.isEmpty) {
      await coordinator.clear();
      return;
    }

    final exerciseIndex =
        _currentExerciseIndex.clamp(0, workout.exercises.length - 1);
    final exercise = workout.exercises[exerciseIndex];
    if (_removedExerciseIds.contains(exercise.id)) {
      await coordinator.clear();
      return;
    }

    await coordinator.syncFromWorkout(
      workout: workout,
      exercise: exercise,
      unitSystem: ref.read(unitSystemProvider),
      removedSetIds: _removedSetIds,
      restEndsAt: _showRestTimer ? _restEndsAt : null,
      restTotalSeconds: _showRestTimer ? _restTotalSeconds : null,
    );
  }

  Future<void> _handleWatchAction(WatchWorkoutAction action) async {
    if (!mounted) return;
    final raw = ref.read(activeWorkoutProvider).valueOrNull;
    if (raw == null) return;
    final workout = _mergedWorkout(raw);

    switch (action.type) {
      case WatchActionType.skipRest:
        if (_showRestTimer) _restTimerController.skip();
      case WatchActionType.adjustRest:
        final delta = action.deltaSeconds;
        if (_showRestTimer && delta != null) {
          _restTimerController.adjust(delta);
          setState(() {
            _restEndsAt = (_restEndsAt ?? DateTime.now()).add(Duration(seconds: delta));
          });
          await _publishWatchSession(workout);
        }
      case WatchActionType.completeSet:
        await _completeSetFromWatch(workout);
      case WatchActionType.updateSet:
        break;
    }
  }

  Future<void> _completeSetFromWatch(Workout workout) async {
    final setId = ref.read(watchWorkoutCoordinatorProvider).lastSnapshot?.setId;
    if (setId == null) return;

    for (final exercise in workout.exercises) {
      for (final set in exercise.sets) {
        if (set.id != setId || set.completed) continue;

        final catalog = ref.read(exercisesProvider).valueOrNull ?? [];
        final isCardio = ExerciseLoggingResolver.isCardioExercise(
          exerciseId: exercise.exerciseId,
          exerciseName: exercise.exerciseName,
          catalog: catalog,
          sets: _sortedSets(exercise),
        );
        if (isCardio) return;

        final sorted = _sortedSets(exercise);
        final isLastSet = sorted.isNotEmpty && sorted.last.id == set.id;

        await _logSet(
          workout,
          exercise,
          set,
          wasAlreadyCompleted: false,
          isCardio: false,
          isLastSet: isLastSet,
        );
        return;
      }
    }
  }

  Future<void> _syncActiveWorkout() async {
    final generation = ++_workoutSyncGeneration;
    ref.invalidate(activeWorkoutProvider);
    await ref.read(activeWorkoutProvider.future);
    if (!mounted || generation != _workoutSyncGeneration) return;
    final workout = ref.read(activeWorkoutProvider).valueOrNull;
    _pruneRemovedIds(workout);
    await _publishWatchSession(workout);
  }

  void _pruneRemovedIds(Workout? workout) {
    if (workout == null) return;
    final exerciseIds = workout.exercises.map((e) => e.id).toSet();
    final setIds = workout.exercises.expand((e) => e.sets).map((s) => s.id).toSet();
    final staleExercises = _removedExerciseIds.any((id) => !exerciseIds.contains(id));
    final staleSets = _removedSetIds.any((id) => !setIds.contains(id));
    if (!staleExercises && !staleSets) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _removedExerciseIds.removeWhere((id) => !exerciseIds.contains(id));
        _removedSetIds.removeWhere((id) => !setIds.contains(id));
      });
    });
  }

  void _invalidateWorkoutProviders() {
    ref.invalidate(workoutsProvider);
    ref.invalidate(recentWorkoutsProvider);
    ref.invalidate(workoutHistoryProvider);
    ref.invalidate(milestoneTotalsProvider);
    ref.invalidate(activeWorkoutProvider);
    ref.invalidate(personalRecordsProvider);
    ref.invalidate(muscleRecoveryProvider);
    ref.invalidate(workoutWeeklyStatsProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(leaderboardProvider);
    ref.invalidate(dailyNutritionProvider);
    ref.invalidate(foodEntriesProvider);
    ref.invalidate(foodDayWorkoutsProvider);
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
    WidgetsBinding.instance.addObserver(this);
    RestPreferences.getDefaultRestSeconds().then((seconds) {
      if (mounted) setState(() => _restSeconds = seconds);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(watchWorkoutCoordinatorProvider).attach(_handleWatchAction);
      unawaited(_publishWatchSession());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(watchWorkoutCoordinatorProvider).detach();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reconcileRestTimerOnResume();
    }
  }

  void _reconcileRestTimerOnResume() {
    if (!_showRestTimer) return;
    final endsAt = _restEndsAt;
    if (endsAt != null && !endsAt.isAfter(DateTime.now())) {
      _dismissRestTimer(_restTimerKey);
    }
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

  Future<void> _cancelWorkout(Workout workout) async {
    if (_completing) return;

    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelWorkoutTitle),
        content: Text(l10n.cancelWorkoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelWorkoutBack),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.cancelWorkoutConfirm),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _completing = true);
    try {
      await ref.read(workoutServiceProvider).cancelWorkout(workout.id);
      await ref.read(watchWorkoutCoordinatorProvider).clear();
      ref.invalidate(activeWorkoutProvider);
      ref.invalidate(workoutsProvider);
      ref.invalidate(recentWorkoutsProvider);
      ref.invalidate(workoutHistoryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.workoutCancelled)),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cancelWorkoutFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _completeWorkout(Workout workout) async {
    if (_completing) return;
    setState(() => _completing = true);

    try {
      final duration = SupabaseDateTime.nowUtc.difference(workout.startedAt.toUtc()).inMinutes;
      final catalog = ref.read(exercisesProvider).valueOrNull ?? [];
      final profile = ref.read(profileProvider).valueOrNull;
      final bodyWeightKg = profile?.bodyWeight;
      final volume = workout.exercises.fold<double>(
        0,
        (sum, ex) =>
            sum +
            ExerciseLoad.exerciseTotalVolumeKg(
              ex,
              catalog: catalog,
              perArmOverrides: _perArmOverrides,
              bodyWeightKg: bodyWeightKg,
            ),
      );
      final completedDates = await ref.read(workoutServiceProvider).getCompletedWorkoutTimestamps();
      final streakWeeks = WorkoutStreakCalculator.weeklyStreak([
        DateTime.now(),
        ...completedDates,
      ]);
      final bodyMetrics = await ref.read(bodyMetricSnapshotsProvider.future);
      final calorieEstimate = WorkoutCalorieEstimator.estimateForWorkout(
        workout: workout,
        durationMinutes: duration,
        totalVolumeKg: volume,
        profile: profile,
        bodyMetrics: bodyMetrics,
      );

      final milestoneTotalsBefore = await ref
          .read(workoutServiceProvider)
          .getMilestoneTotals(profile: profile);
      final personalRecordsBefore = await ref.read(personalRecordsProvider.future);

      await ref.read(workoutServiceProvider).completeWorkout(
            workout.id,
            durationMinutes: duration,
            totalVolume: volume,
            activeCaloriesKcal: calorieEstimate.caloriesKcal,
          );
      await ref.read(watchWorkoutCoordinatorProvider).clear();

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
      final newPersonalRecords = SessionPersonalRecords.detect(
        workout: workout,
        existing: personalRecordsBefore,
        catalog: catalog,
        bodyWeightKg: bodyWeightKg,
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
        newPersonalRecords: newPersonalRecords,
      );

      if (!mounted) return;
      context.pushReplacement('/workout/summary', extra: summary);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _invalidateWorkoutProviders();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.finishFailed('$e'))),
        );
        setState(() => _completing = false);
      }
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
      _restEndsAt = null;
      _restTotalSeconds = null;
    });
  }

  void _dismissRestTimer(int sessionId) {
    if (sessionId != _restTimerKey) return;
    setState(() {
      _showRestTimer = false;
      _restEndsAt = null;
      _restTotalSeconds = null;
    });
    unawaited(_publishWatchSession());
  }

  void _onRestClockStarted(DateTime endsAt, int totalSeconds) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _restEndsAt = endsAt;
        _restTotalSeconds = totalSeconds;
      });
      unawaited(_publishWatchSession());
    });
  }

  Widget _buildActiveRestTimer() {
    final sessionId = _restTimerKey;
    return RestTimer(
      key: ValueKey('rest-$sessionId'),
      sessionId: sessionId,
      seconds: _restSeconds,
      endsAt: _restEndsAt,
      totalSeconds: _restTotalSeconds,
      controller: _restTimerController,
      onClockStarted: _onRestClockStarted,
      onComplete: () => _dismissRestTimer(sessionId),
      onSkip: () => _dismissRestTimer(sessionId),
    );
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
    unawaited(_publishWatchSession());
  }

  Future<void> _reorderExercises(Workout workout, List<String> orderedExerciseIds) async {
    if (orderedExerciseIds.isEmpty) return;

    try {
      await ref.read(workoutServiceProvider).reorderWorkoutExercises(
            workout.id,
            orderedExerciseIds,
          );
      await _syncActiveWorkout();
    } catch (e) {
      await _syncActiveWorkout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric('$e'))),
        );
      }
    }
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
          final displayWorkout = _mergedWorkout(workout);
          final visibleCount =
              displayWorkout.exercises.where((e) => !_removedExerciseIds.contains(e.id)).length;
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
              TextButton(
                onPressed: _completing ? null : () => _cancelWorkout(displayWorkout),
                child: Text(
                  l10n.cancelWorkout,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              TextButton(
                onPressed: _completing ? null : () => _completeWorkout(displayWorkout),
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

          final displayWorkout = _mergedWorkout(workout);

          final visibleExercises = displayWorkout.exercises
              .where((e) => !_removedExerciseIds.contains(e.id))
              .toList();

          if (_showExerciseList || visibleExercises.isEmpty) {
            return Column(
              children: [
                WorkoutElapsedTimer(startedAt: displayWorkout.startedAt),
                if (_showRestTimer) _buildActiveRestTimer(),
                Expanded(
                  child: ActiveWorkoutExerciseList(
                    workout: displayWorkout,
                    removedExerciseIds: _removedExerciseIds,
                    unitSystem: unitSystem,
                    onOpenExercise: _openExercise,
                    onAddExercise: () => _pickAndAddExercise(displayWorkout),
                    onRemoveExercise: (exercise) {
                      setState(() => _removedExerciseIds.add(exercise.id));
                      unawaited(_removeExercise(exercise));
                    },
                    onSwapExercise: (exercise) => _swapExercise(displayWorkout, exercise),
                    onReorderExercises: (orderedIds) =>
                        _reorderExercises(displayWorkout, orderedIds),
                  ),
                ),
              ],
            );
          }

          final exerciseIndex =
              _currentExerciseIndex.clamp(0, displayWorkout.exercises.length - 1);
          if (exerciseIndex != _currentExerciseIndex) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _currentExerciseIndex = exerciseIndex);
            });
          }
          final exercise = displayWorkout.exercises[exerciseIndex];
          if (_removedExerciseIds.contains(exercise.id)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _showExerciseList = true);
            });
            return const FitForgeLoadingScreen();
          }
          final sortedSets = _sortedSets(exercise)
              .where((s) => !_removedSetIds.contains(s.id))
              .toList();
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
              WorkoutElapsedTimer(startedAt: displayWorkout.startedAt),
              if (_showRestTimer) _buildActiveRestTimer(),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filledTonal(
                            tooltip: l10n.reportExerciseProblem,
                            onPressed: () => ExerciseReportSheet.show(
                              context,
                              exerciseId: exercise.exerciseId,
                              exerciseName: exercise.exerciseName,
                              service: ref.read(exerciseReportServiceProvider),
                            ),
                            icon: const Icon(Icons.flag_outlined),
                          ),
                          const SizedBox(width: 4),
                          IconButton.filledTonal(
                            tooltip: l10n.exerciseHistory,
                            onPressed: () => ExerciseHistorySheet.show(
                              context,
                              exerciseId: exercise.exerciseId,
                              exerciseName: exercise.exerciseName,
                              excludeWorkoutId: displayWorkout.id,
                            ),
                            icon: const Icon(Icons.history),
                          ),
                        ],
                      ),
                    ),
                    if (!isCardio) ...[
                      const SizedBox(height: 8),
                      ExerciseLoadControls(
                        exerciseId: exercise.exerciseId,
                        exerciseName: exercise.exerciseName,
                        catalog: exerciseCatalog,
                        perArmEnabled: ExerciseLoad.resolvePerArmWeight(
                          exerciseId: exercise.exerciseId,
                          catalog: exerciseCatalog,
                          exerciseName: exercise.exerciseName,
                          sessionOverride: _perArmOverrides[exercise.exerciseId],
                        ),
                        onPerArmChanged: (value) {
                          setState(() => _perArmOverrides[exercise.exerciseId] = value);
                        },
                        bodyWeightKg: ref.watch(profileProvider).valueOrNull?.bodyWeight,
                        unitSystem: unitSystem,
                      ),
                    ],
                    const SizedBox(height: 12),
                    ...sortedSets.asMap().entries.map(
                      (entry) {
                        if (isCardio) {
                          return CardioSetLogTile(
                            key: ValueKey(entry.value.id),
                            set: entry.value,
                            unitSystem: unitSystem,
                            config: cardioConfig,
                            isLast: entry.key == sortedSets.length - 1,
                            isSaving: _savingSetIds.contains(entry.value.id),
                            onValidationError: (message) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            },
                            onChanged: (updated) => _logSet(
                              displayWorkout,
                              exercise,
                              updated,
                              wasAlreadyCompleted: entry.value.completed,
                              isCardio: true,
                              isLastSet: entry.key == sortedSets.length - 1,
                              cardioConfig: cardioConfig,
                            ),
                            onDelete: () {
                              setState(() => _removedSetIds.add(entry.value.id));
                              unawaited(_deleteSet(displayWorkout, exercise, entry.value));
                            },
                          );
                        }
                        final loadMode = ExerciseLoad.loadModeForExerciseId(
                          exercise.exerciseId,
                          exerciseCatalog,
                          exerciseName: exercise.exerciseName,
                        );
                        final perArm = ExerciseLoad.resolvePerArmWeight(
                          exerciseId: exercise.exerciseId,
                          catalog: exerciseCatalog,
                          exerciseName: exercise.exerciseName,
                          sessionOverride: _perArmOverrides[exercise.exerciseId],
                        );
                        final weightOptional = ExerciseLoad.weightOptionalForExerciseId(
                              exercise.exerciseId,
                              exerciseCatalog,
                              exerciseName: exercise.exerciseName,
                            ) ??
                            false;
                        return SetLogTile(
                          key: ValueKey(entry.value.id),
                          set: entry.value,
                          unitSystem: unitSystem,
                          exerciseName: exercise.exerciseName,
                          perArmWeight: perArm,
                          weightOptional: weightOptional,
                          loadMode: loadMode,
                          bodyWeightKg: ref.watch(profileProvider).valueOrNull?.bodyWeight,
                          isLast: entry.key == sortedSets.length - 1,
                          isSaving: _savingSetIds.contains(entry.value.id),
                          onValidationError: (message) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          },
                          onChanged: (updated) => _logSet(
                            displayWorkout,
                            exercise,
                            updated,
                            wasAlreadyCompleted: entry.value.completed,
                            isCardio: false,
                            isLastSet: entry.key == sortedSets.length - 1,
                          ),
                          onDelete: () {
                            setState(() => _removedSetIds.add(entry.value.id));
                            unawaited(_deleteSet(displayWorkout, exercise, entry.value));
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _addSet(displayWorkout, exercise),
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
                currentIndex: WorkoutExerciseNavigation.visibleIndex(visibleExercises, exercise.id)
                    .clamp(0, visibleExercises.length - 1),
                total: visibleExercises.length,
                onPrevious: () {
                  final previousIndex = WorkoutExerciseNavigation.resolvePreviousWorkoutIndex(
                    workoutExercises: displayWorkout.exercises,
                    visibleExercises: visibleExercises,
                    currentExerciseId: exercise.id,
                  );
                  if (previousIndex != null) {
                    setState(() => _currentExerciseIndex = previousIndex);
                  }
                },
                onNext: () {
                  final nextIndex = WorkoutExerciseNavigation.resolveNextWorkoutIndex(
                    workoutExercises: displayWorkout.exercises,
                    visibleExercises: visibleExercises,
                    currentExerciseId: exercise.id,
                  );
                  if (nextIndex != null) {
                    setState(() => _currentExerciseIndex = nextIndex);
                  }
                },
                hasPrevious: WorkoutExerciseNavigation.hasPrevious(visibleExercises, exercise.id),
                hasNext: WorkoutExerciseNavigation.hasNext(visibleExercises, exercise.id),
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
    required bool isLastSet,
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
        final catalog = ref.read(exercisesProvider).valueOrNull ?? [];
        final weightOptional = ExerciseLoad.weightOptionalForExerciseId(
              exercise.exerciseId,
              catalog,
              exerciseName: exercise.exerciseName,
            ) ??
            false;
        if (!weightOptional && (set.weight == null || set.weight! <= 0)) {
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

    int? rir;
    if (!wasAlreadyCompleted && !isCardio && isLastSet && mounted) {
      rir = await RirPickerSheet.show(context);
    }

    final completedSet = set.copyWith(
      completed: true,
      rir: rir,
      loggingType: isCardio ? ExerciseLoggingType.cardio : ExerciseLoggingType.strength,
    );

    setState(() {
      _setOverrides[set.id] = completedSet;
      _savingSetIds.add(set.id);
    });

    if (!wasAlreadyCompleted && !isCardio) {
      _startRestTimer();
    }

    unawaited(
      _persistSet(
        exercise,
        completedSet,
        setId: set.id,
      ),
    );
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
    final setNumber = sorted.length + 1;
    final prevSet = sorted.isNotEmpty
        ? sorted.last
        : (previous != null
            ? ref.read(workoutServiceProvider).previousSetForNumber(previous, setNumber)
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

    setState(() {
      _insertedSets.putIfAbsent(exercise.id, () => []).add(newSet);
      _savingSetIds.add(newSet.id);
    });

    unawaited(
      _persistSet(
        exercise,
        newSet,
        setId: newSet.id,
      ),
    );
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
