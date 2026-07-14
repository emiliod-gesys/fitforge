import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/workout_summary.dart';

/// Estimated calories burned for a completed workout summary.
class WorkoutCalorieEstimateDisplay extends StatelessWidget {
  final WorkoutSummaryData summary;
  final AppLocalizations l10n;
  final Color? accent;

  const WorkoutCalorieEstimateDisplay({
    super.key,
    required this.summary,
    required this.l10n,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (!summary.hasCalorieEstimate) return const SizedBox.shrink();

    final kcal = l10n.caloriesKcal(summary.calorieEstimate.caloriesKcal!);
    final note = summary.calorieEstimate.usedDefaultWeight
        ? l10n.caloriesEstimateDefaultWeight
        : l10n.caloriesEstimateNote;
    final valueColor = accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_fire_department_outlined,
              size: 18,
              color: valueColor ?? AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.caloriesBurned,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              kcal,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: valueColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          note,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
        ),
      ],
    );
  }
}
