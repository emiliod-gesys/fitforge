import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../core/utils/onboarding_routes.dart';
import '../../core/utils/profile_completeness.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../providers/password_recovery_provider.dart';
import '../../screens/ai/ai_coach_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/reset_password_screen.dart';
import '../../screens/exercises/exercise_detail_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/api_keys_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/progress/progress_screen.dart';
import '../../screens/routines/routine_editor_screen.dart';
import '../../screens/social/friend_profile_screen.dart';
import '../../screens/social/social_screen.dart';
import '../../screens/food/food_screen.dart';
import '../../screens/food/food_add_screen.dart';
import '../../screens/food/food_detail_screen.dart';
import '../../models/workout_summary.dart';
import '../../models/food_entry.dart';
import '../../screens/training/training_hub_screen.dart';
import '../../screens/trainer/students_screen.dart';
import '../../screens/trainer/student_detail_screen.dart';
import '../../screens/workouts/active_workout_screen.dart';
import '../../screens/workouts/workout_summary_screen.dart';
import '../../screens/workouts/workout_history_screen.dart';
import '../../widgets/profile_gate_listener.dart';
import '../../widgets/social_notification_listener.dart';

int _trainingHubInitialTab(GoRouterState state) {
  return state.uri.queryParameters['tab'] == 'routines' ? 1 : 0;
}

/// Notifica a GoRouter cuando cambian auth/perfil sin recrear la instancia del router.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(profileProvider, (_, __) => notifyListeners());
    _ref.listen(passwordRecoveryPendingProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  ref.read(authRecoveryListenerProvider);
  final refresh = _RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    initialLocation: '/',
    redirect: (context, state) {
      final recoveryPending = ref.read(passwordRecoveryPendingProvider);
      final authState = ref.read(authStateProvider);
      final profileAsync = ref.read(profileProvider);
      final isResetRoute = state.matchedLocation == '/reset-password';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';

      if (recoveryPending && !isResetRoute) return '/reset-password';
      if (!recoveryPending && isResetRoute) {
        final isLoggedIn = authState.valueOrNull?.session != null;
        return isLoggedIn ? '/' : '/login';
      }

      final isLoggedIn = authState.valueOrNull?.session != null;
      final isAuthRoute = state.matchedLocation == '/login' || isResetRoute;

      if (!isLoggedIn && !isAuthRoute) return '/login';

      if (isLoggedIn) {
        if (profileAsync.isLoading) return null;

        final profile = profileAsync.valueOrNull;
        final needsOnboarding = ProfileCompleteness.needsOnboarding(profile);

        if (needsOnboarding &&
            !isOnboardingRoute &&
            !OnboardingRoutes.allowsDuringOnboarding(state.matchedLocation) &&
            !isAuthRoute) {
          return '/onboarding';
        }
        if (!needsOnboarding && isOnboardingRoute) return '/';
        if (isLoggedIn && state.matchedLocation == '/login') {
          return needsOnboarding ? '/onboarding' : '/';
        }
      }

      if (state.uri.path == '/routines') return '/?tab=routines';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => SocialNotificationListener(
          child: ProfileGateListener(
            child: HomeScreen(child: child),
          ),
        ),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) {
              final tab = _trainingHubInitialTab(state);
              return NoTransitionPage(
                key: ValueKey('train-tab-$tab'),
                child: TrainingHubScreen(initialTab: tab),
              );
            },
          ),
          GoRoute(
            path: '/ai-coach',
            pageBuilder: (_, __) => const NoTransitionPage(child: AiCoachScreen()),
          ),
          GoRoute(
            path: '/food',
            pageBuilder: (_, __) => const NoTransitionPage(child: FoodScreen()),
          ),
          GoRoute(
            path: '/progress',
            pageBuilder: (_, __) => const NoTransitionPage(child: ProgressScreen()),
          ),
          GoRoute(
            path: '/social',
            pageBuilder: (_, __) => const NoTransitionPage(child: SocialScreen()),
          ),
          GoRoute(
            path: '/students',
            pageBuilder: (_, __) => const NoTransitionPage(child: StudentsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, __) => const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/social/friend/:id',
        builder: (_, state) => FriendProfileScreen(friendId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/students/:id',
        builder: (_, state) => StudentDetailScreen(studentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/workout/active',
        builder: (_, __) => const ActiveWorkoutScreen(),
      ),
      GoRoute(
        path: '/workout/summary',
        builder: (_, state) => WorkoutSummaryScreen(
          summary: state.extra! as WorkoutSummaryData,
        ),
      ),
      GoRoute(
        path: '/workouts/history',
        builder: (_, __) => const WorkoutHistoryScreen(),
      ),
      GoRoute(
        path: '/routines/new',
        builder: (_, state) => RoutineEditorScreen(
          onboardingMode: state.uri.queryParameters['onboarding'] == '1',
        ),
      ),
      GoRoute(
        path: '/routines/:id/edit',
        builder: (_, state) => RoutineEditorScreen(routineId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/students/:studentId/routines/new',
        builder: (_, state) => RoutineEditorScreen(studentId: state.pathParameters['studentId']),
      ),
      GoRoute(
        path: '/students/:studentId/routines/:id/edit',
        builder: (_, state) => RoutineEditorScreen(
          studentId: state.pathParameters['studentId'],
          routineId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/exercises/:id',
        builder: (_, state) => ExerciseDetailScreen(exerciseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/api-keys',
        builder: (_, __) => const ApiKeysScreen(),
      ),
      GoRoute(
        path: '/food/add',
        builder: (_, state) {
          final extra = state.extra! as Map<String, dynamic>;
          return FoodAddScreen(
            mealType: extra['meal'] as MealType,
            day: extra['day'] as DateTime,
            onboardingMode: extra['onboarding'] as bool? ?? false,
            initialMode: extra['initialMode'] as FoodAddMode?,
          );
        },
      ),
      GoRoute(
        path: '/food/detail',
        builder: (_, state) {
          final extra = state.extra! as Map<String, dynamic>;
          return FoodDetailScreen(
            estimate: extra['estimate'] as FoodNutritionEstimate,
            mealType: extra['meal'] as MealType,
            day: extra['day'] as DateTime,
            source: extra['source'] as FoodEntrySource? ?? FoodEntrySource.manual,
            originalQuery: extra['originalQuery'] as String?,
            imageBytes: extra['imageBytes'] as List<int>?,
            onboardingMode: extra['onboarding'] as bool? ?? false,
          );
        },
      ),
    ],
  );
});
