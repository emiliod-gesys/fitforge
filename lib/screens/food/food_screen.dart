import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/food_entry.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/food/calorie_ring.dart';
import '../../widgets/food/macro_progress_bar.dart';
import '../../widgets/food/meal_card.dart';

class FoodScreen extends ConsumerWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final day = ref.watch(foodSelectedDayProvider);
    final summaryAsync = ref.watch(dailyNutritionProvider);

    return Scaffold(
      appBar: FitForgeAppBar(title: l10n.foodTitle),
      body: _FoodBody(
        summaryAsync: summaryAsync,
        day: day,
        l10n: l10n,
        onRefresh: () async {
          ref.invalidate(dailyNutritionProvider);
          ref.invalidate(foodEntriesProvider);
          ref.invalidate(foodDayWorkoutsProvider);
        },
        onDeleteEntry: (entryId) async {
          await ref.read(foodServiceProvider).deleteEntry(entryId);
          ref.invalidate(dailyNutritionProvider);
          ref.invalidate(foodEntriesProvider);
        },
        onAdd: (meal, selectedDay) => _openAdd(context, meal, selectedDay),
        onDayChanged: (d) => ref.read(foodSelectedDayProvider.notifier).state = d,
      ),
    );
  }

  void _openAdd(BuildContext context, MealType meal, DateTime day) {
    context.push('/food/add', extra: {'meal': meal, 'day': day});
  }
}

class _FoodBody extends StatelessWidget {
  final AsyncValue<DailyNutritionSummary> summaryAsync;
  final DateTime day;
  final AppLocalizations l10n;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String entryId) onDeleteEntry;
  final void Function(MealType meal, DateTime day) onAdd;
  final ValueChanged<DateTime> onDayChanged;

  const _FoodBody({
    required this.summaryAsync,
    required this.day,
    required this.l10n,
    required this.onRefresh,
    required this.onDeleteEntry,
    required this.onAdd,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (summaryAsync.hasError && !summaryAsync.hasValue) {
      return Center(child: Text(l10n.errorGeneric('${summaryAsync.error}')));
    }

    if (!summaryAsync.hasValue) {
      return const FitForgeLoadingScreen();
    }

    final summary = summaryAsync.value!;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _DaySelector(day: day, onChanged: onDayChanged),
              const SizedBox(height: 16),
              _SummaryHeader(summary: summary, l10n: l10n),
              const SizedBox(height: 20),
              if (!summary.bmrAvailable) ...[
                Card(
                  color: AppColors.cardElevated,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      l10n.foodBmrMissingHint,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                l10n.foodMealsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              MealCard(
                mealType: MealType.breakfast,
                title: l10n.mealBreakfast,
                emoji: '🌅',
                eatenKcal: summary.eatenForMeal(MealType.breakfast).caloriesKcal,
                goalKcal: summary.mealCalorieGoal(MealType.breakfast),
                entries: summary.entriesByMeal[MealType.breakfast] ?? const [],
                onAdd: () => onAdd(MealType.breakfast, day),
              ),
              MealCard(
                mealType: MealType.lunch,
                title: l10n.mealLunch,
                emoji: '🍽️',
                eatenKcal: summary.eatenForMeal(MealType.lunch).caloriesKcal,
                goalKcal: summary.mealCalorieGoal(MealType.lunch),
                entries: summary.entriesByMeal[MealType.lunch] ?? const [],
                onAdd: () => onAdd(MealType.lunch, day),
              ),
              MealCard(
                mealType: MealType.dinner,
                title: l10n.mealDinner,
                emoji: '🌙',
                eatenKcal: summary.eatenForMeal(MealType.dinner).caloriesKcal,
                goalKcal: summary.mealCalorieGoal(MealType.dinner),
                entries: summary.entriesByMeal[MealType.dinner] ?? const [],
                onAdd: () => onAdd(MealType.dinner, day),
              ),
              MealCard(
                mealType: MealType.snack,
                title: l10n.mealSnack,
                emoji: '🥤',
                eatenKcal: summary.eatenForMeal(MealType.snack).caloriesKcal,
                goalKcal: summary.mealCalorieGoal(MealType.snack),
                entries: summary.entriesByMeal[MealType.snack] ?? const [],
                onAdd: () => onAdd(MealType.snack, day),
              ),
              const SizedBox(height: 8),
              ..._FoodScreenHelpers.allEntries(summary).map(
                (entry) => _FoodEntryTile(
                  entry: entry,
                  onDelete: () => onDeleteEntry(entry.id),
                ),
              ),
            ],
          ),
        ),
        if (summaryAsync.isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2, color: AppColors.orange),
          ),
      ],
    );
  }
}

abstract final class _FoodScreenHelpers {
  static List<FoodEntry> allEntries(DailyNutritionSummary summary) {
    return summary.entriesByMeal.values.expand((list) => list).toList();
  }
}

class _DaySelector extends StatelessWidget {
  final DateTime day;
  final ValueChanged<DateTime> onChanged;

  const _DaySelector({required this.day, required this.onChanged});

  bool get _isToday {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = _isToday
        ? l10n.today
        : '${day.day}/${day.month}/${day.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => onChanged(day.subtract(const Duration(days: 1))),
          icon: const Icon(Icons.chevron_left),
        ),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.orange),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        IconButton(
          onPressed: _isToday
              ? null
              : () {
                  final next = day.add(const Duration(days: 1));
                  final now = DateTime.now();
                  if (next.isAfter(DateTime(now.year, now.month, now.day))) return;
                  onChanged(next);
                },
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final DailyNutritionSummary summary;
  final AppLocalizations l10n;

  const _SummaryHeader({required this.summary, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withValues(alpha: 0.25),
            AppColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatColumn(label: l10n.foodEaten, value: '${summary.caloriesEaten}'),
              CalorieRing(
                remaining: summary.caloriesRemaining,
                budget: summary.calorieBudget,
                eaten: summary.caloriesEaten,
                burned: summary.workoutCaloriesBurned,
              ),
              _StatColumn(label: l10n.foodBurned, value: '${summary.workoutCaloriesBurned}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.foodCaloriesLeft(summary.caloriesRemaining),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          if (summary.workoutCaloriesBurned > 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.foodWorkoutBonus(summary.workoutCaloriesBurned),
              style: const TextStyle(color: AppColors.orange, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          MacroProgressBar(
            label: l10n.macroProtein,
            current: summary.eaten.proteinG,
            target: summary.targets.proteinG,
            color: const Color(0xFFE85D75),
          ),
          const SizedBox(height: 10),
          MacroProgressBar(
            label: l10n.macroFat,
            current: summary.eaten.fatG,
            target: summary.targets.fatG,
            color: const Color(0xFFF5B942),
          ),
          const SizedBox(height: 10),
          MacroProgressBar(
            label: l10n.macroCarbs,
            current: summary.eaten.carbsG,
            target: summary.targets.carbsG,
            color: const Color(0xFF5BB8F0),
          ),
          const SizedBox(height: 10),
          MacroProgressBar(
            label: l10n.macroFiber,
            current: summary.eaten.fiberG,
            target: summary.targets.fiberG,
            color: const Color(0xFF9E7B5A),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}

class _FoodEntryTile extends StatelessWidget {
  final FoodEntry entry;
  final VoidCallback onDelete;

  const _FoodEntryTile({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(entry.name),
        subtitle: Text('${entry.caloriesKcal} kcal · P ${entry.proteinG.round()}g'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
