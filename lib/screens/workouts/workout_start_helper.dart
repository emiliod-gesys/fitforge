import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/subscription/subscription_features.dart';
import '../../core/router/app_router.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../services/ai_preferences.dart';
import '../../services/proactive_workout_enricher.dart';
import '../../widgets/fitforge_loading_indicator.dart';

Future<void> startWorkoutAndNavigate(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  String? routineId,
  List<WorkoutExercise>? exercises,
}) async {
  final l10n = context.l10n;
  if (!context.mounted) return;

  final router = ref.read(routerProvider);
  final messenger = ScaffoldMessenger.maybeOf(context);

  final proactive = await AiPreferences.isProactiveAiEnabled();
  final profile = proactive ? await ref.read(profileProvider.future) : null;
  final useAi = proactive &&
      profile != null &&
      profile.subscriptionTier.hasProactiveAi &&
      profile.hasAiKey &&
      exercises != null &&
      exercises.isNotEmpty;

  var aiApplied = false;

  try {
    if (!context.mounted) return;
    await FitForgeLoadingOverlay.run(
      context,
      message: useAi ? l10n.aiCalculatingWorkoutSuggestions : l10n.startingWorkout,
      task: () async {
        Future<List<WorkoutExercise>> Function(
          List<WorkoutExercise> locallyEnriched,
          String workoutId,
        )? applyProactive;

        if (useAi) {
          applyProactive = (local, workoutId) async {
            final result = await _enrichWithProactiveAi(
              ref: ref,
              profile: profile,
              exercises: local,
              excludeWorkoutId: workoutId,
            );
            aiApplied = result.aiApplied;
            return result.exercises;
          };
        }

        await ref.read(workoutServiceProvider).startWorkout(
              name: name,
              routineId: routineId,
              exercises: exercises,
              applyProactiveSuggestions: applyProactive,
            );
        ref.invalidate(activeWorkoutProvider);
        await ref.read(activeWorkoutProvider.future);
      },
    );
    router.push('/workout/active');
    if (aiApplied) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.aiWorkoutSuggestionsApplied)),
      );
    }
  } catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.startWorkoutError('$e'))),
    );
  }
}

Future<({List<WorkoutExercise> exercises, bool aiApplied})> _enrichWithProactiveAi({
  required WidgetRef ref,
  required UserProfile profile,
  required List<WorkoutExercise> exercises,
  required String excludeWorkoutId,
}) async {
  final workoutService = ref.read(workoutServiceProvider);
  final aiCoach = ref.read(aiCoachServiceProvider);

  final catalog = ref.read(exercisesProvider).valueOrNull ?? [];
  final customRepo = ref.read(customExerciseRepositoryProvider);
  final customs = (await customRepo.loadAll()).map((c) => c.toExercise()).toList();
  final fullCatalog = [...catalog, ...customs];

  final recoveryWorkouts = await workoutService.getWorkoutsForMuscleRecovery();
  final recovery = workoutService.calculateMuscleRecovery(
    recoveryWorkouts,
    catalog: fullCatalog,
  );

  final enricher = ProactiveWorkoutEnricher(
    workoutService: workoutService,
    aiCoach: aiCoach,
  );

  return enricher.enrich(
    exercises: exercises,
    profile: profile,
    muscleRecovery: recovery,
    catalog: fullCatalog,
    excludeWorkoutId: excludeWorkoutId,
  );
}

List<WorkoutExercise> workoutExercisesFromRoutine(Routine routine) {
  return routine.exercises
      .map(
        (e) => WorkoutExercise(
          id: '',
          exerciseId: e.exerciseId,
          exerciseName: e.exerciseName,
          imageUrl: e.imageUrl,
          orderIndex: e.orderIndex,
          sets: e.resolvedSetDetails
              .asMap()
              .entries
              .map(
                (entry) => WorkoutSet(
                  id: '',
                  setNumber: entry.key + 1,
                  weight: e.isCardio ? null : entry.value.weight,
                  reps: e.isCardio ? 0 : entry.value.reps,
                  loggingType: e.loggingType,
                  durationSeconds: e.targetDurationSeconds,
                  distanceMeters: e.targetDistanceMeters,
                  inclinePercent: e.targetInclinePercent,
                  steps: e.targetSteps,
                ),
              )
              .toList(),
        ),
      )
      .toList();
}

Future<void> startWorkoutFromRoutine(
  BuildContext context,
  WidgetRef ref,
  Routine routine,
) {
  return startWorkoutAndNavigate(
    context,
    ref,
    name: routine.name,
    routineId: routine.id,
    exercises: workoutExercisesFromRoutine(routine),
  );
}
