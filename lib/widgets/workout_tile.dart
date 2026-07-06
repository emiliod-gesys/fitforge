import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/unit_converter.dart';
import '../l10n/l10n_extensions.dart';
import '../models/workout.dart';

class WorkoutTile extends StatelessWidget {
  final Workout workout;
  final String unitSystem;
  final List<String> muscleGroups;
  final bool showTopVolumeBadge;
  final bool enableSwipeRepeat;
  final VoidCallback? onRepeat;
  final VoidCallback? onTap;

  const WorkoutTile({
    super.key,
    required this.workout,
    required this.unitSystem,
    this.muscleGroups = const [],
    this.showTopVolumeBadge = false,
    this.enableSwipeRepeat = false,
    this.onRepeat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final when = l10n.timeAgo(workout.startedAt);
    final volume = UnitConverter.formatVolume(workout.totalVolume, unitSystem);

    final tile = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        leading: CircleAvatar(
          backgroundColor: AppColors.orange.withValues(alpha: 0.15),
          child: const Icon(Icons.fitness_center, color: AppColors.orange),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                l10n.workoutDisplayName(workout.name),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (showTopVolumeBadge)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_outlined, size: 14, color: Color(0xFFFFD54F)),
                    const SizedBox(width: 4),
                    Text(
                      l10n.trainVolumePr,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFFFD54F)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '$when · ${workout.durationMinutes} ${l10n.minutes} · $volume ${l10n.volumeShort}',
              style: const TextStyle(fontSize: 13),
            ),
            if (muscleGroups.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: muscleGroups.take(3).map((muscle) {
                  return Chip(
                    label: Text(l10n.muscleLabel(muscle)),
                    labelStyle: const TextStyle(fontSize: 11),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.cardElevated,
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        trailing: workout.isActive
            ? Chip(
                label: Text(l10n.active),
                backgroundColor: AppColors.orange.withValues(alpha: 0.2),
                labelStyle: const TextStyle(color: AppColors.orange),
              )
            : onTap != null
                ? const Icon(Icons.chevron_right, color: AppColors.textMuted)
                : null,
        isThreeLine: muscleGroups.isNotEmpty,
      ),
    );

    if (!enableSwipeRepeat || onRepeat == null || workout.isActive) {
      return tile;
    }

    return Dismissible(
      key: ValueKey('repeat_${workout.id}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          children: [
            const Icon(Icons.replay_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              l10n.trainSwipeRepeat,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.lightImpact();
        onRepeat!();
        return false;
      },
      child: tile,
    );
  }
}
