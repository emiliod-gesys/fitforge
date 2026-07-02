import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/train_suggestion_resolver.dart';
import '../../core/utils/workout_muscle_groups.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/muscle_recovery_map.dart';
import '../../widgets/train/suggested_workout_card.dart';
import '../../widgets/train/train_hero_card.dart';
import '../../widgets/train/train_start_sheet.dart';
import '../../widgets/workout_tile.dart';
import 'workout_start_helper.dart';

class WorkoutTodayTab extends ConsumerWidget {
  const WorkoutTodayTab({super.key});

  static const _previewCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final recentAsync = ref.watch(recentWorkoutsProvider);
    final activeAsync = ref.watch(activeWorkoutProvider);
    final recoveryAsync = ref.watch(muscleRecoveryProvider);
    final routinesAsync = ref.watch(routinesProvider);
    final statsAsync = ref.watch(workoutWeeklyStatsProvider);
    final catalog = ref.watch(exercisesProvider).valueOrNull ?? [];

    Future<void> onRefresh() async {
      HapticFeedback.lightImpact();
      ref.invalidate(recentWorkoutsProvider);
      ref.invalidate(activeWorkoutProvider);
      ref.invalidate(muscleRecoveryProvider);
      ref.invalidate(workoutWeeklyStatsProvider);
      ref.invalidate(routinesProvider);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          activeAsync.when(
            data: (active) {
              if (active != null) {
                return _ActiveWorkoutBanner(workout: active);
              }
              return TrainHeroCard(
                stats: statsAsync.valueOrNull,
                isLoading: statsAsync.isLoading,
                onStartWorkout: () => showTrainStartSheet(context, ref, routinesAsync: routinesAsync),
              );
            },
            loading: () => _HeroSkeleton(),
            error: (_, __) => TrainHeroCard(
              stats: statsAsync.valueOrNull,
              isLoading: statsAsync.isLoading,
              onStartWorkout: () => showTrainStartSheet(context, ref, routinesAsync: routinesAsync),
            ),
          ),
          const SizedBox(height: 20),
          recoveryAsync.when(
            data: (recovery) => MuscleRecoveryMap(
              recovery: recovery,
              compact: true,
            ),
            loading: () => MuscleRecoveryMap(
              recovery: fullMuscleRecoveryMap(),
              compact: true,
              isLoading: true,
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          routinesAsync.when(
            data: (routines) {
              final recent = recentAsync.valueOrNull ?? const <Workout>[];
              final recovery = recoveryAsync.valueOrNull ?? fullMuscleRecoveryMap();
              final suggestion = TrainSuggestionResolver.resolve(
                routines: routines,
                recentWorkouts: recent,
                recovery: recovery,
                catalog: catalog,
              );
              if (suggestion == null || activeAsync.valueOrNull != null) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  SuggestedWorkoutCard(
                    routine: suggestion.routine,
                    reason: suggestion.reason,
                    onStart: () => startWorkoutFromRoutine(context, ref, suggestion.routine),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Text(l10n.trainRecentWorkouts, style: Theme.of(context).textTheme.titleLarge),
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
              final topVolume = preview
                  .where((w) => !w.isActive)
                  .fold<double>(0, (max, w) => w.totalVolume > max ? w.totalVolume : max);

              return Column(
                children: [
                  ...preview.map(
                    (workout) => WorkoutTile(
                      workout: workout,
                      unitSystem: ref.watch(unitSystemProvider),
                      muscleGroups: trainedMuscleGroupsForWorkout(workout, catalog),
                      showTopVolumeBadge: !workout.isActive &&
                          workout.totalVolume > 0 &&
                          workout.totalVolume >= topVolume,
                      enableSwipeRepeat: true,
                      onRepeat: () => _repeatWorkout(context, ref, workout, routinesAsync.valueOrNull ?? []),
                    ),
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
    );
  }

  Future<void> _repeatWorkout(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
    List<Routine> routines,
  ) async {
    final routineId = workout.routineId;
    if (routineId != null) {
      for (final routine in routines) {
        if (routine.id == routineId) {
          await startWorkoutFromRoutine(context, ref, routine);
          return;
        }
      }
    }

    await startWorkoutAndNavigate(
      context,
      ref,
      name: workout.name,
      routineId: routineId,
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
        leading: const Icon(Icons.play_circle_fill, size: 40, color: AppColors.orange),
        title: Text(
          l10n.workoutDisplayName(workout.name),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(l10n.activeWorkout),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/workout/active'),
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardElevated,
      highlightColor: AppColors.card,
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          color: AppColors.cardElevated,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
