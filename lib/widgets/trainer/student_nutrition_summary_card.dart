import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/food_entry.dart';
import '../../core/theme/app_accent.dart';
/// Resumen nutricional compacto para que el entrenador vea el día del alumno.
class StudentNutritionSummaryCard extends StatelessWidget {
  final DailyNutritionSummary summary;
  final DateTime day;
  final AppLocalizations l10n;

  const StudentNutritionSummaryCard({
    super.key,
    required this.summary,
    required this.day,
    required this.l10n,
  });

  String _title(BuildContext context) {
    final now = DateTime.now();
    final selected = DateTime(day.year, day.month, day.day);
    final today = DateTime(now.year, now.month, now.day);
    if (selected == today) return l10n.studentNutritionTitle;
    final locale = Localizations.localeOf(context).toString();
    return l10n.studentNutritionTitleDate(DateFormat.yMMMd(locale).format(selected));
  }

  @override
  Widget build(BuildContext context) {    final budget = summary.calorieBudget;
    final eaten = summary.caloriesEaten;
    final isSurplus = summary.isCaloricSurplus;
    final displayKcal = isSurplus ? summary.caloriesSurplus : summary.caloriesRemaining;
    final progress = budget > 0 ? (eaten / budget).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_outlined, size: 18, color: context.accentColor),
                const SizedBox(width: 8),
                Text(
                  _title(context),
                  style: const TextStyle(                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$displayKcal',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -1,
                    color: isSurplus ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isSurplus ? l10n.foodCaloriesSurplus : l10n.foodCaloriesAvailable,
                  style: TextStyle(
                    color: isSurplus ? AppColors.error.withValues(alpha: 0.85) : AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.cardElevated,
                color: isSurplus ? AppColors.error : context.accentColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${l10n.foodEaten}: $eaten · ${l10n.foodBurned}: ${summary.totalCaloriesBurned} · ${l10n.foodStatGoal}: $budget',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MacroMini(
                    label: l10n.macroProtein,
                    current: summary.eaten.proteinG,
                    target: summary.targets.proteinG,
                    color: const Color(0xFFE85D75),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroMini(
                    label: l10n.macroCarbs,
                    current: summary.eaten.carbsG,
                    target: summary.targets.carbsG,
                    color: const Color(0xFF5BB8F0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MacroMini(
                    label: l10n.macroFat,
                    current: summary.eaten.fatG,
                    target: summary.targets.fatG,
                    color: const Color(0xFFF5B942),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroMini(
                    label: l10n.macroFiber,
                    current: summary.eaten.fiberG,
                    target: summary.targets.fiberG,
                    color: const Color(0xFF7BC67E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroMini extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;

  const _MacroMini({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${current.round()}/${target.round()}g',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: AppColors.card,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
