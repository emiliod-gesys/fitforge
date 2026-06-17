import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/unit_converter.dart';
import '../l10n/l10n_extensions.dart';
import '../models/workout.dart';

class WorkoutTile extends StatelessWidget {
  final Workout workout;
  final String unitSystem;

  const WorkoutTile({
    super.key,
    required this.workout,
    required this.unitSystem,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat('dd MMM yyyy, HH:mm', locale).format(workout.startedAt.toLocal());
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.orange.withValues(alpha: 0.15),
          child: const Icon(Icons.fitness_center, color: AppColors.orange),
        ),
        title: Text(l10n.workoutDisplayName(workout.name)),
        subtitle: Text(
          '$date · ${workout.durationMinutes} ${l10n.minutes} · ${UnitConverter.formatVolume(workout.totalVolume, unitSystem)} ${l10n.volumeShort}',
        ),
        trailing: workout.isActive
            ? Chip(
                label: Text(l10n.active),
                backgroundColor: AppColors.orange.withValues(alpha: 0.2),
                labelStyle: const TextStyle(color: AppColors.orange),
              )
            : null,
      ),
    );
  }
}
