import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/l10n/app_locale.dart';
import '../core/utils/workout_streak.dart';
import '../models/exercise_history.dart';
import '../models/profile.dart';
import '../services/ai_coach_service.dart';
import '../services/auth_service.dart';
import '../services/exercise_service.dart';
import '../services/profile_service.dart';
import '../services/routine_service.dart';
import '../services/workout_service.dart';
import '../models/social.dart';
import '../services/social_service.dart';
import '../services/push_notification_service.dart';

final authServiceProvider = Provider((ref) => AuthService());
final exerciseServiceProvider = Provider((ref) => ExerciseService());
final routineServiceProvider = Provider((ref) => RoutineService());
final workoutServiceProvider = Provider((ref) => WorkoutService());
final profileServiceProvider = Provider((ref) => ProfileService());
final socialServiceProvider = Provider((ref) => SocialService());
final pushNotificationServiceProvider = Provider((ref) => PushNotificationService());
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

/// Idioma preferido del usuario (es / en).
final preferredLanguageProvider = Provider<String>((ref) {
  return ref.watch(profileProvider).value?.preferredLanguage ?? AppLocale.defaultCode;
});

final appLocaleProvider = Provider<Locale>((ref) {
  return AppLocale.toLocale(ref.watch(preferredLanguageProvider));
});

final bodyMetricSnapshotsProvider = FutureProvider((ref) async {
  ref.watch(authStateProvider);
  ref.watch(profileProvider);
  return ref.watch(profileServiceProvider).getBodyMetricSnapshots();
});

final exercisesProvider = FutureProvider((ref) async {
  final lang = ref.watch(preferredLanguageProvider);
  final service = ref.read(exerciseServiceProvider);
  service.configure(language: lang);
  return service.fetchExercises();
});

final exerciseMediaProvider = FutureProvider.family<ExerciseMedia, int>((ref, wgerId) async {
  return ref.watch(exerciseServiceProvider).fetchExerciseMedia(wgerId);
});

final exerciseImageUrlProvider =
    FutureProvider.family<String?, ExerciseImageLookup>((ref, lookup) async {
  return ref.watch(exerciseServiceProvider).resolveImageUrl(lookup);
});

final routinesProvider = FutureProvider((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(routineServiceProvider).getRoutines();
});

final workoutsProvider = FutureProvider((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(workoutServiceProvider).getWorkouts();
});

/// Vista rápida del menú principal (sin cargar ejercicios de cada entreno).
final recentWorkoutsProvider = FutureProvider((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(workoutServiceProvider).getWorkoutSummaries(limit: 8);
});

final workoutHistoryProvider = FutureProvider((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(workoutServiceProvider).getWorkoutSummaries(limit: 100);
});

final progressWorkoutsProvider = FutureProvider((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(workoutServiceProvider).getWorkoutSummaries(limit: 60);
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
  final catalog = await ref.watch(exercisesProvider.future);
  return ref.watch(workoutServiceProvider).calculateMuscleRecovery(
        workouts,
        catalog: catalog,
      );
});

final exerciseHistoryProvider = FutureProvider.family<List<ExerciseSessionHistory>, ExerciseHistoryQuery>(
  (ref, query) async {
    ref.watch(authStateProvider);
    return ref.watch(workoutServiceProvider).getExerciseHistory(
          query.exerciseId,
          excludeWorkoutId: query.excludeWorkoutId,
        );
  },
);

final friendshipsProvider = FutureProvider<List<Friendship>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(socialServiceProvider).getFriendships();
});

final userSearchProvider = FutureProvider.family<List<FriendUser>, String>((ref, query) async {
  ref.watch(authStateProvider);
  return ref.watch(socialServiceProvider).searchUsers(query);
});

final friendProfileProvider = FutureProvider.family<FriendProfileView?, String>((ref, friendId) async {
  ref.watch(authStateProvider);
  return ref.watch(socialServiceProvider).getFriendProfile(friendId);
});

final socialNotificationsProvider = FutureProvider<List<SocialNotification>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(socialServiceProvider).getNotifications();
});

final socialUnreadCountProvider = FutureProvider<int>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(socialServiceProvider).getUnreadCount();
});

final socialRealtimeProvider = StreamProvider<String>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth?.session == null) return const Stream.empty();

  final service = ref.watch(socialServiceProvider);
  final controller = StreamController<String>();

  final channel = service.subscribeToNotifications((payload) {
    final message = payload.newRecord['message'] as String?;
    if (message != null) controller.add(message);
  });

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});
