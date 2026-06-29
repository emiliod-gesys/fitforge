import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/manual_activity_entry.dart';

class WorkoutEnergyItem {
  final String name;
  final int kcal;

  const WorkoutEnergyItem({required this.name, required this.kcal});
}

class EnergyOutputSection extends StatelessWidget {
  final AppLocalizations l10n;
  final List<WorkoutEnergyItem> workoutItems;
  final List<ManualActivityEntry> manualActivities;
  final VoidCallback onAddActivity;
  final ValueChanged<String> onDeleteActivity;

  const EnergyOutputSection({
    super.key,
    required this.l10n,
    required this.workoutItems,
    required this.manualActivities,
    required this.onAddActivity,
    required this.onDeleteActivity,
  });

  int get _totalKcal =>
      workoutItems.fold<int>(0, (sum, w) => sum + w.kcal) +
      manualActivities.fold<int>(0, (sum, a) => sum + a.caloriesKcal);

  @override
  Widget build(BuildContext context) {
    final hasWorkouts = workoutItems.isNotEmpty;
    final hasManual = manualActivities.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.foodEnergyOutputTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (_totalKcal > 0)
                    Text(
                      '$_totalKcal kcal',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: onAddActivity,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.foodAddActivity),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange,
                side: BorderSide(color: AppColors.orange.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!hasWorkouts && !hasManual)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              l10n.foodEnergyOutputEmpty,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          )
        else ...[
          ...workoutItems.map(
            (item) => _EnergyRow(
              icon: Icons.fitness_center_outlined,
              title: item.name,
              subtitle: l10n.foodFromFitForgeWorkout,
              kcal: item.kcal,
            ),
          ),
          ...manualActivities.map(
            (activity) => _EnergyRow(
              icon: Icons.directions_run_outlined,
              title: activity.name,
              subtitle: l10n.foodManualActivityLabel,
              kcal: activity.caloriesKcal,
              onDelete: () => onDeleteActivity(activity.id),
            ),
          ),
        ],
      ],
    );
  }
}

class _EnergyRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int kcal;
  final VoidCallback? onDelete;

  const _EnergyRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.kcal,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '$kcal kcal',
            style: const TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.textMuted,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}
