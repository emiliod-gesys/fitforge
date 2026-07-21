import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n_extensions.dart';
import '../../models/workout_summary.dart';
import '../../providers/app_providers.dart';

/// Abre el resumen (y share card) de un entreno completado por id.
Future<void> openCompletedWorkoutSummary(
  BuildContext context,
  WidgetRef ref,
  String workoutId,
) async {
  if (!context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final workout = await ref.read(workoutServiceProvider).getCompletedWorkoutById(workoutId);
    if (!context.mounted) return;

    if (workout == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.workoutSummaryNotFound)),
      );
      return;
    }

    final catalog = await ref.read(exercisesProvider.future);
    final profile = await ref.read(profileProvider.future);
    if (!context.mounted) return;

    final summary = WorkoutSummaryBuilder.build(
      workout: workout,
      durationMinutes: workout.durationMinutes,
      exerciseCatalog: catalog,
      profile: profile,
    );

    Navigator.of(context).pop();
    if (!context.mounted) return;

    ref.read(pendingWorkoutSummaryProvider.notifier).state = summary;
    await context.push('/workout/summary', extra: summary);
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.errorGeneric('$e'))),
    );
  }
}
