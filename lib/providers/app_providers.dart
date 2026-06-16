import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/workout_streak.dart';
import '../models/profile.dart';
import '../services/ai_coach_service.dart';
import '../services/auth_service.dart';
import '../services/exercise_service.dart';
import '../services/profile_service.dart';import '../services/routine_service.dart';
import '../services/workout_service.dart';

final authServiceProvider = Provider((ref) => AuthService());
final exerciseServiceProvider = Provider((ref) => ExerciseService());
final routineServiceProvider = Provider((ref) => RoutineService());
final workoutServiceProvider = Provider((ref) => WorkoutService());
final profileServiceProvider = Provider((ref) => ProfileService());
final aiCoachServiceProvider = Provider(
  (ref) => AiCoachService(ref.watch(profileServiceProvider)),
);

final authStateProvider = StreamProvider((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(profileServiceProvider).getProfile();
});

/// Unidad global de la app (kg o lb), derivada del perfil del usuario.
final unitSystemProvider = Provider<String>((ref) {
  return ref.watch(profileProvider).value?.unitSystem ?? 'kg';
});

final bodyMetricSnapshotsProvider = FutureProvider((ref) async {
  ref.watch(authStateProvider);
  ref.watch(profileProvider);
  return ref.watch(profileServiceProvider).getBodyMetricSnapshots();
});

final exercisesProvider = FutureProvider((ref) async {
  return ref.watch(exerciseServiceProvider).fetchExercises();
});

final exerciseMediaProvider = FutureProvider.family<ExerciseMedia, int>((ref, wgerId) async {
  return ref.watch(exerciseServiceProvider).fetchExerciseMedia(wgerId);
});

final routinesProvider = FutureProvider((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(routineServiceProvider).getRoutines();
});

final workoutsProvider = FutureProvider((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(workoutServiceProvider).getWorkouts();
});

final workoutWeeklyStatsProvider = FutureProvider<WorkoutWeeklyStats>((ref) async {
  ref.watch(authStateProvider);
  final dates = await ref.watch(workoutServiceProvider).getCompletedWorkoutTimestamps();
  return WorkoutStreakCalculator.fromCompletedDates(dates);
});

final activeWorkoutProvider = FutureProvider((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(workoutServiceProvider).getActiveWorkout();
});

final personalRecordsProvider = FutureProvider((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(workoutServiceProvider).getPersonalRecords();
});

final bodyMeasurementsProvider = FutureProvider((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(workoutServiceProvider).getBodyMeasurements();
});

final muscleRecoveryProvider = FutureProvider((ref) async {
  final workouts = await ref.watch(workoutsProvider.future);
  return ref.watch(workoutServiceProvider).calculateMuscleRecovery(workouts);
});
