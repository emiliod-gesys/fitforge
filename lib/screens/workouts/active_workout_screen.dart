import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/rest_timer.dart';
import '../../widgets/set_log_tile.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  int _currentExerciseIndex = 0;
  bool _showRestTimer = false;
  int _restSeconds = 90;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  Future<void> _completeWorkout(Workout workout) async {
    final duration = DateTime.now().difference(_startTime!).inMinutes;
    final volume = workout.exercises.fold<double>(
      0,
      (sum, ex) => sum + ex.totalVolume,
    );

    await ref.read(workoutServiceProvider).completeWorkout(
          workout.id,
          durationMinutes: duration,
          totalVolume: volume,
        );

    ref.invalidate(workoutsProvider);
    ref.invalidate(activeWorkoutProvider);
    ref.invalidate(personalRecordsProvider);
    ref.invalidate(muscleRecoveryProvider);
    ref.invalidate(workoutWeeklyStatsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Entrenamiento completado!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(activeWorkoutProvider);
    final unitSystem = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: FitForgeAppBar(
        title: 'Entrenando',
        actions: [
          activeAsync.whenOrNull(
            data: (workout) => workout != null
                ? TextButton(
                    onPressed: () => _completeWorkout(workout),
                    child: const Text('Finalizar'),
                  )
                : null,
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: activeAsync.when(
        data: (workout) {
          if (workout == null) {
            return const Center(child: Text('No hay entrenamiento activo'));
          }

          if (workout.exercises.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Añade ejercicios desde la biblioteca'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/exercises'),
                    child: const Text('Ir a ejercicios'),
                  ),
                ],
              ),
            );
          }

          final exercise = workout.exercises[_currentExerciseIndex];

          return Column(
            children: [
              if (_showRestTimer)
                RestTimer(
                  seconds: _restSeconds,
                  onComplete: () => setState(() => _showRestTimer = false),
                  onSkip: () => setState(() => _showRestTimer = false),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (exercise.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          exercise.imageUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      exercise.exerciseName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ...exercise.sets.map(
                      (set) => SetLogTile(
                        set: set,
                        unitSystem: unitSystem,
                        onChanged: (updated) => _logSet(workout, exercise, updated),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _addSet(workout, exercise),
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir serie'),
                    ),
                  ],
                ),
              ),
              _ExerciseNavigator(
                currentIndex: _currentExerciseIndex,
                total: workout.exercises.length,
                onPrevious: _currentExerciseIndex > 0
                    ? () => setState(() => _currentExerciseIndex--)
                    : null,
                onNext: _currentExerciseIndex < workout.exercises.length - 1
                    ? () => setState(() => _currentExerciseIndex++)
                    : null,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _logSet(Workout workout, WorkoutExercise exercise, WorkoutSet set) async {
    await ref.read(workoutServiceProvider).logSet(exercise.id, set.copyWith(completed: true));
    ref.invalidate(activeWorkoutProvider);
    setState(() {
      _showRestTimer = true;
      _restSeconds = 90;
    });
  }

  Future<void> _addSet(Workout workout, WorkoutExercise exercise) async {
    final newSet = WorkoutSet(
      id: const Uuid().v4(),
      setNumber: exercise.sets.length + 1,
      weight: exercise.sets.isNotEmpty ? exercise.sets.last.weight : null,
      reps: exercise.sets.isNotEmpty ? exercise.sets.last.reps : 10,
    );
    await ref.read(workoutServiceProvider).logSet(exercise.id, newSet);
    ref.invalidate(activeWorkoutProvider);
  }
}

class _ExerciseNavigator extends StatelessWidget {
  final int currentIndex;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _ExerciseNavigator({
    required this.currentIndex,
    required this.total,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('${currentIndex + 1} / $total'),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
