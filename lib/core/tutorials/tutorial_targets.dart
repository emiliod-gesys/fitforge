import 'package:flutter/material.dart';

/// Ids estables y [GlobalKey]s para anclar el spotlight a controles reales.
abstract final class TutorialTargets {
  static const navTrain = 'navTrain';
  static const navFood = 'navFood';
  static const navProgress = 'navProgress';
  static const trainStart = 'trainStart';
  static const trainRoutinesTab = 'trainRoutinesTab';
  static const foodBudget = 'foodBudget';
  static const foodAddMeal = 'foodAddMeal';
  static const progressHero = 'progressHero';
  static const progressStats = 'progressStats';
  static const routineCreate = 'routineCreate';
  static const routineAi = 'routineAi';
  static const routineName = 'routineName';
  static const routineAddExercise = 'routineAddExercise';
  static const routineSave = 'routineSave';
  static const routineJoin = 'routineJoin';
  static const routineSupersetKind = 'routineSupersetKind';
  static const routineSupersetRounds = 'routineSupersetRounds';
  static const foodWeek = 'foodWeek';
  static const foodBudgetEdit = 'foodBudgetEdit';
  static const foodAddSearch = 'foodAddSearch';
  static const foodAddModes = 'foodAddModes';
  static const workoutAddExercise = 'workoutAddExercise';
  static const workoutSwap = 'workoutSwap';
  static const workoutReorder = 'workoutReorder';
  static const workoutRest = 'workoutRest';
  static const workoutAddSet = 'workoutAddSet';
  static const workoutRemoveSet = 'workoutRemoveSet';

  static final navTrainKey = GlobalKey(debugLabel: 'tutorial_navTrain');
  static final navFoodKey = GlobalKey(debugLabel: 'tutorial_navFood');
  static final navProgressKey = GlobalKey(debugLabel: 'tutorial_navProgress');
  static final trainStartKey = GlobalKey(debugLabel: 'tutorial_trainStart');
  static final trainRoutinesTabKey =
      GlobalKey(debugLabel: 'tutorial_trainRoutinesTab');
  static final foodBudgetKey = GlobalKey(debugLabel: 'tutorial_foodBudget');
  static final foodAddMealKey = GlobalKey(debugLabel: 'tutorial_foodAddMeal');
  static final progressHeroKey = GlobalKey(debugLabel: 'tutorial_progressHero');
  static final progressStatsKey =
      GlobalKey(debugLabel: 'tutorial_progressStats');
  static final routineCreateKey =
      GlobalKey(debugLabel: 'tutorial_routineCreate');
  static final routineAiKey = GlobalKey(debugLabel: 'tutorial_routineAi');
  static final routineNameKey = GlobalKey(debugLabel: 'tutorial_routineName');
  static final routineAddExerciseKey =
      GlobalKey(debugLabel: 'tutorial_routineAddExercise');
  static final routineSaveKey = GlobalKey(debugLabel: 'tutorial_routineSave');
  static final routineJoinKey = GlobalKey(debugLabel: 'tutorial_routineJoin');
  static final routineSupersetKindKey =
      GlobalKey(debugLabel: 'tutorial_routineSupersetKind');
  static final routineSupersetRoundsKey =
      GlobalKey(debugLabel: 'tutorial_routineSupersetRounds');
  static final foodWeekKey = GlobalKey(debugLabel: 'tutorial_foodWeek');
  static final foodBudgetEditKey =
      GlobalKey(debugLabel: 'tutorial_foodBudgetEdit');
  static final foodAddSearchKey =
      GlobalKey(debugLabel: 'tutorial_foodAddSearch');
  static final foodAddModesKey = GlobalKey(debugLabel: 'tutorial_foodAddModes');
  static final workoutAddExerciseKey =
      GlobalKey(debugLabel: 'tutorial_workoutAddExercise');
  static final workoutSwapKey = GlobalKey(debugLabel: 'tutorial_workoutSwap');
  static final workoutReorderKey =
      GlobalKey(debugLabel: 'tutorial_workoutReorder');
  static final workoutRestKey = GlobalKey(debugLabel: 'tutorial_workoutRest');
  static final workoutAddSetKey =
      GlobalKey(debugLabel: 'tutorial_workoutAddSet');
  static final workoutRemoveSetKey =
      GlobalKey(debugLabel: 'tutorial_workoutRemoveSet');

  static GlobalKey? keyFor(String targetId) {
    return switch (targetId) {
      navTrain => navTrainKey,
      navFood => navFoodKey,
      navProgress => navProgressKey,
      trainStart => trainStartKey,
      trainRoutinesTab => trainRoutinesTabKey,
      foodBudget => foodBudgetKey,
      foodAddMeal => foodAddMealKey,
      progressHero => progressHeroKey,
      progressStats => progressStatsKey,
      routineCreate => routineCreateKey,
      routineAi => routineAiKey,
      routineName => routineNameKey,
      routineAddExercise => routineAddExerciseKey,
      routineSave => routineSaveKey,
      routineJoin => routineJoinKey,
      routineSupersetKind => routineSupersetKindKey,
      routineSupersetRounds => routineSupersetRoundsKey,
      foodWeek => foodWeekKey,
      foodBudgetEdit => foodBudgetEditKey,
      foodAddSearch => foodAddSearchKey,
      foodAddModes => foodAddModesKey,
      workoutAddExercise => workoutAddExerciseKey,
      workoutSwap => workoutSwapKey,
      workoutReorder => workoutReorderKey,
      workoutRest => workoutRestKey,
      workoutAddSet => workoutAddSetKey,
      workoutRemoveSet => workoutRemoveSetKey,
      _ => null,
    };
  }
}
