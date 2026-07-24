import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/hyrox/hyrox_validation.dart';
import '../../core/workout/workout_validation.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/workout_summary.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_loading_indicator.dart';

/// Abre el resumen (y share card) de un entreno completado por id.
Future<void> openCompletedWorkoutSummary(
  BuildContext context,
  WidgetRef ref,
  String workoutId,
) async {
  if (!context.mounted) return;

  try {
    final summary = await FitForgeLoadingOverlay.run(
      context,
      message: context.l10n.loadingWorkoutSummary,
      task: () async {
        final workout = await ref.read(workoutServiceProvider).getCompletedWorkoutById(workoutId);
        if (workout == null) return null;

        final catalog = await ref.read(exercisesProvider.future);
        final profile = await ref.read(profileProvider.future);
        final previous = workout.routineId == null
            ? null
            : await ref.read(workoutServiceProvider).getPreviousRoutineWorkout(
                  routineId: workout.routineId,
                  excludeWorkoutId: workout.id,
                );

        final isRunner = workout.runnerRoute.isNotEmpty || workout.runnerSurface != null;
        final isHyrox = workout.hyroxValidationStatus != null;

        HyroxValidationResult? hyroxValidation;
        if (workout.hyroxValidationStatus != null) {
          hyroxValidation = HyroxValidationResult(
            status: workout.hyroxValidationStatus!,
            reasons: workout.hyroxValidationReasons,
          );
        }

        WorkoutValidationResult? validation;
        if (workout.validationStatus != null) {
          validation = WorkoutValidationResult(
            status: workout.validationStatus!,
            reasons: workout.validationReasons,
          );
        }

        return WorkoutSummaryBuilder.build(
          workout: workout,
          durationMinutes: workout.durationMinutes,
          previousSameRoutine: previous,
          exerciseCatalog: catalog,
          profile: profile,
          isHyrox: isHyrox,
          isRunner: isRunner,
          hyroxValidation: hyroxValidation,
          validation: validation,
        );
      },
    );

    if (!context.mounted) return;

    if (summary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.workoutSummaryNotFound)),
      );
      return;
    }

    ref.read(pendingWorkoutSummaryProvider.notifier).state = summary;
    ref.read(workoutSummarySessionIdProvider.notifier).state = summary.workout.id;
    await context.push('/workout/summary', extra: summary);
    ref.read(pendingWorkoutSummaryProvider.notifier).state = null;
    ref.read(workoutSummarySessionIdProvider.notifier).state = null;
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.errorGeneric('$e'))),
    );
  }
}
