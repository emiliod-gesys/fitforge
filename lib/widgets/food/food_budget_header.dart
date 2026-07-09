import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/food_entry.dart';
import '../../core/theme/app_accent.dart';

class FoodBudgetHeader extends StatelessWidget {
  final DailyNutritionSummary summary;
  final AppLocalizations l10n;

  const FoodBudgetHeader({
    super.key,
    required this.summary,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final budget = summary.calorieBudget;
    final eaten = summary.caloriesEaten;
    final isSurplus = summary.isCaloricSurplus;
    final displayKcal = isSurplus ? summary.caloriesSurplus : summary.caloriesRemaining;
    final progress = budget > 0 ? (eaten / budget) : 0.0;
    final percentUsed = budget > 0 ? (progress * 100).round() : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.foodDailyBudget,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatNumber(displayKcal),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: isSurplus ? AppColors.error : AppColors.textPrimary,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  isSurplus ? l10n.foodCaloriesSurplus : l10n.foodCaloriesAvailable,
                  style: TextStyle(
                    color: isSurplus ? AppColors.error.withValues(alpha: 0.85) : AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.cardElevated,
              color: isSurplus ? AppColors.error : context.accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.foodBudgetUsed(percentUsed),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BudgetStatTile(
                  icon: Icons.restaurant_outlined,
                  label: l10n.foodEaten,
                  value: eaten,
                  accent: const Color(0xFF5BB8F0),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _BudgetStatTile(
                  icon: Icons.local_fire_department_outlined,
                  label: l10n.foodBurned,
                  value: summary.totalCaloriesBurned,
                  accent: context.accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BudgetStatTile(
                  icon: Icons.flag_outlined,
                  label: l10n.foodStatGoal,
                  value: budget,
                  accent: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (summary.workoutCaloriesBurned > 0 ||
              summary.manualActivityCaloriesBurned > 0) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (summary.workoutCaloriesBurned > 0)
                  _BonusChip(
                    icon: Icons.fitness_center_outlined,
                    label: l10n.foodWorkoutBonus(summary.workoutCaloriesBurned),
                  ),
                if (summary.manualActivityCaloriesBurned > 0)
                  _BonusChip(
                    icon: Icons.directions_run_outlined,
                    label: l10n.foodManualActivityBonus(summary.manualActivityCaloriesBurned),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatNumber(int value) {
    final s = value.toString();
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _BudgetStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color accent;

  const _BudgetStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(height: 8),
          Text(
            FoodBudgetHeader._formatNumber(value),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
              color: accent,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BonusChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BonusChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.accentColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.accentColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: context.accentColor, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
