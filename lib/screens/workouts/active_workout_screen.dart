import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/hyrox/hyrox_standards.dart';
import '../../core/hyrox/hyrox_validation.dart';
import '../../core/workout/workout_validation.dart';
import '../../core/runner/runner_models.dart';
import '../../core/runner/runner_standards.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/supabase_datetime.dart';
import '../../core/utils/workout_exercise_navigation.dart';
import '../../core/utils/superset_groups.dart';
import '../../core/utils/workout_calorie_estimator.dart';
import '../../core/utils/workout_duration_guard.dart';
import '../../core/utils/workout_streak.dart';
import '../../core/utils/workout_xp_utils.dart';
import '../../core/utils/exercise_history_utils.dart';
import '../../core/utils/exercise_load.dart';
import '../../core/utils/exercise_logging_resolver.dart';
import '../../core/utils/gym_weight.dart';
import '../../core/utils/previous_set_utils.dart';
import '../../core/utils/rir_weight_adjustment.dart';
import '../../core/utils/unit_converter.dart';
import '../../models/exercise.dart';
import '../../models/exercise_history.dart';
import '../../core/utils/cardio_format.dart';
import '../../core/utils/milestones.dart';
import '../../core/utils/player_level.dart';
import '../../core/utils/session_personal_records.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/body_metric.dart';
import '../../models/exercise_logging.dart';
import '../../models/profile.dart';
import '../../models/routine.dart';
import '../../models/watch_session.dart';
import '../../models/workout.dart';
import '../../models/workout_summary.dart';
import '../../providers/app_providers.dart';
import '../../providers/health_integration_provider.dart';
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
import '../../widgets/superset_rounds_sheet.dart';
import '../../widgets/runner_outdoor_session.dart';
import '../../widgets/runner_treadmill_session.dart';
import '../../widgets/hyrox_phase_timer.dart';
import '../../widgets/similar_exercise_picker_sheet.dart';
import '../../widgets/exercise_load_controls.dart';
import '../../widgets/exercise_report_sheet.dart';
import '../../core/theme/app_accent.dart';
import '../../core/tutorials/tutorial_catalog.dart';
import '../../core/tutorials/tutorial_targets.dart';
import '../../providers/tutorial_controller.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
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
  String? _focusSetId;
  bool _perArmSeeded = false;

  /// Unidad por ejercicio en la sesión (`kg`/`lb`); no persiste ni cambia el perfil.
  final Map<String, String> _unitOverrides = {};

  /// Peso planeado de cada serie antes de un ajuste por RIR de la anterior.
  final Map<String, double> _rirWeightBaselines = {};
  bool _isHyroxWorkout = false;
  HyroxLevel? _hyroxLevel;
  List<RoutineExercise> _hyroxRoutineExercises = const [];
  bool _hyroxRaceStarted = false;
  DateTime? _hyroxGlobalStartedAt;
  DateTime? _stationStartedAt;
  DateTime? _workoutStoppedAt;
  DateTime? _lastActivityAt;
  DateTime? _idlePausedAt;
  Duration _idleSkipped = Duration.zero;
  Timer? _idleCheckTimer;
  bool _activitySeeded = false;
  final Map<String, double> _hyroxTargetMetersByExerciseId = {};
  bool _isRunnerWorkout = false;
  RunnerType? _runnerType;
  RunningSurface? _runnerSurface;

  Future<void> _seedPerArmFromRoutine(Workout workout) async {
    final routineId = workout.routineId;
    if (routineId == null) return;

    final routine =
        await ref.read(routineServiceProvider).getRoutineById(routineId);
    if (!mounted || routine == null) return;

    setState(() {
      _isHyroxWorkout = routine.isHyroxSystem;
      _hyroxLevel = routine.hyroxLevel;
      _hyroxRoutineExercises = routine.isHyroxSystem
          ? List<RoutineExercise>.from(routine.exercises)
          : const [];
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

  bool _workoutHasCompletedCardio(Workout workout) {
    return workout.exercises.any(
      (ex) => ex.sets.any(
          (s) => s.completed && s.isCardio && (s.durationSeconds ?? 0) >= 60),
    );
  }

  Workout _workoutWithRunnerExercise(
    Workout workout,
    WorkoutExercise exercise,
    WorkoutSet set, {
    RunningSurface? runnerSurface,
    List<RunnerRoutePoint>? runnerRoute,
    List<RunnerKmSplit>? runnerSplits,
    double? runnerAvgPaceSecPerKm,
    double? runnerElevationGainMeters,
    double? runnerElevationLossMeters,
  }) {
    return Workout(
      id: workout.id,
      userId: workout.userId,
      routineId: workout.routineId,
      routineName: workout.routineName,
      name: workout.name,
      startedAt: workout.startedAt,
      completedAt: workout.completedAt,
      lastActivityAt: workout.lastActivityAt,
      durationMinutes: workout.durationMinutes,
      activeCaloriesKcal: workout.activeCaloriesKcal,
      exercises: [
        exercise.copyWith(sets: [set]),
      ],
      notes: workout.notes,
      totalVolume: workout.totalVolume,
      runnerSurface: runnerSurface ?? workout.runnerSurface,
      runnerRoute: runnerRoute ?? workout.runnerRoute,
      runnerSplits: runnerSplits ?? workout.runnerSplits,
      runnerAvgPaceSecPerKm:
          runnerAvgPaceSecPerKm ?? workout.runnerAvgPaceSecPerKm,
      runnerElevationGainMeters:
          runnerElevationGainMeters ?? workout.runnerElevationGainMeters,
      runnerElevationLossMeters:
          runnerElevationLossMeters ?? workout.runnerElevationLossMeters,
      hyroxValidationStatus: workout.hyroxValidationStatus,
      hyroxValidationReasons: workout.hyroxValidationReasons,
      validationStatus: workout.validationStatus,
      validationReasons: workout.validationReasons,
    );
  }

  Workout _mergedWorkout(Workout workout) {
    if (_setOverrides.isEmpty && _insertedSets.isEmpty) return workout;

    final exercises = workout.exercises.map((exercise) {
      var sets =
          exercise.sets.map((set) => _setOverrides[set.id] ?? set).toList();
      final pending = _insertedSets[exercise.id];
      if (pending != null) {
        for (final set in pending) {
          if (!sets.any((s) => s.id == set.id)) sets.add(set);
        }
        sets.sort((a, b) => a.setNumber.compareTo(b.setNumber));
      }
      return exercise.copyWith(sets: sets);
    }).toList();

    return Workout(
      id: workout.id,
      userId: workout.userId,
      routineId: workout.routineId,
      routineName: workout.routineName,
      name: workout.name,
      startedAt: workout.startedAt,
      completedAt: workout.completedAt,
      lastActivityAt: workout.lastActivityAt,
      durationMinutes: workout.durationMinutes,
      activeCaloriesKcal: workout.activeCaloriesKcal,
      exercises: exercises,
      notes: workout.notes,
      totalVolume: workout.totalVolume,
      runnerSurface: workout.runnerSurface,
      runnerRoute: workout.runnerRoute,
      runnerSplits: workout.runnerSplits,
      runnerAvgPaceSecPerKm: workout.runnerAvgPaceSecPerKm,
      runnerElevationGainMeters: workout.runnerElevationGainMeters,
      runnerElevationLossMeters: workout.runnerElevationLossMeters,
      hyroxValidationStatus: workout.hyroxValidationStatus,
      hyroxValidationReasons: workout.hyroxValidationReasons,
      validationStatus: workout.validationStatus,
      validationReasons: workout.validationReasons,
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

  Future<void> _refreshActiveWorkoutAfterSet(String setId,
      {String? exerciseId}) async {
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
      await ref.read(workoutServiceProvider).logSet(
            exercise.id,
            completedSet,
            workoutId: ref.read(activeWorkoutProvider).valueOrNull?.id,
          );
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
            _restEndsAt =
                (_restEndsAt ?? DateTime.now()).add(Duration(seconds: delta));
          });
          await _publishWatchSession(workout);
        }
      case WatchActionType.completeSet:
        await _completeSetFromWatch(workout, action);
      case WatchActionType.updateSet:
        break;
    }
  }

  Future<void> _completeSetFromWatch(
    Workout workout,
    WatchWorkoutAction action,
  ) async {
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
          fromWatch: true,
          watchRir: action.skipRir ? null : action.rir,
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
    final setIds =
        workout.exercises.expand((e) => e.sets).map((s) => s.id).toSet();
    final staleExercises =
        _removedExerciseIds.any((id) => !exerciseIds.contains(id));
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

  Future<void> _leaveActiveWorkoutToMenu() async {
    if (!await _confirmLeaveActiveWorkout() || !mounted) return;
    context.go('/');
  }

  Future<bool> _confirmEndTraining() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.endTraining),
        content: Text(l10n.confirmEndTrainingMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.finish),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _requestCompleteWorkout(Workout workout) async {
    if (!await _confirmEndTraining() || !mounted) return;
    await _completeWorkout(workout);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runnerSurface = ref.read(pendingRunnerSurfaceProvider);
    RestPreferences.getDefaultRestSeconds().then((seconds) {
      if (mounted) setState(() => _restSeconds = seconds);
    });
    _idleCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _checkIdlePause();
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
    _idleCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    ref.read(watchWorkoutCoordinatorProvider).detach();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reconcileRestTimerOnResume();
      _checkIdlePause();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _checkIdlePause();
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
    return [...exercise.sets]
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
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
      ref.invalidate(pendingSyncCountProvider);
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

      final set = WorkoutSet(
        id: exercise.sets.isNotEmpty ? exercise.sets.first.id : '',
        setNumber: 1,
        completed: true,
        loggingType: ExerciseLoggingType.cardio,
        durationSeconds: elapsed,
        distanceMeters: snapshot.distanceMeters,
      );
      await ref
          .read(workoutServiceProvider)
          .logSet(exercise.id, set, workoutId: workout.id);

      await ref.read(workoutServiceProvider).saveRunnerSession(
            workoutId: workout.id,
            surface: _runnerSurface ?? snapshot.surface,
            route: snapshot.route,
            splits: snapshot.splits,
            avgPaceSecPerKm: avgPace,
            elevationGainMeters: snapshot.elevationGainMeters,
            elevationLossMeters: snapshot.elevationLossMeters,
          );

      final runnerWorkout = _workoutWithRunnerExercise(
        workout,
        exercise,
        set,
        runnerSurface: _runnerSurface ?? snapshot.surface,
        runnerRoute: snapshot.route,
        runnerSplits: snapshot.splits,
        runnerAvgPaceSecPerKm: avgPace,
        runnerElevationGainMeters: snapshot.elevationGainMeters,
        runnerElevationLossMeters: snapshot.elevationLossMeters,
      );
      await _completeWorkout(runnerWorkout, skipCompletingFlag: true);
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

      final set = WorkoutSet(
        id: exercise.sets.isNotEmpty ? exercise.sets.first.id : '',
        setNumber: 1,
        completed: true,
        loggingType: ExerciseLoggingType.cardio,
        durationSeconds: result.durationSeconds,
        distanceMeters: result.distanceMeters,
        inclinePercent: result.inclinePercent,
      );
      await ref
          .read(workoutServiceProvider)
          .logSet(exercise.id, set, workoutId: workout.id);

      await ref.read(workoutServiceProvider).saveRunnerSession(
            workoutId: workout.id,
            route: const [],
            splits: const [],
            avgPaceSecPerKm: result.avgPaceSecPerKm,
          );

      final runnerWorkout = _workoutWithRunnerExercise(
        workout,
        exercise,
        set,
        runnerAvgPaceSecPerKm: result.avgPaceSecPerKm,
      );
      await _completeWorkout(runnerWorkout, skipCompletingFlag: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.finishFailed('$e'))),
        );
        setState(() => _completing = false);
      }
    }
  }

  Future<void> _completeWorkout(Workout workout,
      {bool skipCompletingFlag = false}) async {
    if (_completing && !skipCompletingFlag) return;
    if (!skipCompletingFlag) {
      _freezeWorkoutTimers();
      setState(() => _completing = true);
    }

    try {
      Workout effectiveWorkout;
      if (_isRunnerWorkout && _workoutHasCompletedCardio(workout)) {
        effectiveWorkout = _mergedWorkout(workout);
      } else {
        final fresh = await ref.read(workoutServiceProvider).getActiveWorkout();
        effectiveWorkout = fresh != null ? _mergedWorkout(fresh) : workout;
      }

      final startAt = _workoutTimerStart(effectiveWorkout);
      final wallEndAt = _workoutTimerStop()?.toUtc() ?? SupabaseDateTime.nowUtc;
      var duration = wallEndAt.difference(startAt.toUtc()).inMinutes;
      duration -= _idleSkipped.inMinutes;
      if (duration < 0) duration = 0;
      if (_isRunnerWorkout) {
        duration = WorkoutCalorieEstimator.resolveDurationMinutes(
          workout: effectiveWorkout,
          wallClockMinutes: duration,
        );
      }
      final durationResolution = WorkoutDurationGuard.resolve(
        wallClockMinutes: duration,
        startedAt: startAt,
        lastActivityAt: _lastActivityAt ?? effectiveWorkout.lastActivityAt,
        skipIdleTrim: _skipIdleGuard,
      );
      duration = durationResolution.minutes;
      final endAt = startAt.toUtc().add(Duration(minutes: duration));
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
      final isOnline = ref.read(isOnlineProvider).valueOrNull ?? true;

      List<DateTime> completedDates = [];
      if (isOnline) {
        try {
          completedDates = await ref
              .read(workoutServiceProvider)
              .getCompletedWorkoutTimestamps();
        } catch (_) {}
      }
      final streakWeeks = WorkoutStreakCalculator.weeklyStreak([
        DateTime.now(),
        ...completedDates,
      ]);
      Map<String, BodyMetricSnapshot>? bodyMetrics;
      try {
        bodyMetrics = await ref.read(bodyMetricSnapshotsProvider.future);
      } catch (_) {
        bodyMetrics = null;
      }
      final calorieEstimate = WorkoutCalorieEstimator.estimateForWorkout(
        workout: effectiveWorkout,
        durationMinutes: duration,
        totalVolumeKg: volume,
        profile: profile,
        bodyMetrics: bodyMetrics,
      );

      MilestoneTotals milestoneTotalsBefore = MilestoneTotals.empty;
      List<PersonalRecord> personalRecordsBefore = [];
      if (isOnline) {
        try {
          milestoneTotalsBefore = await ref
              .read(workoutServiceProvider)
              .getMilestoneTotals(profile: profile);
        } catch (_) {}
        try {
          personalRecordsBefore =
              await ref.read(personalRecordsProvider.future);
        } catch (_) {}
      }

      final completionValidation =
          await ref.read(workoutServiceProvider).completeWorkout(
                effectiveWorkout.id,
                durationMinutes: duration,
                totalVolume: volume,
                activeCaloriesKcal: calorieEstimate.caloriesKcal,
                startedAt: startAt,
                completedAt: endAt,
              );

      // Export a Apple Health / Health Connect (no bloquea el flujo si falla).
      unawaited(
        ref.read(healthWorkoutExporterProvider).exportIfEnabled(
              workoutId: effectiveWorkout.id,
              startAt: startAt,
              endAt: endAt,
              durationMinutes: duration,
              title: effectiveWorkout.name,
              activeCaloriesKcal: calorieEstimate.caloriesKcal,
              distanceMeters: _distanceMetersForHealthExport(effectiveWorkout),
              isRunner: _isRunnerWorkout,
              isHyrox: _isHyroxWorkout,
              runnerType: _runnerType,
            ),
      );

      ref.invalidate(pendingSyncCountProvider);
      await ref.read(watchWorkoutCoordinatorProvider).clear();

      WorkoutValidationResult validation = completionValidation?.validation ??
          WorkoutValidator.validate(
            workout: effectiveWorkout,
            startedAt: startAt,
            completedAt: endAt,
            durationMinutes: duration,
            totalVolumeKg: volume,
            activeCaloriesKcal: calorieEstimate.caloriesKcal,
            runnerAvgPaceSecPerKm: effectiveWorkout.runnerAvgPaceSecPerKm,
            isHyroxSystem: _isHyroxWorkout,
            workoutsCompletedSameDay: completedDates.where((date) {
              final utc = date.toUtc();
              final endUtc = endAt.toUtc();
              return utc.year == endUtc.year &&
                  utc.month == endUtc.month &&
                  utc.day == endUtc.day;
            }).length,
          );

      HyroxValidationResult? hyroxValidation =
          completionValidation?.hyroxValidation;
      if (hyroxValidation == null && _isHyroxWorkout && _hyroxLevel != null) {
        hyroxValidation = HyroxValidator.validate(
          workout: effectiveWorkout,
          level: _hyroxLevel!,
          gender: profile?.gender,
          startedAt: startAt,
          completedAt: endAt,
          expectations: HyroxValidator.expectationsFromRoutineExercises(
              _hyroxRoutineExercises),
        );
      }

      XpAwardResult? xpAward;
      final skipXp = completionValidation?.skipXp ??
          (validation.status == WorkoutValidationStatus.rejected ||
              hyroxValidation?.status == HyroxValidationStatus.rejected);
      if (!skipXp && isOnline) {
        try {
          xpAward = await ref.read(profileServiceProvider).awardWorkoutXp(
                workoutId: effectiveWorkout.id,
                totalVolumeKg: volume,
                streakWeeks: streakWeeks,
                runDistanceMeters:
                    WorkoutXpUtils.completedRunDistanceMeters(effectiveWorkout),
                isRunnerRoutine: _isRunnerWorkout,
              );
        } catch (_) {}
      }

      MilestoneTotals milestoneTotalsAfter = milestoneTotalsBefore;
      if (isOnline) {
        try {
          milestoneTotalsAfter = await ref
              .read(workoutServiceProvider)
              .getMilestoneTotals(profile: profile);
        } catch (_) {}
      }
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

      Workout? previous;
      if (isOnline) {
        try {
          previous =
              await ref.read(workoutServiceProvider).getPreviousRoutineWorkout(
                    routineId: effectiveWorkout.routineId,
                    excludeWorkoutId: effectiveWorkout.id,
                  );
        } catch (_) {}
      }
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
        validation: validation,
      );

      if (!mounted) return;
      if (durationResolution.trimmed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.workoutDurationTrimmed(duration)),
            duration: const Duration(seconds: 6),
          ),
        );
      }
      ref.read(pendingWorkoutSummaryProvider.notifier).state = summary;
      ref.read(workoutSummarySessionIdProvider.notifier).state =
          summary.workout.id;
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

  double? _distanceMetersForHealthExport(Workout workout) {
    var sum = 0.0;
    for (final exercise in workout.exercises) {
      for (final set in exercise.sets) {
        final meters = set.distanceMeters;
        if (meters != null && meters > 0) sum += meters;
      }
    }
    if (sum > 0) return sum;
    if (workout.runnerSplits.isNotEmpty) {
      return workout.runnerSplits.last.km * 1000.0;
    }
    return null;
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
    FocusManager.instance.primaryFocus?.unfocus();
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
      await ref
          .read(workoutServiceProvider)
          .removeExerciseFromWorkout(exercise.id);
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

  DateTime? _workoutTimerStop() => _workoutStoppedAt ?? _idlePausedAt;

  DateTime _elapsedTimerStart(Workout workout) =>
      _workoutTimerStart(workout).add(_idleSkipped);

  void _seedActivityIfNeeded(Workout workout) {
    if (_activitySeeded) return;
    _activitySeeded = true;
    _lastActivityAt = workout.lastActivityAt ?? workout.startedAt;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkIdlePause();
    });
  }

  void _markWorkoutActivity() {
    final now = DateTime.now();
    setState(() {
      _lastActivityAt = now;
      if (_idlePausedAt != null) {
        _idleSkipped += now.difference(_idlePausedAt!);
        _idlePausedAt = null;
      }
    });
  }

  bool get _skipIdleGuard =>
      _isRunnerWorkout ||
      _isHyroxWorkout ||
      ref.read(tutorialControllerProvider).activeTourId ==
          TutorialCatalog.workoutSession;

  void _checkIdlePause() {
    if (!mounted || _skipIdleGuard || _completing) return;
    if (_workoutStoppedAt != null || _idlePausedAt != null) return;
    final last = _lastActivityAt;
    if (last == null) return;
    if (!WorkoutDurationGuard.shouldPauseForIdle(
      lastActivityAt: last,
      now: DateTime.now(),
      restTimerActive: _showRestTimer,
    )) {
      return;
    }
    setState(() => _idlePausedAt = DateTime.now());
  }

  void _resumeIdlePause() {
    final pausedAt = _idlePausedAt;
    if (pausedAt == null) return;
    setState(() {
      _idleSkipped += DateTime.now().difference(pausedAt);
      _idlePausedAt = null;
      _lastActivityAt = DateTime.now();
    });
  }

  void _freezeWorkoutTimers() {
    if (_workoutStoppedAt != null) return;
    setState(() {
      _workoutStoppedAt = _idlePausedAt ?? DateTime.now();
      _showRestTimer = false;
    });
  }

  Widget _buildIdlePauseBanner(AppLocalizations l10n) {
    return Material(
      color: AppColors.cardElevated,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.pause_circle_outline,
                color: AppColors.warning, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.workoutIdlePaused,
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _resumeIdlePause,
              child: Text(l10n.workoutIdleResume),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startHyroxRace(Workout workout) async {
    final visible = workout.exercises
        .where((e) => !_removedExerciseIds.contains(e.id))
        .toList();
    if (visible.isEmpty) return;

    final firstIndex =
        workout.exercises.indexWhere((e) => e.id == visible.first.id);
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
    final visibleCount = workout.exercises
        .where((e) => !_removedExerciseIds.contains(e.id))
        .length;

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

  static const _tutorialExerciseDetailTargets = {
    TutorialTargets.workoutRest,
    TutorialTargets.workoutAddSet,
    TutorialTargets.workoutRemoveSet,
  };

  void _scheduleTutorialWorkoutView(Workout? workout) {
    if (workout == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncTutorialWorkoutView(workout);
    });
  }

  void _syncTutorialWorkoutView(Workout workout) {
    final tutorial = ref.read(tutorialControllerProvider);
    if (tutorial.activeTourId != TutorialCatalog.workoutSession) return;
    final id = tutorial.activeStep?.targetId;
    if (id == null) return;

    final wantDetail = _tutorialExerciseDetailTargets.contains(id);
    if (wantDetail) {
      final index = _tutorialExerciseIndex(workout);
      if (_showExerciseList || _currentExerciseIndex != index) {
        setState(() {
          _showExerciseList = false;
          _currentExerciseIndex = index;
        });
      }
      return;
    }

    if (!_showExerciseList) {
      setState(() => _showExerciseList = true);
    }
  }

  int _tutorialExerciseIndex(Workout workout) {
    final catalog = ref.read(exercisesProvider).valueOrNull ?? [];
    final visible = workout.exercises
        .where((exercise) => !_removedExerciseIds.contains(exercise.id))
        .toList();
    for (final exercise in visible) {
      final cardio = ExerciseLoggingResolver.isCardioExercise(
        exerciseId: exercise.exerciseId,
        exerciseName: exercise.exerciseName,
        catalog: catalog,
        sets: exercise.sets,
      );
      if (!cardio) {
        final index = workout.exercises.indexWhere((e) => e.id == exercise.id);
        if (index >= 0) return index;
      }
    }
    if (visible.isEmpty) return 0;
    final index = workout.exercises.indexWhere((e) => e.id == visible.first.id);
    return index >= 0 ? index : 0;
  }

  Widget _anchorRemoveSet({required bool highlight, required Widget child}) {
    if (!highlight) return child;
    return KeyedSubtree(
      key: TutorialTargets.workoutRemoveSetKey,
      child: child,
    );
  }

  Future<void> _reorderExercises(
      Workout workout, List<String> orderedExerciseIds) async {
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

  bool _isWorkoutExerciseCardio(WorkoutExercise exercise) {
    final catalog = ref.read(exercisesProvider).valueOrNull ?? [];
    return ExerciseLoggingResolver.isCardioExercise(
      exerciseId: exercise.exerciseId,
      exerciseName: exercise.exerciseName,
      catalog: catalog,
      sets: exercise.sets,
    );
  }

  List<WorkoutExercise> _assignMissingSetIds(List<WorkoutExercise> exercises) {
    return [
      for (final ex in exercises)
        ex.copyWith(
          sets: [
            for (final set in ex.sets)
              if (set.id.isEmpty)
                WorkoutSet(
                  id: const Uuid().v4(),
                  setNumber: set.setNumber,
                  weight: set.weight,
                  reps: set.reps,
                  rir: set.rir,
                  completed: set.completed,
                  restTaken: set.restTaken,
                  durationSeconds: set.durationSeconds,
                  distanceMeters: set.distanceMeters,
                  inclinePercent: set.inclinePercent,
                  steps: set.steps,
                  loggingType: set.loggingType,
                )
              else
                set,
          ],
        ),
    ];
  }

  Future<void> _applyWorkoutLayout(
    Workout workout,
    List<WorkoutExercise> nextExercises,
  ) async {
    final assigned = _assignMissingSetIds(nextExercises);
    final previousById = {for (final ex in workout.exercises) ex.id: ex};
    final service = ref.read(workoutServiceProvider);

    try {
      await service.updateExerciseGrouping(
        workoutId: workout.id,
        exercises: assigned,
      );
      for (final ex in assigned) {
        final previous = previousById[ex.id];
        final previousIds = {
          for (final set in previous?.sets ?? const <WorkoutSet>[]) set.id,
        };
        for (final set in ex.sets) {
          if (!previousIds.contains(set.id)) {
            await service.logSet(ex.id, set, workoutId: workout.id);
          }
        }
        if (previous != null) {
          final nextIds = {for (final set in ex.sets) set.id};
          for (final set in previous.sets) {
            if (set.id.isNotEmpty && !nextIds.contains(set.id)) {
              await service.deleteSet(ex.id, set.id, workoutId: workout.id);
            }
          }
        }
      }
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

  Future<void> _joinSuperset(
    Workout workout,
    int blockIndex,
    List<WorkoutExercise> ordered,
  ) async {
    final updated = SupersetGroups.joinWorkoutBlockWithNext(
      ordered,
      blockIndex,
      newGroupId: const Uuid().v4(),
      isCardio: _isWorkoutExerciseCardio,
    );
    await _applyWorkoutLayout(workout, updated);
  }

  Future<void> _leaveSuperset(Workout workout, WorkoutExercise exercise) async {
    final visible = workout.exercises
        .where((e) => !_removedExerciseIds.contains(e.id))
        .toList();
    final updated = SupersetGroups.leaveWorkoutSuperset(visible, exercise.id);
    await _applyWorkoutLayout(workout, updated);
  }

  Future<void> _setSupersetRounds(
    Workout workout,
    List<WorkoutExercise> members,
    int rounds,
  ) async {
    final groupId = members.first.supersetGroupId;
    if (groupId == null) return;
    final updated = SupersetGroups.setGroupRoundCount(
      workout.exercises,
      groupId,
      rounds,
    );
    await _applyWorkoutLayout(workout, updated);
  }

  Future<void> _pickSupersetRounds(
    Workout workout,
    List<WorkoutExercise> members,
  ) async {
    final selected = await SupersetRoundsSheet.show(
      context,
      selected: SupersetGroups.roundCount(members),
      min: SupersetGroups.minAllowedRounds(members),
    );
    if (selected == null || !mounted) return;
    await _setSupersetRounds(workout, members, selected);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tutorialControllerProvider, (prev, next) {
      if (next.activeTourId != TutorialCatalog.workoutSession) return;
      _scheduleTutorialWorkoutView(ref.read(activeWorkoutProvider).valueOrNull);
    });
    ref.listen(activeWorkoutProvider, (prev, next) {
      _scheduleTutorialWorkoutView(next.valueOrNull);
    });

    final l10n = context.l10n;
    final activeAsync = ref.watch(activeWorkoutProvider);
    final unitSystem = ref.watch(unitSystemProvider);
    final exerciseCatalog = ref.watch(exercisesProvider).valueOrNull ?? [];

    final workoutForSeed = activeAsync.valueOrNull;
    if (workoutForSeed != null &&
        !_perArmSeeded &&
        workoutForSeed.routineId != null) {
      _perArmSeeded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_seedPerArmFromRoutine(workoutForSeed));
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _leaveActiveWorkoutToMenu();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: activeAsync.whenOrNull(
              data: (workout) {
                if (workout == null) return null;
                final displayWorkout = _mergedWorkout(workout);
                final visibleCount = displayWorkout.exercises
                    .where((e) => !_removedExerciseIds.contains(e.id))
                    .length;
                final inExerciseView = !_showExerciseList && visibleCount > 0;

                return FitForgeAppBar(
                  title: l10n.training,
                  showBrandMark: false,
                  showWordmark: false,
                  automaticallyImplyLeading: false,
                  leading: inExerciseView
                      ? IconButton(
                          icon: const Icon(Icons.list),
                          tooltip: l10n.viewList,
                          onPressed: () =>
                              setState(() => _showExerciseList = true),
                        )
                      : IconButton(
                          icon: const Icon(Icons.menu),
                          tooltip: l10n.backToMenu,
                          onPressed:
                              _completing ? null : _leaveActiveWorkoutToMenu,
                        ),
                  actions: [
                    if (MediaQuery.viewInsetsOf(context).bottom > 80)
                      IconButton(
                        tooltip: l10n.done,
                        onPressed: () =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        icon: const Icon(Icons.keyboard_hide_outlined),
                      ),
                    TextButton(
                      onPressed: _completing
                          ? null
                          : () => _cancelWorkout(displayWorkout),
                      child: Text(
                        l10n.cancelWorkout,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    if ((!_isHyroxWorkout || _hyroxRaceStarted) &&
                        !_isRunnerWorkout)
                      TextButton(
                        onPressed: _completing
                            ? null
                            : () => _requestCompleteWorkout(displayWorkout),
                        child: _completing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.finish),
                      ),
                  ],
                );
              },
            ) ??
            FitForgeAppBar(
                title: l10n.training, automaticallyImplyLeading: false),
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
            _seedActivityIfNeeded(displayWorkout);

            if (_isHyroxWorkout && !_hyroxRaceStarted) {
              return _buildHyroxStartGate(displayWorkout, l10n);
            }

            if (_isRunnerWorkout && (_runnerType?.usesOutdoorGps ?? false)) {
              return RunnerOutdoorSession(
                workoutId: displayWorkout.id,
                unitSystem: unitSystem,
                surface: _runnerSurface,
                isWalk: _runnerType?.isWalk ?? false,
                onCancel: () => _cancelWorkout(displayWorkout),
                onFinish: (snap) async {
                  if (!await _confirmEndTraining() || !mounted) return;
                  await _completeRunnerOutdoor(displayWorkout, snap);
                },
              );
            }

            if (_isRunnerWorkout && _runnerType == RunnerType.treadmill) {
              return RunnerTreadmillSession(
                unitSystem: unitSystem,
                onCancel: () => _cancelWorkout(displayWorkout),
                onFinish: (result) async {
                  if (!await _confirmEndTraining() || !mounted) return;
                  await _completeRunnerTreadmill(displayWorkout, result);
                },
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
                      startedAt: _elapsedTimerStart(displayWorkout),
                      stoppedAt: _workoutTimerStop(),
                    ),
                  if (_idlePausedAt != null && !_skipIdleGuard)
                    _buildIdlePauseBanner(l10n),
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
                      onSwapExercise: (exercise) =>
                          _swapExercise(displayWorkout, exercise),
                      onReorderExercises: (orderedIds) =>
                          _reorderExercises(displayWorkout, orderedIds),
                      isCardioExercise: (exercise) =>
                          ExerciseLoggingResolver.isCardioExercise(
                        exerciseId: exercise.exerciseId,
                        exerciseName: exercise.exerciseName,
                        catalog: exerciseCatalog,
                        sets: exercise.sets,
                      ),
                      onJoinSuperset: (_isHyroxWorkout || _isRunnerWorkout)
                          ? null
                          : (blockIndex, ordered) => _joinSuperset(
                              displayWorkout, blockIndex, ordered),
                      onLeaveSuperset: (_isHyroxWorkout || _isRunnerWorkout)
                          ? null
                          : (exercise) =>
                              _leaveSuperset(displayWorkout, exercise),
                    ),
                  ),
                ],
              );
            }

            final exerciseIndex = _currentExerciseIndex.clamp(
                0, displayWorkout.exercises.length - 1);
            if (exerciseIndex != _currentExerciseIndex) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted)
                  setState(() => _currentExerciseIndex = exerciseIndex);
              });
            }
            final exercise = displayWorkout.exercises[exerciseIndex];
            if (_removedExerciseIds.contains(exercise.id)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _showExerciseList = true);
              });
              return const FitForgeLoadingScreen();
            }
            final supersetMembers = SupersetGroups.membersOf(
              visibleExercises,
              exercise.supersetGroupId,
            );
            if (supersetMembers.length >= 2 && !_isHyroxWorkout) {
              return _buildSupersetLogger(
                displayWorkout: displayWorkout,
                members: supersetMembers,
                visibleExercises: visibleExercises,
                unitSystem: unitSystem,
                exerciseCatalog: exerciseCatalog,
                l10n: l10n,
              );
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

            final exerciseUnit =
                _unitOverrides[exercise.exerciseId] ?? unitSystem;
            final lastSessionLabel = !isCardio && !_isHyroxWorkout
                ? ref
                    .watch(
                      exerciseHistoryProvider(
                        ExerciseHistoryQuery(
                          exerciseId: exercise.exerciseId,
                          excludeWorkoutId: displayWorkout.id,
                        ),
                      ),
                    )
                    .maybeWhen(
                      data: (history) => _lastSessionChipLabel(
                        history,
                        exerciseUnit,
                        l10n,
                      ),
                      orElse: () => null,
                    )
                : null;

            return Column(
              children: [
                if (!_isHyroxWorkout || _hyroxRaceStarted)
                  WorkoutElapsedTimer(
                    startedAt: _elapsedTimerStart(displayWorkout),
                    stoppedAt: _workoutTimerStop(),
                  ),
                if (_idlePausedAt != null && !_skipIdleGuard)
                  _buildIdlePauseBanner(l10n),
                if (_isHyroxWorkout &&
                    _hyroxRaceStarted &&
                    _stationStartedAt != null)
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
                _PinnedExerciseHeader(
                  exerciseId: exercise.exerciseId,
                  exerciseName: exercise.exerciseName,
                  restSelector: !isCardio && !_isHyroxWorkout
                      ? RestTimeSelector(
                          key: TutorialTargets.workoutRestKey,
                          selectedSeconds: _restSeconds,
                          onChanged: _onRestSecondsChanged,
                        )
                      : null,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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
                                service:
                                    ref.read(exerciseReportServiceProvider),
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
                            sessionOverride:
                                _perArmOverrides[exercise.exerciseId],
                          ),
                          onPerArmChanged: (value) {
                            setState(() =>
                                _perArmOverrides[exercise.exerciseId] = value);
                          },
                          bodyWeightKg: ref
                              .watch(profileProvider)
                              .valueOrNull
                              ?.bodyWeight,
                          unitSystem: exerciseUnit,
                          onUnitSystemChanged: (value) {
                            setState(() =>
                                _unitOverrides[exercise.exerciseId] = value);
                          },
                        ),
                      ],
                      if (lastSessionLabel != null) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: Icon(
                              Icons.history,
                              size: 16,
                              color: context.accentColor,
                            ),
                            label: Text(lastSessionLabel),
                            side: BorderSide(
                              color:
                                  context.accentColor.withValues(alpha: 0.35),
                            ),
                            backgroundColor:
                                context.accentColor.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (_isHyroxWorkout)
                        ..._buildHyroxStation(
                          displayWorkout: displayWorkout,
                          exercise: exercise,
                          sets: sortedSets,
                          visibleExercises: visibleExercises,
                          unitSystem: exerciseUnit,
                          isCardio: isCardio,
                          cardioConfig: cardioConfig,
                        )
                      else ...[
                        ...sortedSets.asMap().entries.map(
                          (entry) {
                            if (isCardio) {
                              return _anchorRemoveSet(
                                highlight: entry.key == sortedSets.length - 1,
                                child: CardioSetLogTile(
                                  key: ValueKey(entry.value.id),
                                  set: entry.value,
                                  unitSystem: exerciseUnit,
                                  config: cardioConfig,
                                  isLast: entry.key == sortedSets.length - 1,
                                  isSaving:
                                      _savingSetIds.contains(entry.value.id),
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
                                    isLastSet:
                                        entry.key == sortedSets.length - 1,
                                    cardioConfig: cardioConfig,
                                  ),
                                  onDelete: () {
                                    setState(() =>
                                        _removedSetIds.add(entry.value.id));
                                    unawaited(_deleteSet(
                                        displayWorkout, exercise, entry.value));
                                  },
                                ),
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
                              sessionOverride:
                                  _perArmOverrides[exercise.exerciseId],
                            );
                            final weightOptional =
                                ExerciseLoad.weightOptionalForExerciseId(
                                      exercise.exerciseId,
                                      exerciseCatalog,
                                      exerciseName: exercise.exerciseName,
                                    ) ??
                                    false;
                            return _anchorRemoveSet(
                              highlight: entry.key == sortedSets.length - 1,
                              child: SetLogTile(
                                key: ValueKey(entry.value.id),
                                set: entry.value,
                                unitSystem: exerciseUnit,
                                exerciseName: exercise.exerciseName,
                                perArmWeight: perArm,
                                weightOptional: weightOptional,
                                loadMode: loadMode,
                                useLegLabel: ExerciseLoad.isLowerBodySideLoad(
                                  exerciseName: exercise.exerciseName,
                                  exerciseId: exercise.exerciseId,
                                  catalog: exerciseCatalog,
                                ),
                                bodyWeightKg: ref
                                    .watch(profileProvider)
                                    .valueOrNull
                                    ?.bodyWeight,
                                isLast: entry.key == sortedSets.length - 1,
                                isSaving:
                                    _savingSetIds.contains(entry.value.id),
                                requestFocus: _focusSetId == entry.value.id,
                                onFocusHandled: () {
                                  if (_focusSetId == entry.value.id) {
                                    setState(() => _focusSetId = null);
                                  }
                                },
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
                                  setState(
                                      () => _removedSetIds.add(entry.value.id));
                                  unawaited(_deleteSet(
                                      displayWorkout, exercise, entry.value));
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: TutorialTargets.workoutAddSetKey,
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
                if (MediaQuery.viewInsetsOf(context).bottom <= 80)
                  _ExerciseNavigator(
                    l10n: l10n,
                    currentIndex: SupersetGroups.blockIndexOf(
                        visibleExercises, exercise.id),
                    total:
                        SupersetGroups.workoutBlocks(visibleExercises).length,
                    completing: _completing,
                    onPrevious: () {
                      final previousIndex =
                          SupersetGroups.resolvePreviousBlockWorkoutIndex(
                        workoutExercises: displayWorkout.exercises,
                        visibleExercises: visibleExercises,
                        currentExerciseId: exercise.id,
                      );
                      if (previousIndex != null) {
                        setState(() => _currentExerciseIndex = previousIndex);
                      }
                    },
                    onNext: () {
                      final nextIndex =
                          SupersetGroups.resolveNextBlockWorkoutIndex(
                        workoutExercises: displayWorkout.exercises,
                        visibleExercises: visibleExercises,
                        currentExerciseId: exercise.id,
                      );
                      if (nextIndex != null) {
                        setState(() => _currentExerciseIndex = nextIndex);
                      }
                    },
                    onEndTraining: () =>
                        _requestCompleteWorkout(displayWorkout),
                    hasPrevious: SupersetGroups.hasPreviousBlock(
                        visibleExercises, exercise.id),
                    hasNext: SupersetGroups.hasNextBlock(
                        visibleExercises, exercise.id),
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

  Widget _buildSupersetLogger({
    required Workout displayWorkout,
    required List<WorkoutExercise> members,
    required List<WorkoutExercise> visibleExercises,
    required String unitSystem,
    required List<Exercise> exerciseCatalog,
    required AppLocalizations l10n,
  }) {
    final round = SupersetGroups.currentRound(members);
    final totalRounds = SupersetGroups.roundCount(members);
    final currentExercise = displayWorkout.exercises[
        _currentExerciseIndex.clamp(0, displayWorkout.exercises.length - 1)];
    final bodyWeightKg = ref.watch(profileProvider).valueOrNull?.bodyWeight;

    return Column(
      children: [
        WorkoutElapsedTimer(
          startedAt: _elapsedTimerStart(displayWorkout),
          stoppedAt: _workoutTimerStop(),
        ),
        if (_idlePausedAt != null && !_skipIdleGuard)
          _buildIdlePauseBanner(l10n),
        if (_showRestTimer) _buildActiveRestTimer(),
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(l10n.groupedSetKind(members.length)),
                      side: BorderSide(
                          color: context.accentColor.withValues(alpha: 0.4)),
                      backgroundColor:
                          context.accentColor.withValues(alpha: 0.1),
                    ),
                    const Spacer(),
                    RestTimeSelector(
                      key: TutorialTargets.workoutRestKey,
                      selectedSeconds: _restSeconds,
                      onChanged: _onRestSecondsChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        totalRounds == 0
                            ? l10n.noSets
                            : l10n.supersetRound(round, totalRounds),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: Icon(
                        Icons.repeat,
                        size: 16,
                        color: context.accentColor,
                      ),
                      label: Text(l10n.supersetRoundsCount(totalRounds)),
                      onPressed: totalRounds == 0
                          ? null
                          : () => _pickSupersetRounds(displayWorkout, members),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              if (round > 1) ...[
                for (var past = 1; past < round; past++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${l10n.supersetRound(past, totalRounds)} · ${_supersetRoundSummary(members, past, unitSystem)}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 4),
              ],
              for (var i = 0; i < members.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _buildSupersetMemberSection(
                  displayWorkout: displayWorkout,
                  member: members[i],
                  round: round,
                  isActive: members[i].id == currentExercise.id,
                  unitSystem: unitSystem,
                  exerciseCatalog: exerciseCatalog,
                  bodyWeightKg: bodyWeightKg,
                  l10n: l10n,
                  highlightRemoveSet: i == 0,
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: TutorialTargets.workoutAddSetKey,
                onPressed: () => _addSetToSuperset(displayWorkout, members),
                icon: const Icon(Icons.add),
                label: Text(l10n.addSet),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: context.accentColor),
                  foregroundColor: context.accentColor,
                ),
              ),
            ],
          ),
        ),
        if (MediaQuery.viewInsetsOf(context).bottom <= 80)
          _ExerciseNavigator(
            l10n: l10n,
            currentIndex: SupersetGroups.blockIndexOf(
                visibleExercises, currentExercise.id),
            total: SupersetGroups.workoutBlocks(visibleExercises).length,
            completing: _completing,
            onPrevious: () {
              final previousIndex =
                  SupersetGroups.resolvePreviousBlockWorkoutIndex(
                workoutExercises: displayWorkout.exercises,
                visibleExercises: visibleExercises,
                currentExerciseId: currentExercise.id,
              );
              if (previousIndex != null) {
                setState(() => _currentExerciseIndex = previousIndex);
              }
            },
            onNext: () {
              final nextIndex = SupersetGroups.resolveNextBlockWorkoutIndex(
                workoutExercises: displayWorkout.exercises,
                visibleExercises: visibleExercises,
                currentExerciseId: currentExercise.id,
              );
              if (nextIndex != null) {
                setState(() => _currentExerciseIndex = nextIndex);
              }
            },
            onEndTraining: () => _requestCompleteWorkout(displayWorkout),
            hasPrevious: SupersetGroups.hasPreviousBlock(
                visibleExercises, currentExercise.id),
            hasNext: SupersetGroups.hasNextBlock(
                visibleExercises, currentExercise.id),
          ),
      ],
    );
  }

  Widget _buildSupersetMemberSection({
    required Workout displayWorkout,
    required WorkoutExercise member,
    required int round,
    required bool isActive,
    required String unitSystem,
    required List<Exercise> exerciseCatalog,
    required double? bodyWeightKg,
    required AppLocalizations l10n,
    bool highlightRemoveSet = false,
  }) {
    final set = SupersetGroups.setForRound(member, round);
    final letter = SupersetGroups.slotLetter(member.supersetSlot ?? 1);
    final exerciseUnit = _unitOverrides[member.exerciseId] ?? unitSystem;
    final loadMode = ExerciseLoad.loadModeForExerciseId(
      member.exerciseId,
      exerciseCatalog,
      exerciseName: member.exerciseName,
    );
    final perArm = ExerciseLoad.resolvePerArmWeight(
      exerciseId: member.exerciseId,
      catalog: exerciseCatalog,
      exerciseName: member.exerciseName,
      sessionOverride: _perArmOverrides[member.exerciseId],
    );
    final weightOptional = ExerciseLoad.weightOptionalForExerciseId(
          member.exerciseId,
          exerciseCatalog,
          exerciseName: member.exerciseName,
        ) ??
        false;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? context.accentColor.withValues(alpha: 0.7)
              : AppColors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: context.accentColor.withValues(alpha: 0.18),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: context.accentColor,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ExerciseThumbnail(
                  exerciseId: member.exerciseId,
                  exerciseName: member.exerciseName,
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => ExerciseImageViewer.open(
                    context,
                    exerciseId: member.exerciseId,
                    exerciseName: member.exerciseName,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LocalizedExerciseName(
                    member.exerciseName,
                    exerciseId: member.exerciseId,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: l10n.exerciseHistory,
                  onPressed: () => ExerciseHistorySheet.show(
                    context,
                    exerciseId: member.exerciseId,
                    exerciseName: member.exerciseName,
                    excludeWorkoutId: displayWorkout.id,
                  ),
                  icon: const Icon(Icons.history, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExerciseLoadControls(
              exerciseId: member.exerciseId,
              exerciseName: member.exerciseName,
              catalog: exerciseCatalog,
              perArmEnabled: perArm,
              onPerArmChanged: (value) {
                setState(() => _perArmOverrides[member.exerciseId] = value);
              },
              bodyWeightKg: bodyWeightKg,
              unitSystem: exerciseUnit,
              onUnitSystemChanged: (value) {
                setState(() => _unitOverrides[member.exerciseId] = value);
              },
            ),
            if (set != null)
              _anchorRemoveSet(
                highlight: highlightRemoveSet,
                child: SetLogTile(
                  key: ValueKey(set.id),
                  set: set,
                  unitSystem: exerciseUnit,
                  exerciseName: member.exerciseName,
                  perArmWeight: perArm,
                  weightOptional: weightOptional,
                  loadMode: loadMode,
                  useLegLabel: ExerciseLoad.isLowerBodySideLoad(
                    exerciseName: member.exerciseName,
                    exerciseId: member.exerciseId,
                    catalog: exerciseCatalog,
                  ),
                  bodyWeightKg: bodyWeightKg,
                  isLast: true,
                  isSaving: _savingSetIds.contains(set.id),
                  requestFocus: _focusSetId == set.id,
                  onFocusHandled: () {
                    if (_focusSetId == set.id) {
                      setState(() => _focusSetId = null);
                    }
                  },
                  onValidationError: (message) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  },
                  onChanged: (updated) => _logSet(
                    displayWorkout,
                    member,
                    updated,
                    wasAlreadyCompleted: set.completed,
                    isCardio: false,
                    isLastSet: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _supersetRoundSummary(
    List<WorkoutExercise> members,
    int round,
    String unitSystem,
  ) {
    final parts = <String>[];
    for (final member in members) {
      final set = SupersetGroups.setForRound(member, round);
      if (set == null) continue;
      final letter = SupersetGroups.slotLetter(member.supersetSlot ?? 1);
      final weight = set.weight == null
          ? ''
          : '×${GymWeight.formatDisplay(set.weight!, unitSystem)}';
      parts.add('$letter ${set.reps}$weight');
    }
    return parts.join(' · ');
  }

  Future<void> _addSetToSuperset(
    Workout workout,
    List<WorkoutExercise> members,
  ) async {
    if (SupersetGroups.roundCount(members) >= SupersetGroups.maxRounds) return;
    await _setSupersetRounds(
      workout,
      members,
      SupersetGroups.roundCount(members) + 1,
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
      final w = UnitConverter.formatGymMass(weight, unitSystem);
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
    bool fromWatch = false,
    int? watchRir,
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

    int? rir = set.rir;
    if (!wasAlreadyCompleted && !isCardio && mounted && !_isHyroxWorkout) {
      if (fromWatch) {
        rir = watchRir;
      } else {
        rir = await RirPickerSheet.show(context);
      }
    }

    final stationSeconds =
        (_isHyroxWorkout && _stationStartedAt != null && !wasAlreadyCompleted)
            ? (_workoutStoppedAt ?? DateTime.now())
                .difference(_stationStartedAt!)
                .inSeconds
                .clamp(1, 24 * 3600)
            : null;

    final completedSet = set.copyWith(
      completed: true,
      rir: rir,
      loggingType:
          isCardio ? ExerciseLoggingType.cardio : ExerciseLoggingType.strength,
      durationSeconds: stationSeconds ?? set.durationSeconds,
    );

    WorkoutSet? adjustedNextSet;
    int? nextExerciseIndex;
    var startRest = false;
    if (!wasAlreadyCompleted && !isCardio && !_isHyroxWorkout) {
      final String resolvedUnit =
          _unitOverrides[exercise.exerciseId] ?? ref.read(unitSystemProvider);
      final sorted = _sortedSets(exercise);
      for (final candidate in sorted) {
        if (candidate.setNumber <= set.setNumber) continue;
        final effective = candidate.id == set.id
            ? completedSet
            : (_setOverrides[candidate.id] ?? candidate);
        if (effective.completed) continue;
        final selectedRir = rir;
        if (selectedRir != null) {
          final baseline =
              _rirWeightBaselines[effective.id] ?? effective.weight;
          if (baseline != null && baseline > 0) {
            _rirWeightBaselines[effective.id] = baseline;
            final nextKg = RirWeightAdjustment.apply(
              baselineKg: baseline,
              rir: selectedRir,
              unitSystem: resolvedUnit,
            );
            if (nextKg != null &&
                (effective.weight == null ||
                    (effective.weight! - nextKg).abs() > 0.01)) {
              adjustedNextSet = effective.copyWith(weight: nextKg);
            }
          }
        }
        break;
      }

      final groupMembers = SupersetGroups.membersOf(
        workout.exercises
            .where((e) => !_removedExerciseIds.contains(e.id))
            .toList(),
        exercise.supersetGroupId,
      );
      if (groupMembers.length >= 2) {
        final patchedGroup = groupMembers.map((m) {
          final sets = m.sets
              .map((s) {
                if (s.id == completedSet.id) return completedSet;
                if (adjustedNextSet != null && s.id == adjustedNextSet.id) {
                  return adjustedNextSet;
                }
                return _setOverrides[s.id] ?? s;
              })
              .where((s) => !_removedSetIds.contains(s.id))
              .toList();
          return m.copyWith(sets: sets);
        }).toList();

        final nextInRound = SupersetGroups.nextMemberInRound(
          patchedGroup,
          exercise.id,
          completedSet.setNumber,
        );
        if (nextInRound != null) {
          final index =
              workout.exercises.indexWhere((e) => e.id == nextInRound.id);
          if (index >= 0) nextExerciseIndex = index;
        } else {
          final nextMember =
              SupersetGroups.activeMember(patchedGroup) ?? patchedGroup.first;
          final index =
              workout.exercises.indexWhere((e) => e.id == nextMember.id);
          if (index >= 0) nextExerciseIndex = index;
        }
        startRest = SupersetGroups.isRoundComplete(
            patchedGroup, completedSet.setNumber);
      } else {
        startRest = true;
      }
    }

    if (!wasAlreadyCompleted) {
      _markWorkoutActivity();
    }

    setState(() {
      _setOverrides[set.id] = completedSet;
      if (adjustedNextSet != null) {
        _setOverrides[adjustedNextSet.id] = adjustedNextSet;
      }
      _savingSetIds.add(set.id);
      if (nextExerciseIndex != null) _currentExerciseIndex = nextExerciseIndex;
    });

    if (startRest) {
      _startRestTimer();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    });
    unawaited(_publishWatchSession(workout));

    final persist = _persistSet(
      exercise,
      completedSet,
      setId: set.id,
    );
    if (adjustedNextSet != null) {
      unawaited(
        _persistSet(
          exercise,
          adjustedNextSet,
          setId: adjustedNextSet.id,
        ),
      );
    }
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
      await ref.read(workoutServiceProvider).deleteSet(
            exercise.id,
            setId,
            workoutId: workout.id,
          );
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
    final previous =
        await ref.read(workoutServiceProvider).getPreviousSetsForExercise(
              exercise.exerciseId,
              excludeWorkoutId: workout.id,
            );
    final setNumber = sorted.length + 1;
    final prevSet = sorted.isNotEmpty
        ? sorted.last
        : (previous != null
            ? ref
                .read(workoutServiceProvider)
                .previousSetForNumber(previous, setNumber)
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
      distanceMeters:
          isCardio || isLoadedDistance ? prevSet?.distanceMeters : null,
      inclinePercent: isCardio ? prevSet?.inclinePercent : null,
      steps: isCardio ? prevSet?.steps : null,
      loggingType:
          isCardio ? ExerciseLoggingType.cardio : ExerciseLoggingType.strength,
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

  String? _lastSessionChipLabel(
    List<ExerciseSessionHistory> history,
    String unitSystem,
    AppLocalizations l10n,
  ) {
    if (history.isEmpty) return null;
    final sets = history.first.sets;
    final working = ExerciseHistoryUtils.workingSets(sets);
    final source = working.isNotEmpty
        ? working
        : PreviousSetUtils.sortedMeaningfulSets(sets);
    if (source.isEmpty) return null;
    final set = source.last;
    final weight = set.weight;
    if (weight != null && weight > 0) {
      final display = GymWeight.formatDisplay(weight, unitSystem);
      if (set.reps > 0) {
        return l10n.lastSessionChip('$display×${set.reps}');
      }
      if ((set.distanceMeters ?? 0) > 0) {
        return l10n.lastSessionChip('$display×${set.distanceMeters!.round()}m');
      }
      return l10n.lastSessionChip(display);
    }
    if (set.reps > 0) return l10n.lastSessionChip(l10n.repsOnly(set.reps));
    return null;
  }
}

class _PinnedExerciseHeader extends StatelessWidget {
  final String exerciseId;
  final String exerciseName;
  final Widget? restSelector;

  const _PinnedExerciseHeader({
    required this.exerciseId,
    required this.exerciseName,
    this.restSelector,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(
          children: [
            ExerciseThumbnail(
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(10),
              onTap: () => ExerciseImageViewer.open(
                context,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LocalizedExerciseName(
                exerciseName,
                exerciseId: exerciseId,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (restSelector != null) ...[
              const SizedBox(width: 8),
              restSelector!,
            ],
          ],
        ),
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
  final Future<void> Function()? onEndTraining;
  final bool hasPrevious;
  final bool hasNext;
  final bool completing;

  const _ExerciseNavigator({
    required this.l10n,
    required this.currentIndex,
    required this.total,
    required this.hasPrevious,
    required this.hasNext,
    this.completing = false,
    this.onPrevious,
    this.onNext,
    this.onEndTraining,
  });

  @override
  Widget build(BuildContext context) {
    final isLastExercise = !hasNext;

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
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted),
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
                  child: isLastExercise
                      ? ElevatedButton.icon(
                          onPressed:
                              completing ? null : () => onEndTraining?.call(),
                          icon: const Icon(Icons.flag_outlined, size: 18),
                          label: Text(l10n.endTraining),
                        )
                      : ElevatedButton.icon(
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
