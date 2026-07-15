import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/hyrox/hyrox_standards.dart';
import '../../core/hyrox/hyrox_validation.dart';
import '../../core/runner/runner_models.dart';
import '../../core/runner/runner_standards.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/supabase_datetime.dart';
import '../../core/utils/workout_exercise_navigation.dart';
import '../../core/utils/workout_calorie_estimator.dart';
import '../../core/utils/workout_streak.dart';
import '../../core/utils/workout_xp_utils.dart';
import '../../core/utils/exercise_load.dart';
import '../../core/utils/exercise_logging_resolver.dart';
import '../../core/utils/unit_converter.dart';
import '../../core/utils/cardio_format.dart';
import '../../core/utils/milestones.dart';
import '../../core/utils/player_level.dart';
import '../../core/utils/session_personal_records.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/exercise_logging.dart';
import '../../models/routine.dart';
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
import '../../widgets/runner_outdoor_session.dart';
import '../../widgets/runner_treadmill_session.dart';
import '../../widgets/hyrox_phase_timer.dart';
import '../../widgets/similar_exercise_picker_sheet.dart';
import '../../widgets/exercise_load_controls.dart';
import '../../widgets/exercise_report_sheet.dart';
import '../../core/theme/app_accent.dart';

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
  bool _perArmSeeded = false;
  bool _isHyroxWorkout = false;
  HyroxLevel? _hyroxLevel;
  List<RoutineExercise> _hyroxRoutineExercises = const [];
  bool _hyroxRaceStarted = false;
  DateTime? _hyroxGlobalStartedAt;
  DateTime? _stationStartedAt;
  DateTime? _workoutStoppedAt;
  final Map<String, double> _hyroxTargetMetersByExerciseId = {};
  bool _isRunnerWorkout = false;
  RunnerType? _runnerType;
  RunningSurface? _runnerSurface;

  Future<void> _seedPerArmFromRoutine(Workout workout) async {
    final routineId = workout.routineId;
    if (routineId == null) return;

    final routine = await ref.read(routineServiceProvider).getRoutineById(routineId);
    if (!mounted || routine == null) return;

    setState(() {
      _isHyroxWorkout = routine.isHyroxSystem;
      _hyroxLevel = routine.hyroxLevel;
      _hyroxRoutineExercises =
          routine.isHyroxSystem ? List<RoutineExercise>.from(routine.exercises) : const [];
      _isRunnerWorkout = routine.isRunnerSystem;
      _runnerType = routine.runnerType;
      _hyroxTargetMetersByExerciseId
        ..clear()
        ..addEntries(
          routine.exercises
              .where((e) => e.targetDistanceMeters != null)
              .map((e) => MapEntry(e.exerciseId, e.targetDistanceMeters!)),
        );
      for (final ex in routine.exercises) {
        if (ex.perArmWeight != null) {
          _perArmOverrides[ex.exerciseId] = ex.perArmWeight!;
        }
      }
    });
  }

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
    _runnerSurface = ref.read(pendingRunnerSurfaceProvider);
    RestPreferences.getDefaultRestSeconds().then((seconds) {
      if (mounted) setState(() => _restSeconds = seconds);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pendingRunnerSurfaceProvider.notifier).state = null;
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

  Future<void> _completeRunnerOutdoor(
    Workout workout,
    RunnerTrackingSnapshot snapshot,
  ) async {
    if (_completing) return;
    _freezeWorkoutTimers();
    setState(() => _completing = true);

    try {
      final exercise = workout.exercises.first;
      final frozen = _workoutStoppedAt ?? DateTime.now();
      final elapsed = snapshot.elapsedSeconds(frozen);
      final avgPace = snapshot.avgPaceSecPerKm(frozen);

      await ref.read(workoutServiceProvider).beginWorkoutTimer(workout.id);

      final set = WorkoutSet(
        id: exercise.sets.isNotEmpty ? exercise.sets.first.id : '',
        setNumber: 1,
        completed: true,
        loggingType: ExerciseLoggingType.cardio,
        durationSeconds: elapsed,
        distanceMeters: snapshot.distanceMeters,
      );
      await ref.read(workoutServiceProvider).logSet(exercise.id, set);

      await ref.read(workoutServiceProvider).saveRunnerSession(
            workoutId: workout.id,
            surface: _runnerSurface ?? snapshot.surface,
            route: snapshot.route,
            splits: snapshot.splits,
            avgPaceSecPerKm: avgPace,
            elevationGainMeters: snapshot.elevationGainMeters,
            elevationLossMeters: snapshot.elevationLossMeters,
          );

      await _syncActiveWorkout();
      final synced = ref.read(activeWorkoutProvider).valueOrNull;
      final merged = synced != null ? _mergedWorkout(synced) : workout;
      await _completeWorkout(merged, skipCompletingFlag: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.finishFailed('$e'))),
        );
        setState(() => _completing = false);
      }
    }
  }

  Future<void> _completeRunnerTreadmill(
    Workout workout,
    RunnerTreadmillResult result,
  ) async {
    if (_completing) return;
    _freezeWorkoutTimers();
    setState(() => _completing = true);

    try {
      final exercise = workout.exercises.first;

      await ref.read(workoutServiceProvider).beginWorkoutTimer(workout.id);

      final set = WorkoutSet(
        id: exercise.sets.isNotEmpty ? exercise.sets.first.id : '',
        setNumber: 1,
        completed: true,
        loggingType: ExerciseLoggingType.cardio,
        durationSeconds: result.durationSeconds,
        distanceMeters: result.distanceMeters,
        inclinePercent: result.inclinePercent,
      );
      await ref.read(workoutServiceProvider).logSet(exercise.id, set);

      await ref.read(workoutServiceProvider).saveRunnerSession(
            workoutId: workout.id,
            route: const [],
            splits: const [],
            avgPaceSecPerKm: result.avgPaceSecPerKm,
          );

      await _syncActiveWorkout();
      final synced = ref.read(activeWorkoutProvider).valueOrNull;
      final merged = synced != null ? _mergedWorkout(synced) : workout;
      await _completeWorkout(merged, skipCompletingFlag: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.finishFailed('$e'))),
        );
        setState(() => _completing = false);
      }
    }
  }

  Future<void> _completeWorkout(Workout workout, {bool skipCompletingFlag = false}) async {
    if (_completing && !skipCompletingFlag) return;
    if (!skipCompletingFlag) {
      _freezeWorkoutTimers();
      setState(() => _completing = true);
    }

    try {
      final fresh = await ref.read(workoutServiceProvider).getActiveWorkout();
      var effectiveWorkout = fresh != null ? _mergedWorkout(fresh) : workout;

      final startAt = _workoutTimerStart(effectiveWorkout);
      final endAt = _workoutTimerStop()?.toUtc() ?? SupabaseDateTime.nowUtc;
      final duration = endAt.difference(startAt.toUtc()).inMinutes;
      final catalog = ref.read(exercisesProvider).valueOrNull ?? [];
      final profile = ref.read(profileProvider).valueOrNull;
      final bodyWeightKg = profile?.bodyWeight;
      final volume = effectiveWorkout.exercises.fold<double>(
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
        workout: effectiveWorkout,
        durationMinutes: duration,
        totalVolumeKg: volume,
        profile: profile,
        bodyMetrics: bodyMetrics,
      );

      final milestoneTotalsBefore = await ref
          .read(workoutServiceProvider)
          .getMilestoneTotals(profile: profile);
      final personalRecordsBefore = await ref.read(personalRecordsProvider.future);

      final hyroxValidationFromServer = await ref.read(workoutServiceProvider).completeWorkout(
            effectiveWorkout.id,
            durationMinutes: duration,
            totalVolume: volume,
            activeCaloriesKcal: calorieEstimate.caloriesKcal,
          );
      await ref.read(watchWorkoutCoordinatorProvider).clear();

      HyroxValidationResult? hyroxValidation = hyroxValidationFromServer;
      if (hyroxValidation == null && _isHyroxWorkout && _hyroxLevel != null) {
        hyroxValidation = HyroxValidator.validate(
          workout: effectiveWorkout,
          level: _hyroxLevel!,
          gender: profile?.gender,
          startedAt: startAt,
          completedAt: endAt,
          expectations: HyroxValidator.expectationsFromRoutineExercises(_hyroxRoutineExercises),
        );
      }

      XpAwardResult? xpAward;
      final skipHyroxXp = hyroxValidation?.status == HyroxValidationStatus.rejected;
      if (!skipHyroxXp) {
        xpAward = await ref.read(profileServiceProvider).awardWorkoutXp(
              workoutId: effectiveWorkout.id,
              totalVolumeKg: volume,
              streakWeeks: streakWeeks,
              runDistanceMeters: WorkoutXpUtils.completedRunDistanceMeters(effectiveWorkout),
            );
      }

      final milestoneTotalsAfter = await ref
          .read(workoutServiceProvider)
          .getMilestoneTotals(profile: profile);
      final newMilestones = MilestonesCalculator.newlyUnlocked(
        milestoneTotalsBefore,
        milestoneTotalsAfter,
      );

      try {
        await ref.read(socialServiceProvider).publishPostWorkoutFeedEvents(
              newMilestones: newMilestones,
              xpAward: xpAward,
            );
      } catch (_) {}

      final previous = await ref.read(workoutServiceProvider).getPreviousRoutineWorkout(
            routineId: effectiveWorkout.routineId,
            excludeWorkoutId: effectiveWorkout.id,
          );
      final newPersonalRecords = SessionPersonalRecords.detect(
        workout: effectiveWorkout,
        existing: personalRecordsBefore,
        catalog: catalog,
        bodyWeightKg: bodyWeightKg,
      );

      final summary = WorkoutSummaryBuilder.build(
        workout: effectiveWorkout,
        durationMinutes: duration,
        previousSameRoutine: previous,
        xpAward: xpAward,
        exerciseCatalog: catalog,
        profile: profile,
        bodyMetrics: bodyMetrics,
        newMilestoneUnlocks: newMilestones,
        newPersonalRecords: newPersonalRecords,
        isHyrox: _isHyroxWorkout,
        isRunner: _isRunnerWorkout,
        hyroxValidation: hyroxValidation,
      );

      if (!mounted) return;
      ref.read(pendingWorkoutSummaryProvider.notifier).state = summary;
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

  DateTime _workoutTimerStart(Workout workout) =>
      _hyroxGlobalStartedAt ?? workout.startedAt;

  DateTime? _workoutTimerStop() => _workoutStoppedAt;

  void _freezeWorkoutTimers() {
    if (_workoutStoppedAt != null) return;
    setState(() {
      _workoutStoppedAt = DateTime.now();
      _showRestTimer = false;
    });
  }

  Future<void> _startHyroxRace(Workout workout) async {
    final visible = workout.exercises
        .where((e) => !_removedExerciseIds.contains(e.id))
        .toList();
    if (visible.isEmpty) return;

    final firstIndex = workout.exercises.indexWhere((e) => e.id == visible.first.id);
    final now = DateTime.now();

    setState(() {
      _hyroxRaceStarted = true;
      _hyroxGlobalStartedAt = now;
      _workoutStoppedAt = null;
      _showExerciseList = false;
      _currentExerciseIndex = firstIndex.clamp(0, workout.exercises.length - 1);
      _stationStartedAt = now;
    });

    try {
      await ref.read(workoutServiceProvider).beginWorkoutTimer(workout.id);
      ref.invalidate(activeWorkoutProvider);
      unawaited(_publishWatchSession());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric('$e'))),
        );
      }
    }
  }

  Widget _buildHyroxStartGate(Workout workout, AppLocalizations l10n) {
    final accent = context.accentColor;
    final visibleCount =
        workout.exercises.where((e) => !_removedExerciseIds.contains(e.id)).length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_run, size: 56, color: accent),
            const SizedBox(height: 20),
            Text(
              l10n.workoutDisplayName(workout.name),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.exercisesInRoutine(visibleCount),
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.hyroxReadyToStart,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _completing ? null : () => _startHyroxRace(workout),
                icon: const Icon(Icons.play_arrow, size: 28),
                label: Text(l10n.hyroxStartRace),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openExercise(int index) {
    setState(() {
      _currentExerciseIndex = index;
      _showExerciseList = false;
      if (_isHyroxWorkout && _hyroxRaceStarted) {
        _stationStartedAt = DateTime.now();
      }
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

    final workoutForSeed = activeAsync.valueOrNull;
    if (workoutForSeed != null && !_perArmSeeded && workoutForSeed.routineId != null) {
      _perArmSeeded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_seedPerArmFromRoutine(workoutForSeed));
      });
    }

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
              if ((!_isHyroxWorkout || _hyroxRaceStarted) && !_isRunnerWorkout)
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

          if (_isHyroxWorkout && !_hyroxRaceStarted) {
            return _buildHyroxStartGate(displayWorkout, l10n);
          }

          if (_isRunnerWorkout && _runnerType == RunnerType.outdoor) {
            return RunnerOutdoorSession(
              workoutId: displayWorkout.id,
              unitSystem: unitSystem,
              surface: _runnerSurface,
              onCancel: () => _cancelWorkout(displayWorkout),
              onFinish: (snap) => _completeRunnerOutdoor(displayWorkout, snap),
            );
          }

          if (_isRunnerWorkout && _runnerType == RunnerType.treadmill) {
            return RunnerTreadmillSession(
              unitSystem: unitSystem,
              onCancel: () => _cancelWorkout(displayWorkout),
              onFinish: (result) => _completeRunnerTreadmill(displayWorkout, result),
            );
          }

          final visibleExercises = displayWorkout.exercises
              .where((e) => !_removedExerciseIds.contains(e.id))
              .toList();

          if (_showExerciseList || visibleExercises.isEmpty) {
            return Column(
              children: [
                if (!_isHyroxWorkout || _hyroxRaceStarted)
                  WorkoutElapsedTimer(
                    startedAt: _workoutTimerStart(displayWorkout),
                    stoppedAt: _workoutTimerStop(),
                  ),
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
              if (!_isHyroxWorkout || _hyroxRaceStarted)
                WorkoutElapsedTimer(
                  startedAt: _workoutTimerStart(displayWorkout),
                  stoppedAt: _workoutTimerStop(),
                ),
              if (_isHyroxWorkout && _hyroxRaceStarted && _stationStartedAt != null)
                HyroxPhaseTimer(
                  phaseIndex: exerciseIndex,
                  totalPhases: visibleExercises.length,
                  startedAt: _stationStartedAt!,
                  stoppedAt: _workoutTimerStop(),
                  targetDistanceMeters: () {
                    final fromRoutine =
                        _hyroxTargetMetersByExerciseId[exercise.exerciseId];
                    if (fromRoutine != null) return fromRoutine;
                    for (final s in sortedSets) {
                      if (s.distanceMeters != null) return s.distanceMeters;
                    }
                    return null;
                  }(),
                ),
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
                    if (!isCardio && !_isHyroxWorkout) ...[
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
                    if (!isCardio && !_isHyroxWorkout) ...[
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
                    if (_isHyroxWorkout)
                      ..._buildHyroxStation(
                        displayWorkout: displayWorkout,
                        exercise: exercise,
                        sets: sortedSets,
                        visibleExercises: visibleExercises,
                        unitSystem: unitSystem,
                        isCardio: isCardio,
                        cardioConfig: cardioConfig,
                      )
                    else ...[
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
                        side: BorderSide(color: context.accentColor),
                        foregroundColor: context.accentColor,
                      ),
                    ),
                    ],
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

  List<String> _hyroxStationParts(
    WorkoutExercise exercise,
    List<WorkoutSet> sets,
    String unitSystem,
  ) {
    final parts = <String>[];
    final set = sets.isNotEmpty ? sets.first : null;
    final meters = _hyroxTargetMetersByExerciseId[exercise.exerciseId] ??
        set?.distanceMeters;
    if (meters != null && meters > 0) {
      parts.add('${meters.round()} m');
    }
    final reps = set?.reps ?? 0;
    if (reps > 0 && (meters == null || meters <= 0)) {
      parts.add('$reps reps');
    }
    final weight = set?.weight;
    if (weight != null && weight > 0) {
      final perArm = _perArmOverrides[exercise.exerciseId] ?? false;
      final w = UnitConverter.formatMass(weight, unitSystem, decimals: 0);
      parts.add(perArm ? '2 × $w' : w);
    }
    return parts;
  }

  List<Widget> _buildHyroxStation({
    required Workout displayWorkout,
    required WorkoutExercise exercise,
    required List<WorkoutSet> sets,
    required List<WorkoutExercise> visibleExercises,
    required String unitSystem,
    required bool isCardio,
    CardioLoggingConfig? cardioConfig,
  }) {
    final l10n = context.l10n;
    final accent = context.accentColor;
    final parts = _hyroxStationParts(exercise, sets, unitSystem);
    final allDone = sets.isNotEmpty && sets.every((s) => s.completed);
    final splitSeconds = allDone && sets.isNotEmpty
        ? sets
            .map((s) => s.durationSeconds ?? 0)
            .fold<int>(0, (a, b) => a > b ? a : b)
        : null;
    final saving = sets.any((s) => _savingSetIds.contains(s.id));

    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(
              parts.isEmpty ? '—' : parts.join('   ·   '),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.hyroxStationFixedHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (allDone)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                '${l10n.hyroxStationCompleted} · ${CardioFormat.duration(splitSeconds)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        )
      else
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: saving
                ? null
                : () => _completeHyroxStation(
                      displayWorkout,
                      exercise,
                      sets,
                      visibleExercises,
                      isCardio: isCardio,
                      cardioConfig: cardioConfig,
                    ),
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(l10n.hyroxStationDone),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              backgroundColor: accent,
              foregroundColor: Colors.black,
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
    ];
  }

  Future<void> _completeHyroxStation(
    Workout workout,
    WorkoutExercise exercise,
    List<WorkoutSet> sets,
    List<WorkoutExercise> visibleExercises, {
    required bool isCardio,
    CardioLoggingConfig? cardioConfig,
  }) async {
    final nextIndex = WorkoutExerciseNavigation.resolveNextWorkoutIndex(
      workoutExercises: workout.exercises,
      visibleExercises: visibleExercises,
      currentExerciseId: exercise.id,
    );
    if (nextIndex == null && _workoutStoppedAt == null) {
      setState(() => _workoutStoppedAt = DateTime.now());
    }

    for (var i = 0; i < sets.length; i++) {
      final set = sets[i];
      if (set.completed) continue;
      await _logSet(
        workout,
        exercise,
        set,
        wasAlreadyCompleted: false,
        isCardio: isCardio,
        isLastSet: i == sets.length - 1,
        cardioConfig: cardioConfig,
      );
    }

    if (!mounted) return;
    if (nextIndex != null) {
      setState(() {
        _currentExerciseIndex = nextIndex;
        _stationStartedAt = DateTime.now();
      });
      unawaited(_publishWatchSession());
    } else {
      await _syncActiveWorkout();
      if (!mounted) return;
      final synced = ref.read(activeWorkoutProvider).valueOrNull;
      await _completeWorkout(synced != null ? _mergedWorkout(synced) : workout);
    }
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
    if (!wasAlreadyCompleted && !_isHyroxWorkout) {
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
        final isLoadedDistance = ExerciseLoad.isLoadedDistance(
          exercise.exerciseId,
          catalog,
          exerciseName: exercise.exerciseName,
        );
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
        if (isLoadedDistance) {
          if (set.distanceMeters == null || set.distanceMeters! <= 0) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.distanceRequired)),
              );
            }
            return;
          }
        } else if (set.reps <= 0) {
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
    if (!wasAlreadyCompleted && !isCardio && isLastSet && mounted && !_isHyroxWorkout) {
      rir = await RirPickerSheet.show(context);
    }

    final stationSeconds = (_isHyroxWorkout && _stationStartedAt != null && !wasAlreadyCompleted)
        ? (_workoutStoppedAt ?? DateTime.now())
            .difference(_stationStartedAt!)
            .inSeconds
            .clamp(1, 24 * 3600)
        : null;

    final completedSet = set.copyWith(
      completed: true,
      rir: rir,
      loggingType: isCardio ? ExerciseLoggingType.cardio : ExerciseLoggingType.strength,
      durationSeconds: stationSeconds ?? set.durationSeconds,
    );

    setState(() {
      _setOverrides[set.id] = completedSet;
      _savingSetIds.add(set.id);
    });

    if (!wasAlreadyCompleted && !isCardio && !_isHyroxWorkout) {
      _startRestTimer();
    }

    final persist = _persistSet(
      exercise,
      completedSet,
      setId: set.id,
    );
    if (_isHyroxWorkout) {
      await persist;
    } else {
      unawaited(persist);
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
    final isLoadedDistance = ExerciseLoad.isLoadedDistance(
      exercise.exerciseId,
      catalog,
      exerciseName: exercise.exerciseName,
    );

    final newSet = WorkoutSet(
      id: const Uuid().v4(),
      setNumber: sorted.length + 1,
      weight: isCardio ? null : prevSet?.weight,
      reps: isCardio || isLoadedDistance ? 0 : (prevSet?.reps ?? 10),
      durationSeconds: isCardio ? prevSet?.durationSeconds : null,
      distanceMeters: isCardio || isLoadedDistance ? prevSet?.distanceMeters : null,
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
