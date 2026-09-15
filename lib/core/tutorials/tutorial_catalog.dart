import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'tutorial_targets.dart';

enum TutorialNav { go, push }

class TutorialStep {
  final String targetId;
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) body;
  final String? route;
  final TutorialNav nav;
  final bool optional;

  const TutorialStep({
    required this.targetId,
    required this.title,
    required this.body,
    this.route,
    this.nav = TutorialNav.go,
    this.optional = false,
  });
}

class TutorialTour {
  final String id;
  final String route;
  final IconData icon;
  final bool advanced;
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) subtitle;
  final List<TutorialStep> steps;

  const TutorialTour({
    required this.id,
    required this.route,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.steps,
    this.advanced = false,
  });
}

abstract final class TutorialCatalog {
  static const train = 'train';
  static const food = 'food';
  static const progress = 'progress';
  static const routines = 'routines';
  static const supersets = 'supersets';
  static const foodLog = 'foodLog';
  static const workoutSession = 'workoutSession';

  static final List<TutorialTour> all = [
    TutorialTour(
      id: train,
      route: '/',
      icon: Icons.fitness_center_outlined,
      title: (l10n) => l10n.tutorialTrainTitle,
      subtitle: (l10n) => l10n.tutorialTrainSubtitle,
      steps: [
        TutorialStep(
          targetId: TutorialTargets.navTrain,
          title: (l10n) => l10n.tutorialTrainNavTitle,
          body: (l10n) => l10n.tutorialTrainNavBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.trainStart,
          title: (l10n) => l10n.tutorialTrainStartTitle,
          body: (l10n) => l10n.tutorialTrainStartBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.trainRoutinesTab,
          title: (l10n) => l10n.tutorialTrainRoutinesTitle,
          body: (l10n) => l10n.tutorialTrainRoutinesBody,
        ),
      ],
    ),
    TutorialTour(
      id: food,
      route: '/food',
      icon: Icons.restaurant_outlined,
      title: (l10n) => l10n.tutorialFoodTitle,
      subtitle: (l10n) => l10n.tutorialFoodSubtitle,
      steps: [
        TutorialStep(
          targetId: TutorialTargets.navFood,
          title: (l10n) => l10n.tutorialFoodNavTitle,
          body: (l10n) => l10n.tutorialFoodNavBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.foodBudget,
          title: (l10n) => l10n.tutorialFoodBudgetTitle,
          body: (l10n) => l10n.tutorialFoodBudgetBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.foodAddMeal,
          title: (l10n) => l10n.tutorialFoodAddTitle,
          body: (l10n) => l10n.tutorialFoodAddBody,
        ),
      ],
    ),
    TutorialTour(
      id: progress,
      route: '/progress',
      icon: Icons.show_chart_outlined,
      title: (l10n) => l10n.tutorialProgressTitle,
      subtitle: (l10n) => l10n.tutorialProgressSubtitle,
      steps: [
        TutorialStep(
          targetId: TutorialTargets.navProgress,
          title: (l10n) => l10n.tutorialProgressNavTitle,
          body: (l10n) => l10n.tutorialProgressNavBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.progressHero,
          title: (l10n) => l10n.tutorialProgressHeroTitle,
          body: (l10n) => l10n.tutorialProgressHeroBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.progressStats,
          title: (l10n) => l10n.tutorialProgressStatsTitle,
          body: (l10n) => l10n.tutorialProgressStatsBody,
        ),
      ],
    ),
    TutorialTour(
      id: routines,
      route: '/?tab=routines',
      icon: Icons.playlist_add_outlined,
      advanced: true,
      title: (l10n) => l10n.tutorialRoutinesTitle,
      subtitle: (l10n) => l10n.tutorialRoutinesSubtitle,
      steps: [
        TutorialStep(
          targetId: TutorialTargets.trainRoutinesTab,
          route: '/?tab=routines',
          title: (l10n) => l10n.tutorialRoutinesTabTitle,
          body: (l10n) => l10n.tutorialRoutinesTabBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.routineCreate,
          title: (l10n) => l10n.tutorialRoutinesCreateTitle,
          body: (l10n) => l10n.tutorialRoutinesCreateBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.routineAi,
          title: (l10n) => l10n.tutorialRoutinesAiTitle,
          body: (l10n) => l10n.tutorialRoutinesAiBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.routineName,
          route: '/routines/new',
          nav: TutorialNav.push,
          title: (l10n) => l10n.tutorialRoutinesNameTitle,
          body: (l10n) => l10n.tutorialRoutinesNameBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.routineAddExercise,
          title: (l10n) => l10n.tutorialRoutinesAddTitle,
          body: (l10n) => l10n.tutorialRoutinesAddBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.routineSave,
          title: (l10n) => l10n.tutorialRoutinesSaveTitle,
          body: (l10n) => l10n.tutorialRoutinesSaveBody,
        ),
      ],
    ),
    TutorialTour(
      id: supersets,
      route: '/?tab=routines',
      icon: Icons.link,
      advanced: true,
      title: (l10n) => l10n.tutorialSupersetTitle,
      subtitle: (l10n) => l10n.tutorialSupersetSubtitle,
      steps: [
        TutorialStep(
          targetId: TutorialTargets.trainRoutinesTab,
          route: '/?tab=routines',
          title: (l10n) => l10n.tutorialSupersetTabTitle,
          body: (l10n) => l10n.tutorialSupersetTabBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.routineCreate,
          title: (l10n) => l10n.tutorialSupersetCreateTitle,
          body: (l10n) => l10n.tutorialSupersetCreateBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.routineJoin,
          route: '/routines/new',
          nav: TutorialNav.push,
          title: (l10n) => l10n.tutorialSupersetJoinTitle,
          body: (l10n) => l10n.tutorialSupersetJoinBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.routineSupersetKind,
          title: (l10n) => l10n.tutorialSupersetKindTitle,
          body: (l10n) => l10n.tutorialSupersetKindBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.routineSupersetRounds,
          title: (l10n) => l10n.tutorialSupersetRoundsTitle,
          body: (l10n) => l10n.tutorialSupersetRoundsBody,
        ),
      ],
    ),
    TutorialTour(
      id: foodLog,
      route: '/food',
      icon: Icons.restaurant_menu_outlined,
      advanced: true,
      title: (l10n) => l10n.tutorialFoodLogTitle,
      subtitle: (l10n) => l10n.tutorialFoodLogSubtitle,
      steps: [
        TutorialStep(
          targetId: TutorialTargets.foodWeek,
          route: '/food',
          title: (l10n) => l10n.tutorialFoodLogWeekTitle,
          body: (l10n) => l10n.tutorialFoodLogWeekBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.foodBudgetEdit,
          title: (l10n) => l10n.tutorialFoodLogBudgetTitle,
          body: (l10n) => l10n.tutorialFoodLogBudgetBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.foodAddMeal,
          title: (l10n) => l10n.tutorialFoodLogAddTitle,
          body: (l10n) => l10n.tutorialFoodLogAddBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.foodAddSearch,
          route: '/food/add',
          nav: TutorialNav.push,
          title: (l10n) => l10n.tutorialFoodLogSearchTitle,
          body: (l10n) => l10n.tutorialFoodLogSearchBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.foodAddModes,
          title: (l10n) => l10n.tutorialFoodLogModesTitle,
          body: (l10n) => l10n.tutorialFoodLogModesBody,
        ),
      ],
    ),
    TutorialTour(
      id: workoutSession,
      route: '/',
      icon: Icons.play_circle_outline,
      advanced: true,
      title: (l10n) => l10n.tutorialWorkoutSessionTitle,
      subtitle: (l10n) => l10n.tutorialWorkoutSessionSubtitle,
      steps: [
        TutorialStep(
          targetId: TutorialTargets.trainStart,
          route: '/',
          title: (l10n) => l10n.tutorialWorkoutSessionStartTitle,
          body: (l10n) => l10n.tutorialWorkoutSessionStartBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.workoutAddExercise,
          route: '/workout/active',
          nav: TutorialNav.push,
          title: (l10n) => l10n.tutorialWorkoutSessionAddTitle,
          body: (l10n) => l10n.tutorialWorkoutSessionAddBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.workoutSwap,
          route: '/workout/active',
          nav: TutorialNav.push,
          title: (l10n) => l10n.tutorialWorkoutSessionSwapTitle,
          body: (l10n) => l10n.tutorialWorkoutSessionSwapBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.workoutReorder,
          route: '/workout/active',
          nav: TutorialNav.push,
          optional: true,
          title: (l10n) => l10n.tutorialWorkoutSessionReorderTitle,
          body: (l10n) => l10n.tutorialWorkoutSessionReorderBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.workoutRest,
          route: '/workout/active',
          nav: TutorialNav.push,
          optional: true,
          title: (l10n) => l10n.tutorialWorkoutSessionRestTitle,
          body: (l10n) => l10n.tutorialWorkoutSessionRestBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.workoutAddSet,
          route: '/workout/active',
          nav: TutorialNav.push,
          title: (l10n) => l10n.tutorialWorkoutSessionAddSetTitle,
          body: (l10n) => l10n.tutorialWorkoutSessionAddSetBody,
        ),
        TutorialStep(
          targetId: TutorialTargets.workoutRemoveSet,
          route: '/workout/active',
          nav: TutorialNav.push,
          optional: true,
          title: (l10n) => l10n.tutorialWorkoutSessionRemoveSetTitle,
          body: (l10n) => l10n.tutorialWorkoutSessionRemoveSetBody,
        ),
      ],
    ),
  ];

  static Iterable<TutorialTour> get basics =>
      all.where((tour) => !tour.advanced);

  static Iterable<TutorialTour> get advancedTours =>
      all.where((tour) => tour.advanced);

  static TutorialTour? byId(String? id) {
    if (id == null) return null;
    for (final tour in all) {
      if (tour.id == id) return tour;
    }
    return null;
  }
}
