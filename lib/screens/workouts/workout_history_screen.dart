import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/workout_tile.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);
    final unitSystem = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: const FitForgeAppBar(title: 'Historial'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(workoutHistoryProvider),
        child: historyAsync.when(
          data: (workouts) {
            if (workouts.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Sin entrenamientos registrados')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: workouts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemBuilder: (_, i) => WorkoutTile(workout: workouts[i], unitSystem: unitSystem),
            );
          },
          loading: () => const FitForgeLoadingScreen(),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
