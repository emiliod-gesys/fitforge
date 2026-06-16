import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/muscle_recovery_map.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/workout_tile.dart';

class WorkoutListScreen extends ConsumerWidget {
  static const _previewCount = 7;
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              loading: () => const FitForgeLoadingScreen(),
              error: (_, __) => _StartWorkoutSection(routinesAsync: routinesAsync),
            ),
            const SizedBox(height: 20),
            recoveryAsync.when(
              data: (recovery) => MuscleRecoveryMap(recovery: recovery),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text('Historial', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            recentAsync.when(
              data: (workouts) {
                if (workouts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Sin entrenamientos aún. ¡Empieza hoy!')),
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
                          label: const Text('Ver historial completo'),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const FitForgeLoadingScreen(),
              error: (e, _) => Text('Error: $e'),
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
    return Card(
      color: AppColors.orange.withValues(alpha: 0.12),
      child: ListTile(
        leading: Icon(Icons.play_circle_fill, size: 40, color: AppColors.orange),
        title: Text(workout.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Entrenamiento en curso'),
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
                  label: 'Racha (≥4/sem)',
                  value: stats.streakLabel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.fitness_center,
                  label: 'Esta semana',
                  value: stats.weekProgressLabel,
                ),
              ),
            ],
          ),
          loading: () => const Row(
            children: [
              Expanded(child: StatCard(icon: Icons.local_fire_department, label: 'Racha', value: '…')),
              SizedBox(width: 12),
              Expanded(child: StatCard(icon: Icons.fitness_center, label: 'Esta semana', value: '…')),
            ],
          ),
          error: (_, __) => const Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.local_fire_department,
                  label: 'Racha (≥4/sem)',
                  value: '0 semanas',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.fitness_center,
                  label: 'Esta semana',
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
          label: const Text('Iniciar entrenamiento'),
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
    if (!context.mounted) return;

    try {
      await FitForgeLoadingOverlay.run(
        context,
        message: 'Iniciando entrenamiento…',
        task: () async {
          await start();
          ref.invalidate(activeWorkoutProvider);
          await ref.read(activeWorkoutProvider.future);
        },
      );
      if (context.mounted) context.push('/workout/active');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar entrenamiento: $e')),
        );
      }
    }
  }

  void _showStartOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text('Entrenamiento libre'),
              onTap: () async {
                Navigator.pop(ctx);
                await _startAndOpenWorkout(context, ref, () async {
                  await ref.read(workoutServiceProvider).startWorkout(
                        name: 'Entrenamiento libre',
                      );
                });
              },
            ),
            routinesAsync.when(
              data: (routines) => Column(
                children: routines
                    .map(
                      (r) => ListTile(
                        leading: const Icon(Icons.list_alt),
                        title: Text(r.name),
                        subtitle: Text('${r.exercises.length} ejercicios'),
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
                                      weight: e.targetWeight,
                                      reps: e.targetReps,
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
                      ),
                    )
                    .toList(),
              ),
              loading: () => const ListTile(title: Text('Cargando rutinas...')),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
