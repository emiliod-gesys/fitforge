import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

import '../../core/utils/workout_calorie_estimator.dart';

import '../../l10n/l10n_extensions.dart';

import '../../models/food_entry.dart';

import '../../providers/app_providers.dart';

import '../../widgets/fitforge_app_bar.dart';

import '../../widgets/fitforge_loading_indicator.dart';

import '../../widgets/food/energy_output_section.dart';

import '../../widgets/food/food_budget_header.dart';

import '../../widgets/food/food_week_strip.dart';

import '../../widgets/food/macro_chip_grid.dart';

import '../../widgets/food/manual_activity_sheet.dart';

import '../../widgets/food/meal_timeline.dart';
import '../../core/theme/app_accent.dart';



class FoodScreen extends ConsumerWidget {

  const FoodScreen({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final l10n = context.l10n;

    final day = ref.watch(foodSelectedDayProvider);

    final summaryAsync = ref.watch(dailyNutritionProvider);



    void invalidateNutrition() {

      ref.invalidate(dailyNutritionProvider);

      ref.invalidate(foodEntriesProvider);

      ref.invalidate(foodDayWorkoutsProvider);

      ref.invalidate(manualActivitiesProvider);

    }



    return Scaffold(

      appBar: FitForgeAppBar(title: l10n.foodTitle),

      body: _FoodBody(

        summaryAsync: summaryAsync,

        day: day,

        onRefresh: () async => invalidateNutrition(),

        onDeleteEntry: (entryId) async {

          await ref.read(foodServiceProvider).deleteEntry(entryId);

          invalidateNutrition();

        },

        onDeleteActivity: (activityId) async {

          await ref.read(activityLogServiceProvider).deleteEntry(activityId);

          invalidateNutrition();

        },

        onAdd: (meal, selectedDay) => context.push('/food/add', extra: {'meal': meal, 'day': selectedDay}),

        onAddActivity: (selectedDay) => ManualActivitySheet.show(

          context,

          service: ref.read(activityLogServiceProvider),

          day: selectedDay,

          onSaved: invalidateNutrition,

        ),

        onDayChanged: (d) => ref.read(foodSelectedDayProvider.notifier).state = d,

      ),

    );

  }

}



class _FoodBody extends ConsumerWidget {

  final AsyncValue<DailyNutritionSummary> summaryAsync;

  final DateTime day;

  final Future<void> Function() onRefresh;

  final Future<void> Function(String entryId) onDeleteEntry;

  final Future<void> Function(String activityId) onDeleteActivity;

  final void Function(MealType meal, DateTime day) onAdd;

  final void Function(DateTime day) onAddActivity;

  final ValueChanged<DateTime> onDayChanged;



  const _FoodBody({

    required this.summaryAsync,

    required this.day,

    required this.onRefresh,

    required this.onDeleteEntry,

    required this.onDeleteActivity,

    required this.onAdd,

    required this.onAddActivity,

    required this.onDayChanged,

  });



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final l10n = context.l10n;



    if (summaryAsync.hasError && !summaryAsync.hasValue) {

      return Center(child: Text(l10n.errorGeneric('${summaryAsync.error}')));

    }



    if (!summaryAsync.hasValue) {

      return const FitForgeLoadingScreen();

    }



    final summary = summaryAsync.value!;

    final normalizedDay = DateTime(day.year, day.month, day.day);

    final profile = ref.watch(profileProvider).valueOrNull;

    final bodyMetrics = ref.watch(bodyMetricSnapshotsProvider).valueOrNull;

    final workouts = ref.watch(foodDayWorkoutsProvider(normalizedDay)).valueOrNull ?? const [];



    final workoutItems = workouts

        .map(

          (workout) => WorkoutEnergyItem(

            name: l10n.workoutDisplayName(workout.name),

            kcal: WorkoutCalorieEstimator.resolvedActiveCalories(

              workout: workout,

              profile: profile,

              bodyMetrics: bodyMetrics,

            ),

          ),

        )

        .toList();



    return Stack(

      children: [

        RefreshIndicator(

          onRefresh: onRefresh,

          color: context.accentColor,

          child: ListView(

            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),

            children: [

              FoodWeekStrip(selectedDay: normalizedDay, onChanged: onDayChanged),

              const SizedBox(height: 20),

              FoodBudgetHeader(summary: summary, l10n: l10n),

              const SizedBox(height: 16),

              MacroChipGrid(

                eaten: summary.eaten,

                targets: summary.targets,

                proteinLabel: l10n.macroProtein,

                carbsLabel: l10n.macroCarbs,

                fatLabel: l10n.macroFat,

                fiberLabel: l10n.macroFiber,

              ),

              if (!summary.bmrAvailable) ...[

                const SizedBox(height: 12),

                Container(

                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(

                    color: AppColors.cardElevated,

                    borderRadius: BorderRadius.circular(14),

                    border: Border.all(color: AppColors.border),

                  ),

                  child: Text(

                    l10n.foodBmrMissingHint,

                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),

                  ),

                ),

              ],

              const SizedBox(height: 28),

              Text(

                l10n.foodMealsTitle,

                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),

              ),

              const SizedBox(height: 14),

              MealTimeline(

                summary: summary,

                l10n: l10n,

                onAdd: (meal) => onAdd(meal, normalizedDay),

                onDeleteEntry: (id) => onDeleteEntry(id),

              ),

              const SizedBox(height: 28),

              EnergyOutputSection(

                l10n: l10n,

                workoutItems: workoutItems,

                manualActivities: summary.manualActivities,

                onAddActivity: () => onAddActivity(normalizedDay),

                onDeleteActivity: (id) => onDeleteActivity(id),

              ),

            ],

          ),

        ),

        if (summaryAsync.isLoading)

          Positioned(

            top: 0,

            left: 0,

            right: 0,

            child: LinearProgressIndicator(minHeight: 2, color: context.accentColor),

          ),

      ],

    );

  }

}


