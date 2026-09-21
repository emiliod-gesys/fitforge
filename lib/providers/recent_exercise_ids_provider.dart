import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/exercise_picker_merge.dart';
import '../models/workout.dart';
import 'app_providers.dart';

class RecentPickerExerciseIds extends Notifier<List<String>> {
  static const prefKey = 'recent_picker_exercise_ids';
  static const maxIds = 80;

  String? _userId;

  @override
  List<String> build() {
    _userId = ref.watch(authUserIdProvider);
    final userId = _userId;
    Future<void>.microtask(() => _hydrate(userId));
    return const [];
  }

  String _key(String userId) => '${prefKey}_$userId';

  Future<void> _hydrate(String? userId) async {
    if (userId == null || userId.isEmpty) {
      state = const [];
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!ref.exists(recentPickerExerciseIdsProvider) || _userId != userId) return;
    state = prefs.getStringList(_key(userId)) ?? const [];
  }

  Future<void> record(String exerciseId) async {
    final userId = _userId;
    if (exerciseId.isEmpty || userId == null || userId.isEmpty) return;
    final next = [
      exerciseId,
      ...state.where((id) => id != exerciseId),
    ].take(maxIds).toList();
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(userId), next);
  }
}

final recentPickerExerciseIdsProvider =
    NotifierProvider<RecentPickerExerciseIds, List<String>>(
  RecentPickerExerciseIds.new,
);

final recentWorkoutExerciseUsagesProvider =
    FutureProvider<List<ExerciseUsage>>((ref) async {
  ref.keepAlive();
  ref.watch(authStateProvider);
  final workouts =
      await ref.watch(workoutServiceProvider).getWorkoutsForMuscleRecovery(limit: 20);
  return _usagesFromWorkouts(workouts);
});

/// IDs más recientes primero, para el selector de cada categoría.
final recentExerciseIdsProvider = Provider<List<String>>((ref) {
  final local = ref.watch(recentPickerExerciseIdsProvider);
  final routines = ref.watch(routinesProvider).valueOrNull ?? const [];
  final active = ref.watch(activeWorkoutProvider).valueOrNull;
  final history = ref.watch(recentWorkoutExerciseUsagesProvider).valueOrNull ?? const [];

  final usages = <ExerciseUsage>[
    if (active != null)
      for (var i = 0; i < active.exercises.length; i++)
        ExerciseUsage(
          exerciseId: active.exercises[i].exerciseId,
          usedAt: DateTime.now().subtract(
            Duration(seconds: active.exercises.length - i),
          ),
        ),
    ...history,
    for (final routine in routines)
      for (final exercise in routine.exercises)
        ExerciseUsage(exerciseId: exercise.exerciseId, usedAt: routine.updatedAt),
  ];

  return mergeRecentExerciseIds(localPicks: local, usages: usages);
});

List<ExerciseUsage> _usagesFromWorkouts(List<Workout> workouts) {
  final usages = <ExerciseUsage>[];
  for (final workout in workouts) {
    final usedAt = workout.completedAt ?? workout.lastActivityAt ?? workout.startedAt;
    for (final exercise in workout.exercises) {
      usages.add(ExerciseUsage(exerciseId: exercise.exerciseId, usedAt: usedAt));
    }
  }
  return usages;
}
