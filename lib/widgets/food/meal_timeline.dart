import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/food_entry.dart';

class MealTimeline extends StatelessWidget {
  final DailyNutritionSummary summary;
  final AppLocalizations l10n;
  final void Function(MealType meal) onAdd;
  final ValueChanged<String> onDeleteEntry;

  const MealTimeline({
    super.key,
    required this.summary,
    required this.l10n,
    required this.onAdd,
    required this.onDeleteEntry,
  });

  static const _meals = [
    (MealType.breakfast, Icons.wb_sunny_outlined),
    (MealType.lunch, Icons.restaurant_outlined),
    (MealType.dinner, Icons.nightlight_outlined),
    (MealType.snack, Icons.local_cafe_outlined),
  ];

  String _mealTitle(MealType meal) => switch (meal) {
        MealType.breakfast => l10n.mealBreakfast,
        MealType.lunch => l10n.mealLunch,
        MealType.dinner => l10n.mealDinner,
        MealType.snack => l10n.mealSnack,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _meals.length; i++) ...[
          _MealTimelineNode(
            mealType: _meals[i].$1,
            icon: _meals[i].$2,
            title: _mealTitle(_meals[i].$1),
            eatenKcal: summary.eatenForMeal(_meals[i].$1).caloriesKcal,
            entries: summary.entriesByMeal[_meals[i].$1] ?? const [],
            isLast: i == _meals.length - 1,
            emptyLabel: l10n.foodTimelineEmpty,
            onAdd: () => onAdd(_meals[i].$1),
            onDeleteEntry: onDeleteEntry,
          ),
        ],
      ],
    );
  }
}

class _MealTimelineNode extends StatelessWidget {
  final MealType mealType;
  final IconData icon;
  final String title;
  final int eatenKcal;
  final List<FoodEntry> entries;
  final bool isLast;
  final String emptyLabel;
  final VoidCallback onAdd;
  final ValueChanged<String> onDeleteEntry;

  const _MealTimelineNode({
    required this.mealType,
    required this.icon,
    required this.title,
    required this.eatenKcal,
    required this.entries,
    required this.isLast,
    required this.emptyLabel,
    required this.onAdd,
    required this.onDeleteEntry,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.cardElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: eatenKcal > 0
                          ? AppColors.orange.withValues(alpha: 0.6)
                          : AppColors.border,
                    ),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.orange),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '$eatenKcal kcal',
                              style: TextStyle(
                                color: eatenKcal > 0 ? AppColors.orange : AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.orange,
                        tooltip: title,
                      ),
                    ],
                  ),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        emptyLabel,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    )
                  else
                    ...entries.map(
                      (entry) => _FoodEntryRow(
                        entry: entry,
                        onDelete: () => onDeleteEntry(entry.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodEntryRow extends StatelessWidget {
  final FoodEntry entry;
  final VoidCallback onDelete;

  const _FoodEntryRow({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  '${entry.caloriesKcal} kcal · P ${entry.proteinG.round()}g',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.textMuted,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
