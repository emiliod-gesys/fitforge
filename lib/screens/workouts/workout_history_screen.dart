import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/l10n_extensions.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/workout_tile.dart';
import 'workout_summary_helper.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final historyAsync = ref.watch(workoutHistoryProvider);
    final unitSystem = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: FitForgeAppBar(title: l10n.historyTitle),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(workoutHistoryProvider),
        child: historyAsync.when(
          data: (workouts) {
            if (workouts.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text(l10n.noWorkoutsRegistered)),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: workouts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemBuilder: (_, i) {
                final workout = workouts[i];
                return WorkoutTile(
                  workout: workout,
                  unitSystem: unitSystem,
                  onTap: workout.isActive
                      ? null
                      : () => openCompletedWorkoutSummary(context, ref, workout.id),
                );
              },
            );
          },
          loading: () => const FitForgeLoadingScreen(),
          error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
        ),
      ),
    );
  }
}
