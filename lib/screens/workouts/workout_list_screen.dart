import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../../models/exercise_logging.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/muscle_recovery_map.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/workout_tile.dart';
import '../../core/router/app_router.dart';

class WorkoutListScreen extends ConsumerWidget {
  static const _previewCount = 7;
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final recentAsync = ref.watch(recentWorkoutsProvider);
    final activeAsync = ref.watch(activeWorkoutProvider);
    final recoveryAsync = ref.watch(muscleRecoveryProvider);
    final routinesAsync = ref.watch(routinesProvider);

    return Scaffold(
      appBar: const FitForgeAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentWorkoutsProvider);
          ref.invalidate(activeWorkoutProvider);
          ref.invalidate(muscleRecoveryProvider);
          ref.invalidate(workoutWeeklyStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            activeAsync.when(
              data: (active) {
                if (active != null) {
                  return _ActiveWorkoutBanner(workout: active);
                }
                return _StartWorkoutSection(routinesAsync: routinesAsync);
              },
              loading: () => _StartWorkoutSection(routinesAsync: routinesAsync),
              error: (_, __) => _StartWorkoutSection(routinesAsync: routinesAsync),
            ),
            const SizedBox(height: 20),
            recoveryAsync.when(
              data: (recovery) => MuscleRecoveryMap(recovery: recovery),
              loading: () => MuscleRecoveryMap(recovery: fullMuscleRecoveryMap()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text(l10n.history, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            recentAsync.when(
              data: (workouts) {
                if (workouts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(l10n.noWorkoutsYet)),
                  );
                }
                final preview = workouts.take(_previewCount).toList();
                final hasMore = workouts.length > _previewCount;
                return Column(
                  children: [
                    ...preview.map(
                      (w) => WorkoutTile(workout: w, unitSystem: ref.watch(unitSystemProvider)),
                    ),
                    if (hasMore) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => context.push('/workouts/history'),
                          icon: const Icon(Icons.history),
                          label: Text(l10n.viewFullHistory),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const FitForgeLoadingScreen(),
              error: (e, _) => Text(l10n.errorGeneric('$e')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveWorkoutBanner extends StatelessWidget {
  final Workout workout;

  const _ActiveWorkoutBanner({required this.workout});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      color: AppColors.orange.withValues(alpha: 0.12),
      child: ListTile(
        leading: Icon(Icons.play_circle_fill, size: 40, color: AppColors.orange),
        title: Text(l10n.workoutDisplayName(workout.name), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(l10n.activeWorkout),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/workout/active'),
      ),
    );
  }
}

class _StartWorkoutSection extends ConsumerWidget {
  final AsyncValue<List<Routine>> routinesAsync;

  const _StartWorkoutSection({required this.routinesAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statsAsync = ref.watch(workoutWeeklyStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        statsAsync.when(
          data: (stats) => Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.local_fire_department,
                  label: l10n.streakWeekly,
                  value: l10n.streakWeeksLabel(stats.streakWeeks),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.fitness_center,
                  label: l10n.thisWeek,
                  value: stats.weekProgressLabel,
                ),
              ),
            ],
          ),
          loading: () => Row(
            children: [
              Expanded(child: StatCard(icon: Icons.local_fire_department, label: l10n.streakLabel, value: '…')),
              const SizedBox(width: 12),
              Expanded(child: StatCard(icon: Icons.fitness_center, label: l10n.thisWeek, value: '…')),
            ],
          ),
          error: (_, __) => Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.local_fire_department,
                  label: l10n.streakWeekly,
                  value: '0',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.fitness_center,
                  label: l10n.thisWeek,
                  value: '0/4',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showStartOptions(context, ref),
          icon: const Icon(Icons.add),
          label: Text(l10n.startWorkout),
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ],
    );
  }

  Future<void> _startAndOpenWorkout(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() start,
  ) async {
    final l10n = context.l10n;
    if (!context.mounted) return;

    final router = ref.read(routerProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      await FitForgeLoadingOverlay.run(
        context,
        message: l10n.startingWorkout,
        task: () async {
          await start();
          ref.invalidate(activeWorkoutProvider);
          await ref.read(activeWorkoutProvider.future);
        },
      );
      router.push('/workout/active');
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.startWorkoutError('$e'))),
      );
    }
  }

  void _showStartOptions(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                    leading: const Icon(Icons.flash_on),
                    title: Text(l10n.freeWorkout),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _startAndOpenWorkout(context, ref, () async {
                        await ref.read(workoutServiceProvider).startWorkout(
                              name: l10n.freeWorkout,
                            );
                      });
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
                            final r = routines[index];
                            return ListTile(
                              leading: const Icon(Icons.list_alt),
                              title: Text(r.name),
                              subtitle: Text(l10n.exercisesInRoutine(r.exercises.length)),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final exercises = r.exercises
                                    .map(
                                      (e) => WorkoutExercise(
                                        id: '',
                                        exerciseId: e.exerciseId,
                                        exerciseName: e.exerciseName,
                                        imageUrl: e.imageUrl,
                                        orderIndex: e.orderIndex,
                                        sets: List.generate(
                                          e.targetSets,
                                          (i) => WorkoutSet(
                                            id: '',
                                            setNumber: i + 1,
                                            weight: e.isCardio ? null : e.targetWeight,
                                            reps: e.isCardio ? 0 : e.targetReps,
                                            loggingType: e.loggingType,
                                            durationSeconds: e.targetDurationSeconds,
                                            distanceMeters: e.targetDistanceMeters,
                                            inclinePercent: e.targetInclinePercent,
                                            steps: e.targetSteps,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList();
                                await _startAndOpenWorkout(context, ref, () async {
                                  await ref.read(workoutServiceProvider).startWorkout(
                                        name: r.name,
                                        routineId: r.id,
                                        exercises: exercises,
                                      );
                                });
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
}
