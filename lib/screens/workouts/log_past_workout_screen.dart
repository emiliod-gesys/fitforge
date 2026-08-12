import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/exercise_load.dart';
import '../../core/utils/exercise_logging_resolver.dart';
import '../../core/utils/workout_calorie_estimator.dart';
import '../../core/workout/workout_validation.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/body_metric.dart';
import '../../models/exercise.dart';
import '../../models/exercise_logging.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../services/exercise_service.dart';
import '../../widgets/cardio_set_log_tile.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/localized_exercise_name.dart';
import '../../widgets/set_log_tile.dart';
import '../../widgets/workout_exercise_picker_sheet.dart';
import 'workout_summary_helper.dart';

class LogPastWorkoutArgs {
  final String name;
  final String? routineId;
  final List<WorkoutExercise> exercises;

  const LogPastWorkoutArgs({
    required this.name,
    this.routineId,
    required this.exercises,
  });
}

class LogPastWorkoutScreen extends ConsumerStatefulWidget {
  final LogPastWorkoutArgs args;

  const LogPastWorkoutScreen({super.key, required this.args});

  @override
  ConsumerState<LogPastWorkoutScreen> createState() => _LogPastWorkoutScreenState();
}

class _LogPastWorkoutScreenState extends ConsumerState<LogPastWorkoutScreen> {
  static const _uuid = Uuid();

  late List<WorkoutExercise> _exercises;
  late final TextEditingController _durationController;
  late DateTime _completedDay;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _exercises = List<WorkoutExercise>.from(widget.args.exercises);
    _durationController = TextEditingController(text: '45');
    final now = DateTime.now();
    _completedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  int get _completedSetCount =>
      _exercises.expand((e) => e.sets).where((s) => s.completed).length;

  void _replaceExercise(int index, WorkoutExercise exercise) {
    setState(() {
      _exercises = [..._exercises]..[index] = exercise;
    });
  }

  void _updateSet(int exerciseIndex, WorkoutSet set) {
    final exercise = _exercises[exerciseIndex];
    final sets = exercise.sets.map((s) => s.id == set.id ? set : s).toList();
    _replaceExercise(
      exerciseIndex,
      WorkoutExercise(
        id: exercise.id,
        exerciseId: exercise.exerciseId,
        exerciseName: exercise.exerciseName,
        imageUrl: exercise.imageUrl,
        orderIndex: exercise.orderIndex,
        notes: exercise.notes,
        sets: sets,
      ),
    );
  }

  void _addSet(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    final last = exercise.sets.isEmpty ? null : exercise.sets.last;
    final loggingType = last?.loggingType ??
        ExerciseLoggingResolver.resolveLoggingType(
          exerciseId: exercise.exerciseId,
          exerciseName: exercise.exerciseName,
          catalog: ref.read(exercisesProvider).valueOrNull ?? [],
        );
    final next = WorkoutSet(
      id: _uuid.v4(),
      setNumber: exercise.sets.length + 1,
      weight: last?.weight,
      reps: last?.reps ?? 0,
      loggingType: loggingType,
      durationSeconds: last?.durationSeconds,
      distanceMeters: last?.distanceMeters,
      inclinePercent: last?.inclinePercent,
      steps: last?.steps,
    );
    _replaceExercise(
      exerciseIndex,
      WorkoutExercise(
        id: exercise.id,
        exerciseId: exercise.exerciseId,
        exerciseName: exercise.exerciseName,
        imageUrl: exercise.imageUrl,
        orderIndex: exercise.orderIndex,
        notes: exercise.notes,
        sets: [...exercise.sets, next],
      ),
    );
  }

  void _deleteSet(int exerciseIndex, String setId) {
    final exercise = _exercises[exerciseIndex];
    final sets = <WorkoutSet>[];
    for (final s in exercise.sets) {
      if (s.id == setId) continue;
      sets.add(
        WorkoutSet(
          id: s.id,
          setNumber: sets.length + 1,
          weight: s.weight,
          reps: s.reps,
          rir: s.rir,
          completed: s.completed,
          restTaken: s.restTaken,
          durationSeconds: s.durationSeconds,
          distanceMeters: s.distanceMeters,
          inclinePercent: s.inclinePercent,
          steps: s.steps,
          loggingType: s.loggingType,
        ),
      );
    }
    _replaceExercise(
      exerciseIndex,
      WorkoutExercise(
        id: exercise.id,
        exerciseId: exercise.exerciseId,
        exerciseName: exercise.exerciseName,
        imageUrl: exercise.imageUrl,
        orderIndex: exercise.orderIndex,
        notes: exercise.notes,
        sets: sets,
      ),
    );
  }

  void _markAllCompleted() {
    final catalog = ref.read(exercisesProvider).valueOrNull ?? [];
    setState(() {
      _exercises = [
        for (final exercise in _exercises)
          WorkoutExercise(
            id: exercise.id,
            exerciseId: exercise.exerciseId,
            exerciseName: exercise.exerciseName,
            imageUrl: exercise.imageUrl,
            orderIndex: exercise.orderIndex,
            notes: exercise.notes,
            sets: [
              for (final set in exercise.sets)
                _completedSetPreservingValues(set, exercise, catalog),
            ],
          ),
      ];
    });
  }

  WorkoutSet _completedSetPreservingValues(
    WorkoutSet set,
    WorkoutExercise exercise,
    List<Exercise> catalog,
  ) {
    if (set.completed) return set;

    final weightOptional = ExerciseLoad.weightOptionalForExerciseId(
          exercise.exerciseId,
          catalog,
          exerciseName: exercise.exerciseName,
        ) ??
        false;
    final isCardio = set.isCardio ||
        ExerciseLoggingResolver.isCardioExercise(
          exerciseId: exercise.exerciseId,
          exerciseName: exercise.exerciseName,
          sets: exercise.sets,
          catalog: catalog,
        );

    if (isCardio) {
      return WorkoutSet(
        id: set.id,
        setNumber: set.setNumber,
        weight: set.weight,
        reps: set.reps,
        rir: set.rir,
        completed: true,
        restTaken: set.restTaken,
        durationSeconds: set.durationSeconds,
        distanceMeters: set.distanceMeters,
        inclinePercent: set.inclinePercent,
        steps: set.steps,
        loggingType: set.loggingType,
      );
    }

    return WorkoutSet(
      id: set.id,
      setNumber: set.setNumber,
      weight: set.weight ?? (weightOptional ? 0.0 : set.weight),
      reps: set.reps,
      rir: set.rir,
      completed: true,
      restTaken: set.restTaken,
      durationSeconds: set.durationSeconds,
      distanceMeters: set.distanceMeters,
      inclinePercent: set.inclinePercent,
      steps: set.steps,
      loggingType: set.loggingType,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _completedDay,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _completedDay = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _addExercise() async {
    final existingIds = _exercises.map((e) => e.exerciseId).toSet();
    final picked = await WorkoutExercisePickerSheet.show(
      context,
      excludeExerciseIds: existingIds,
    );
    if (picked == null || !mounted) return;

    String? imageUrl = picked.imageUrl;
    if (!picked.isUserCustom) {
      imageUrl = picked.imageUrl ??
          await ref.read(exerciseServiceProvider).resolveImageUrl(
                ExerciseImageLookup(
                  exerciseId: picked.id,
                  exerciseName: picked.name,
                ),
              );
    }

    final loggingType = ExerciseLoggingResolver.loggingTypeFor(
      picked.id,
      ref.read(exercisesProvider).valueOrNull ?? const [],
      exerciseName: picked.name,
    );
    final isCardio = loggingType == ExerciseLoggingType.cardio;

    setState(() {
      _exercises = [
        ..._exercises,
        WorkoutExercise(
          id: _uuid.v4(),
          exerciseId: picked.id,
          exerciseName: picked.name,
          imageUrl: imageUrl,
          orderIndex: _exercises.length,
          sets: [
            WorkoutSet(
              id: _uuid.v4(),
              setNumber: 1,
              loggingType: loggingType,
              reps: isCardio ? 0 : 10,
            ),
          ],
        ),
      ];
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    final duration = int.tryParse(_durationController.text.trim());
    if (duration == null ||
        duration < WorkoutValidator.minDurationMinutesReject ||
        duration > WorkoutValidator.maxDurationMinutesReject) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.logPastDurationInvalid(
              WorkoutValidator.minDurationMinutesReject,
              WorkoutValidator.maxDurationMinutesReject,
            ),
          ),
        ),
      );
      return;
    }

    if (_completedSetCount < 1) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.logPastNeedCompletedSets)));
      return;
    }

    final active = ref.read(activeWorkoutProvider).valueOrNull;
    if (active != null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.logPastActiveWorkoutExists)));
      return;
    }

    setState(() => _saving = true);
    try {
      final catalog = ref.read(exercisesProvider).valueOrNull ?? [];
      final profile = ref.read(profileProvider).valueOrNull;
      final bodyWeightKg = profile?.bodyWeight;
      final draft = Workout(
        id: 'draft',
        userId: '',
        name: widget.args.name,
        routineId: widget.args.routineId,
        startedAt: _completedDay,
        exercises: _exercises,
      );
      final volume = _exercises.fold<double>(
        0,
        (sum, ex) =>
            sum +
            ExerciseLoad.exerciseTotalVolumeKg(
              ex,
              catalog: catalog,
              bodyWeightKg: bodyWeightKg,
            ),
      );
      Map<String, BodyMetricSnapshot>? bodyMetrics;
      try {
        bodyMetrics = await ref.read(bodyMetricSnapshotsProvider.future);
      } catch (_) {
        bodyMetrics = null;
      }
      if (!mounted) return;
      final calorieEstimate = WorkoutCalorieEstimator.estimateForWorkout(
        workout: draft,
        durationMinutes: duration,
        totalVolumeKg: volume,
        profile: profile,
        bodyMetrics: bodyMetrics,
      );

      final completedAt = DateTime(
        _completedDay.year,
        _completedDay.month,
        _completedDay.day,
        12,
      );

      final saved = await FitForgeLoadingOverlay.run(
        context,
        message: l10n.logPastSaving,
        task: () => ref.read(workoutServiceProvider).logPastWorkout(
              name: widget.args.name,
              routineId: widget.args.routineId,
              completedAt: completedAt,
              durationMinutes: duration,
              exercises: _exercises,
              totalVolume: volume,
              activeCaloriesKcal: calorieEstimate.caloriesKcal,
            ),
      );

      if (!mounted) return;

      try {
        await ref.read(profileServiceProvider).awardWorkoutXp(
              workoutId: saved.id,
              totalVolumeKg: volume,
              streakWeeks: 0,
            );
      } catch (_) {}

      ref.invalidate(activeWorkoutProvider);
      ref.invalidate(recentWorkoutsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (!mounted) return;
      await openCompletedWorkoutSummary(context, ref, saved.id);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('active_workout_exists')
          ? l10n.logPastActiveWorkoutExists
          : e.toString().contains('no_completed_sets')
              ? l10n.logPastNeedCompletedSets
              : l10n.logPastSaveFailed('$e');
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unitSystem = ref.watch(unitSystemProvider);
    final catalog = ref.watch(exercisesProvider).valueOrNull ?? [];
    final profile = ref.watch(profileProvider).valueOrNull;

    return Scaffold(
      appBar: FitForgeAppBar(
        title: l10n.logPastWorkoutTitle,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.logPastSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            color: AppColors.card,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.args.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.logPastDurationLabel,
                      helperText: l10n.logPastDurationInvalid(
                        WorkoutValidator.minDurationMinutesReject,
                        WorkoutValidator.maxDurationMinutesReject,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.logPastDateLabel),
                    subtitle: Text(
                      MaterialLocalizations.of(context).formatMediumDate(_completedDay),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: _pickDate,
                  ),
                ],
              ),
            ),
          ),
          if (_exercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ||
                      _exercises.every((e) => e.sets.every((s) => s.completed))
                  ? null
                  : _markAllCompleted,
              icon: const Icon(Icons.done_all),
              label: Text(l10n.logPastMarkAllDone),
            ),
          ],
          const SizedBox(height: 12),
          ...List.generate(_exercises.length, (index) {
            final exercise = _exercises[index];
            final isCardio = ExerciseLoggingResolver.isCardioExercise(
              exerciseId: exercise.exerciseId,
              exerciseName: exercise.exerciseName,
              sets: exercise.sets,
              catalog: catalog,
            );
            final cardioConfig = ExerciseLoggingResolver.cardioConfigFor(
              exerciseId: exercise.exerciseId,
              exerciseName: exercise.exerciseName,
              catalog: catalog,
            );
            final loadMode = ExerciseLoad.loadModeForExerciseId(
              exercise.exerciseId,
              catalog,
              exerciseName: exercise.exerciseName,
            );

            return Card(
              key: ValueKey(exercise.id),
              color: AppColors.card,
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                initiallyExpanded: index == 0,
                title: LocalizedExerciseName(
                  exercise.exerciseName,
                  exerciseId: exercise.exerciseId,
                ),
                subtitle: Text(
                  '${exercise.sets.where((s) => s.completed).length}/${exercise.sets.length}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                children: [
                  for (final set in exercise.sets)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: isCardio
                          ? CardioSetLogTile(
                              set: set,
                              unitSystem: unitSystem,
                              config: cardioConfig,
                              onChanged: (updated) => _updateSet(index, updated),
                              onDelete: () => _deleteSet(index, set.id),
                              onValidationError: (msg) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(msg)),
                                );
                              },
                            )
                          : SetLogTile(
                              set: set,
                              unitSystem: unitSystem,
                              exerciseName: exercise.exerciseName,
                              loadMode: loadMode,
                              weightOptional: ExerciseLoad.weightOptionalForExerciseId(
                                    exercise.exerciseId,
                                    catalog,
                                    exerciseName: exercise.exerciseName,
                                  ) ??
                                  false,
                              bodyWeightKg: profile?.bodyWeight,
                              onChanged: (updated) => _updateSet(index, updated),
                              onDelete: () => _deleteSet(index, set.id),
                              onValidationError: (msg) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(msg)),
                                );
                              },
                            ),
                    ),
                  TextButton.icon(
                    onPressed: () => _addSet(index),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.logPastAddSet),
                  ),
                ],
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: _addExercise,
            icon: const Icon(Icons.add),
            label: Text(l10n.addExercise),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.logPastSave),
          ),
        ],
      ),
    );
  }
}
