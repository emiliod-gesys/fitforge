import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/runner/runner_standards.dart';
import '../core/subscription/subscription_features.dart';
import '../core/utils/bmr_calculator.dart';
import '../core/utils/daily_nutrition_budget.dart';
import '../core/l10n/app_locale.dart';
import '../core/theme/app_accent.dart';
import '../core/utils/workout_streak.dart';
import '../core/constants/cloud_exercise_catalog.dart';
import '../data/exercise_translation_store.dart';
import '../models/exercise.dart';
import '../models/exercise_history.dart';
import '../models/body_metric.dart';
import '../models/food_entry.dart';
import '../models/manual_activity_entry.dart';
import '../models/leaderboard.dart';
import '../models/profile.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import '../models/workout_summary.dart';
import '../services/ai_coach_service.dart';
import '../services/auth_service.dart';
import '../services/custom_exercise_repository.dart';
import '../data/cloud_exercise_catalog.dart';
import '../services/exercise_service.dart';
import '../services/activity_log_service.dart';
import '../services/food_service.dart';
import '../services/local_manual_food_store.dart';
import '../services/open_food_facts_service.dart';
import '../services/profile_service.dart';
import '../services/routine_service.dart';
import '../services/hyrox_service.dart';
import '../services/runner_service.dart';
import '../services/routine_share_service.dart';
import '../services/exercise_report_service.dart';
import '../services/workout_service.dart';
import '../models/trainer.dart';
import '../models/feed_reaction.dart';
import '../models/social.dart';
import '../services/social_service.dart';
import '../services/trainer_service.dart';
import '../models/rest_timer_alert_mode.dart';
import '../services/rest_preferences.dart';
import '../services/ai_preferences.dart';
import '../services/coach_nutrition_service.dart';
import '../services/coach_usage_service.dart';
import '../services/push_notification_service.dart';
import '../services/watch_session_bridge.dart';
import '../services/watch_workout_coordinator.dart';

final authServiceProvider = Provider((ref) => AuthService());
final exerciseServiceProvider = Provider((ref) => ExerciseService());
final exerciseTranslationStoreProvider = Provider((ref) => ExerciseTranslationStore());
final routineShareServiceProvider = Provider((ref) => RoutineShareService());

final routineServiceProvider = Provider((ref) => RoutineService());
final hyroxServiceProvider = Provider(
  (ref) => HyroxService(ref.watch(routineServiceProvider)),
);
final runnerServiceProvider = Provider(
  (ref) => RunnerService(ref.watch(routineServiceProvider)),
);
final pendingRunnerSurfaceProvider = StateProvider<RunningSurface?>((ref) => null);

/// Resumen pendiente tras finalizar entreno; sobrevive a rebuilds de GoRouter sin `extra`.
final pendingWorkoutSummaryProvider = StateProvider<WorkoutSummaryData?>((ref) => null);
final workoutServiceProvider = Provider((ref) => WorkoutService());
final exerciseReportServiceProvider = Provider((ref) => ExerciseReportService());
final profileServiceProvider = Provider((ref) => ProfileService());
final socialServiceProvider = Provider((ref) => SocialService());
final trainerServiceProvider = Provider((ref) => TrainerService());
final pushNotificationServiceProvider = Provider((ref) => PushNotificationService());
final aiCoachServiceProvider = Provider(
  (ref) => AiCoachService(ref.watch(profileServiceProvider)),
);
final coachUsageServiceProvider = Provider((ref) => CoachUsageService());
final coachNutritionServiceProvider = Provider(
  (ref) => CoachNutritionService(
    foodService: ref.watch(foodServiceProvider),
    workoutService: ref.watch(workoutServiceProvider),
    activityLogService: ref.watch(activityLogServiceProvider),
  ),
);

final coachUsageStatusProvider = FutureProvider<CoachUsageStatus>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  final profileService = ref.watch(profileServiceProvider);
  return ref.watch(coachUsageServiceProvider).getStatus(profile, profileService);
});

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

/// Color de acento personalizado del usuario (solo afecta su propia vista).
final accentProvider = Provider<AppAccent>((ref) {
  return ref.watch(profileProvider).value?.accentColor ?? AppAccent.gold;
});

final bodyMetricSnapshotsProvider = FutureProvider((ref) async {
  ref.watch(authStateProvider);
  final profile = await ref.watch(profileProvider.future);
  final snapshots = await ref.watch(profileServiceProvider).getBodyMetricSnapshots();
  return BodyMetricCalculator.enrich(snapshots, profile);
});

final restTimerAlertModeProvider = FutureProvider<RestTimerAlertMode>((ref) async {
  return RestPreferences.getRestTimerAlertMode();
});

final aiProactiveEnabledProvider = FutureProvider<bool>((ref) async {
  return AiPreferences.isProactiveAiEnabled();
});

final customExerciseRepositoryProvider = Provider((ref) => CustomExerciseRepository());

final exercisesProvider = FutureProvider((ref) async {
  final lang = ref.watch(preferredLanguageProvider);
  final store = ref.read(exerciseTranslationStoreProvider);
  await store.load();
  final customRepo = ref.read(customExerciseRepositoryProvider);
  await customRepo.loadAll();
  final service = ref.read(exerciseServiceProvider);
  service.configure(language: lang);
  service.setTranslationStore(store);
  service.setCustomExerciseRepository(customRepo);
  return service.fetchExercises();
});

final cloudExerciseCatalogProvider = Provider((ref) => CloudExerciseCatalog());

final cloudExerciseByIdProvider = FutureProvider.family<Exercise?, String>((ref, id) async {
  if (!CloudExerciseCatalog.isCloudExerciseId(id)) return null;
  final lang = ref.watch(preferredLanguageProvider);
  ref.read(exerciseServiceProvider).configure(language: lang);
  return ref.read(exerciseServiceProvider).getCloudExerciseById(id);
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

final milestoneTotalsProvider = FutureProvider((ref) async {
  ref.watch(authStateProvider);
  final profile = await ref.watch(profileProvider.future);
  return ref.watch(workoutServiceProvider).getMilestoneTotals(profile: profile);
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
  ref.keepAlive();
  ref.watch(authStateProvider);

  final service = ref.watch(workoutServiceProvider);
  final catalog = await ref.watch(exercisesProvider.future);

  final workouts = await service.getWorkoutsForMuscleRecovery();
  return service.calculateMuscleRecovery(workouts, catalog: catalog);
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

final isTrainerProvider = Provider<bool>((ref) {
  final profile = ref.watch(profileProvider).value;
  if (profile == null) return false;
  return profile.isTrainer && profile.subscriptionTier.hasTrainerMode;
});

final trainerStudentsProvider = FutureProvider<List<TrainerStudent>>((ref) async {
  ref.watch(authStateProvider);
  final profile = await ref.watch(profileProvider.future);
  if (profile?.isTrainer != true) return [];
  return ref.watch(trainerServiceProvider).getStudents();
});

final trainerAddableFriendsProvider = FutureProvider<List<FriendUser>>((ref) async {
  ref.watch(authStateProvider);
  final profile = await ref.watch(profileProvider.future);
  if (profile?.isTrainer != true) return [];
  final social = ref.watch(socialServiceProvider);
  return ref.watch(trainerServiceProvider).getAddableFriends(social);
});

final studentProfileProvider = FutureProvider.family<StudentProfileView?, String>((ref, studentId) async {
  ref.watch(authStateProvider);
  return ref.watch(trainerServiceProvider).getStudentProfile(studentId);
});

final studentWorkoutHistoryProvider = FutureProvider.family<List<Workout>, String>((ref, studentId) async {
  ref.watch(authStateProvider);
  return ref.watch(workoutServiceProvider).getWorkoutSummariesForUser(
        studentId,
        limit: 30,
        completedOnly: true,
      );
});

final studentRoutinesProvider = FutureProvider.family<List<Routine>, String>((ref, studentId) async {
  ref.watch(authStateProvider);
  return ref.watch(routineServiceProvider).getRoutinesForUser(studentId);
});

final studentNutritionDayProvider = StateProvider.family<DateTime, String>((ref, studentId) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final studentDailyNutritionProvider = FutureProvider.family<DailyNutritionSummary, String>((ref, studentId) async {
  ref.watch(authStateProvider);
  final selected = ref.watch(studentNutritionDayProvider(studentId));
  final day = DateTime(selected.year, selected.month, selected.day);

  final profileView = await ref.watch(studentProfileProvider(studentId).future);
  if (profileView == null) {
    throw StateError('Student not found');
  }

  final entries = await ref.watch(foodServiceProvider).getEntriesForDay(day, userId: studentId);
  final workouts = await ref.watch(workoutServiceProvider).getCompletedWorkoutsOnDay(day, userId: studentId);
  final activities = await ref.watch(activityLogServiceProvider).getEntriesForDay(day, userId: studentId);
  final bodyMetrics = await ref.watch(profileServiceProvider).getBodyMetricSnapshotsForUser(studentId);

  return DailyNutritionBudget.build(
    day: day,
    entries: entries,
    workoutsCompletedOnDay: workouts,
    manualActivities: activities,
    profile: profileView.profile,
    bodyMetrics: bodyMetrics,
  );
});

final studentRecoveryProvider = FutureProvider.family<Map<String, double>, String>((ref, studentId) async {
  ref.keepAlive();
  ref.watch(authStateProvider);
  final service = ref.watch(workoutServiceProvider);
  final catalog = await ref.watch(exercisesProvider.future);
  final workouts = await service.getWorkoutsForMuscleRecoveryForUser(studentId);
  return service.calculateMuscleRecovery(workouts, catalog: catalog);
});

final myTrainerProvider = FutureProvider<MyTrainerView?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(trainerServiceProvider).getMyTrainer();
});

final friendshipsProvider = FutureProvider<List<Friendship>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(socialServiceProvider).getFriendships();
});

final mutedFriendsProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(socialServiceProvider).getMutedFriendIds();
});

final leaderboardProvider = FutureProvider.family<LeaderboardResult, LeaderboardKey>((ref, key) async {
  ref.watch(authStateProvider);
  ref.watch(profileProvider);
  return ref.watch(socialServiceProvider).getLeaderboard(
        metric: key.metric,
        scope: key.scope,
        period: key.period,
        limit: key.limit,
      );
});

final userSearchProvider = FutureProvider.family<List<FriendUser>, String>((ref, query) async {
  ref.watch(authStateProvider);
  return ref.watch(socialServiceProvider).searchUsers(query);
});

final friendFavoriteRoutinesProvider = FutureProvider.family<List<Routine>, String>((ref, userId) async {
  ref.watch(authStateProvider);
  return ref.watch(routineServiceProvider).getFavoriteRoutinesForUser(userId);
});

final friendProfileProvider = FutureProvider.family<FriendProfileView?, String>((ref, friendId) async {
  ref.watch(authStateProvider);
  return ref.watch(socialServiceProvider).getFriendProfile(friendId);
});

final socialNotificationsProvider = FutureProvider<List<SocialNotification>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(socialServiceProvider).getNotifications();
});

final socialFeedProvider = FutureProvider<List<FeedPost>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(socialServiceProvider).getFeedWithReactions();
});

final socialUnreadCountProvider = FutureProvider<int>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(socialServiceProvider).getUnreadCount();
});

final socialRealtimeProvider = StreamProvider<SocialRealtimeEvent>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth?.session == null) return const Stream.empty();

  final service = ref.watch(socialServiceProvider);
  final controller = StreamController<SocialRealtimeEvent>();

  final channel = service.subscribeToNotifications((payload) {
    final event = SocialRealtimeEvent.fromRecord(payload.newRecord);
    if (event.message.isNotEmpty) controller.add(event);
  });

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

final foodServiceProvider = Provider((ref) => FoodService());
final activityLogServiceProvider = Provider((ref) => ActivityLogService());
final localManualFoodStoreProvider = Provider((ref) => LocalManualFoodStore());

final openFoodFactsServiceProvider = Provider((ref) => OpenFoodFactsService());

final foodSelectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final foodEntriesProvider = FutureProvider<List<FoodEntry>>((ref) async {
  ref.keepAlive();
  ref.watch(authStateProvider);
  final day = ref.watch(foodSelectedDayProvider);
  return ref.watch(foodServiceProvider).getEntriesForDay(day);
});

final manualActivitiesProvider = FutureProvider<List<ManualActivityEntry>>((ref) async {
  ref.keepAlive();
  ref.watch(authStateProvider);
  final day = ref.watch(foodSelectedDayProvider);
  return ref.watch(activityLogServiceProvider).getEntriesForDay(day);
});

final foodDayWorkoutsProvider = FutureProvider.family<List<Workout>, DateTime>((ref, day) async {
  ref.watch(authStateProvider);
  final normalized = DateTime(day.year, day.month, day.day);
  return ref.watch(workoutServiceProvider).getCompletedWorkoutsOnDay(normalized);
});

final dailyNutritionProvider = FutureProvider<DailyNutritionSummary>((ref) async {
  ref.keepAlive();
  ref.watch(authStateProvider);
  final day = ref.watch(foodSelectedDayProvider);
  final normalizedDay = DateTime(day.year, day.month, day.day);

  final profileFuture = ref.watch(profileProvider.future);
  final metricsFuture = ref.watch(bodyMetricSnapshotsProvider.future);
  final entriesFuture = ref.watch(foodEntriesProvider.future);
  final workoutsFuture = ref.watch(foodDayWorkoutsProvider(normalizedDay).future);
  final activitiesFuture = ref.watch(manualActivitiesProvider.future);

  final results = await Future.wait([
    profileFuture,
    metricsFuture,
    entriesFuture,
    workoutsFuture,
    activitiesFuture,
  ]);

  return DailyNutritionBudget.build(
    day: normalizedDay,
    entries: results[2] as List<FoodEntry>,
    workoutsCompletedOnDay: results[3] as List<Workout>,
    manualActivities: results[4] as List<ManualActivityEntry>,
    profile: results[0] as UserProfile?,
    bodyMetrics: results[1] as Map<String, BodyMetricSnapshot>,
  );
});

final watchSessionBridgeProvider = Provider((ref) => WatchSessionBridge());

final watchWorkoutCoordinatorProvider = Provider((ref) {
  final coordinator = WatchWorkoutCoordinator(ref.watch(watchSessionBridgeProvider));
  ref.onDispose(coordinator.detach);
  return coordinator;
});
