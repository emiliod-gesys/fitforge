import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../screens/workouts/log_past_workout_screen.dart';
import '../../screens/workouts/workout_start_helper.dart';
import '../../widgets/fitforge_loading_indicator.dart';

bool _isGymRoutine(Routine routine) =>
    !routine.isHyroxSystem && !routine.isRunnerSystem;

Future<void> showRoutineStartChoices(
  BuildContext context,
  WidgetRef ref,
  Routine routine,
) async {
  if (routine.isRunnerSystem) {
    await startRunnerWorkoutFromRoutine(context, ref, routine);
    return;
  }
  if (routine.isHyroxSystem) {
    await startWorkoutFromRoutine(context, ref, routine);
    return;
  }

  final l10n = context.l10n;
  final parentContext = context;

  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  routine.name,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.play_arrow_rounded, color: context.accentColor),
              title: Text(l10n.startWorkout),
              onTap: () async {
                Navigator.pop(ctx);
                if (!parentContext.mounted) return;
                await startWorkoutFromRoutine(parentContext, ref, routine);
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: context.accentColor),
              title: Text(l10n.logPastWorkout),
              subtitle: Text(l10n.logPastWorkoutSubtitle),
              onTap: () async {
                Navigator.pop(ctx);
                if (!parentContext.mounted) return;
                await openLogPastWorkout(
                  parentContext,
                  ref,
                  name: routine.name,
                  routineId: routine.id,
                  exercises: workoutExercisesFromRoutine(routine),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<void> showTrainStartSheet(
  BuildContext context,
  WidgetRef ref, {
  required AsyncValue<List<Routine>> routinesAsync,
}) {
  final l10n = context.l10n;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.85;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.history, color: context.accentColor),
                  title: Text(l10n.logPastWorkout),
                  subtitle: Text(l10n.logPastWorkoutSubtitle),
                  onTap: () {
                    Navigator.pop(ctx);
                    showLogPastStartSheet(context, ref, routinesAsync: routinesAsync);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.flash_on, color: context.accentColor),
                  title: Text(l10n.freeWorkout),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await startWorkoutAndNavigate(
                      context,
                      ref,
                      name: l10n.freeWorkout,
                    );
                  },
                ),
                const Divider(height: 1),
                Flexible(
                  child: routinesAsync.when(
                    data: (routines) {
                      if (routines.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.noRoutines,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: routines.length,
                        itemBuilder: (context, index) {
                          final routine = routines[index];
                          return ListTile(
                            leading: const Icon(Icons.list_alt),
                            title: Text(routine.name),
                            subtitle: Text(l10n.exercisesInRoutine(routine.exercises.length)),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await startWorkoutFromRoutine(context, ref, routine);
                            },
                          );
                        },
                      );
                    },
                    loading: () => ListTile(title: Text(l10n.loadingRoutines)),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showLogPastStartSheet(
  BuildContext context,
  WidgetRef ref, {
  required AsyncValue<List<Routine>> routinesAsync,
}) {
  final l10n = context.l10n;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.85;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.logPastWorkout,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.flash_on, color: context.accentColor),
                  title: Text(l10n.logPastFreeWorkout),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (!context.mounted) return;
                    await openLogPastWorkout(
                      context,
                      ref,
                      name: l10n.freeWorkout,
                      exercises: const [],
                    );
                  },
                ),
                const Divider(height: 1),
                Flexible(
                  child: routinesAsync.when(
                    data: (routines) {
                      final gymRoutines = routines.where(_isGymRoutine).toList();
                      if (gymRoutines.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.logPastNoGymRoutines,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: gymRoutines.length,
                        itemBuilder: (_, index) {
                          final routine = gymRoutines[index];
                          return ListTile(
                            leading: const Icon(Icons.list_alt),
                            title: Text(routine.name),
                            subtitle: Text(l10n.exercisesInRoutine(routine.exercises.length)),
                            onTap: () async {
                              Navigator.pop(ctx);
                              if (!context.mounted) return;
                              await openLogPastWorkout(
                                context,
                                ref,
                                name: routine.name,
                                routineId: routine.id,
                                exercises: workoutExercisesFromRoutine(routine),
                              );
                            },
                          );
                        },
                      );
                    },
                    loading: () => ListTile(title: Text(l10n.loadingRoutines)),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> openLogPastWorkout(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  String? routineId,
  required List<WorkoutExercise> exercises,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);

  final active = ref.read(activeWorkoutProvider).valueOrNull;
  if (active != null) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.logPastActiveWorkoutExists)));
    return;
  }

  try {
    final prepared = await FitForgeLoadingOverlay.run(
      context,
      message: l10n.loadingRoutines,
      task: () => ref.read(workoutServiceProvider).preparePastLogExercises(exercises),
    );
    if (!context.mounted) return;
    context.push(
      '/workout/log-past',
      extra: LogPastWorkoutArgs(
        name: name,
        routineId: routineId,
        exercises: prepared,
      ),
    );
  } catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.logPastSaveFailed('$e'))));
  }
}
