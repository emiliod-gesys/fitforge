import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/food_entry.dart';
import '../../providers/app_providers.dart';
import '../../providers/tutorial_controller.dart';
import '../../screens/food/food_add_screen.dart';
import '../router/app_router.dart';
import 'tutorial_catalog.dart';

/// Whether [current] already satisfies a catalog [target] path (+ optional query).
bool tutorialRouteMatches(Uri current, String target) {
  final parsed = Uri.parse(target);
  if (current.path != parsed.path) return false;
  if (parsed.queryParameters.isEmpty) return true;
  for (final entry in parsed.queryParameters.entries) {
    if (current.queryParameters[entry.key] != entry.value) return false;
  }
  return true;
}

abstract final class TutorialNavigation {
  static void start(WidgetRef ref, TutorialTour tour) {
    ref.read(tutorialControllerProvider.notifier).start(tour.id);
    goTo(ref, tour.route, TutorialNav.go);
  }

  static void ensureStep(WidgetRef ref, TutorialStep step) {
    final route = step.route;
    if (route == null) return;
    goTo(ref, route, step.nav);
  }

  static bool matches(WidgetRef ref, String target) {
    return tutorialRouteMatches(ref.read(routerProvider).state.uri, target);
  }

  static void goTo(WidgetRef ref, String route, TutorialNav nav) {
    final router = ref.read(routerProvider);
    if (tutorialRouteMatches(router.state.uri, route)) return;
    if (route.startsWith('/food/add')) {
      _prepareFoodAdd(ref);
    }
    if (nav == TutorialNav.push) {
      router.push(route, extra: _extraFor(ref, route));
    } else {
      router.go(route);
    }
  }

  static Object? _extraFor(WidgetRef ref, String route) {
    if (!route.startsWith('/food/add')) return null;
    final args = ref.read(foodAddRouteArgsProvider);
    if (args == null) return null;
    return {
      'meal': args.mealType,
      'day': args.day,
    };
  }

  static void _prepareFoodAdd(WidgetRef ref) {
    ref.read(foodAddRouteArgsProvider.notifier).state = FoodAddRouteArgs(
      mealType: MealType.breakfast,
      day: ref.read(foodSelectedDayProvider),
    );
  }
}
