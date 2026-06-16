import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../screens/ai/ai_coach_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/exercises/exercise_detail_screen.dart';
import '../../screens/exercises/exercise_library_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/api_keys_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/progress/progress_screen.dart';
import '../../screens/routines/routine_editor_screen.dart';
import '../../screens/routines/routine_list_screen.dart';
import '../../screens/workouts/active_workout_screen.dart';
import '../../screens/workouts/workout_history_screen.dart';
import '../../screens/workouts/workout_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.session != null;
      final isAuthRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, __) => const NoTransitionPage(child: WorkoutListScreen()),
          ),
          GoRoute(
            path: '/routines',
            pageBuilder: (_, __) => const NoTransitionPage(child: RoutineListScreen()),
          ),
          GoRoute(
            path: '/exercises',
            pageBuilder: (_, __) => const NoTransitionPage(child: ExerciseLibraryScreen()),
          ),
          GoRoute(
            path: '/progress',
            pageBuilder: (_, __) => const NoTransitionPage(child: ProgressScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, __) => const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/workout/active',
        builder: (_, __) => const ActiveWorkoutScreen(),
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
        path: '/exercises/:id',
        builder: (_, state) => ExerciseDetailScreen(exerciseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/ai-coach',
        builder: (_, __) => const AiCoachScreen(),
      ),
      GoRoute(
        path: '/api-keys',
        builder: (_, __) => const ApiKeysScreen(),
      ),
    ],
  );
});
