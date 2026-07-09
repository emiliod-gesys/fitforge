import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final recoveryPending = ref.watch(passwordRecoveryPendingProvider);
  ref.watch(authRecoveryListenerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isResetRoute = state.matchedLocation == '/reset-password';

      if (recoveryPending && !isResetRoute) return '/reset-password';
      if (!recoveryPending && isResetRoute) {
        final isLoggedIn = authState.valueOrNull?.session != null;
        return isLoggedIn ? '/' : '/login';
      }

      final isLoggedIn = authState.valueOrNull?.session != null;
      final isAuthRoute = state.matchedLocation == '/login' || isResetRoute;

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && state.matchedLocation == '/login') return '/';
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
        builder: (_, __) => const RoutineEditorScreen(),
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
          );
        },
      ),
    ],
  );
});
