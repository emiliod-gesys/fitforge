import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../models/routine.dart';

class AiRoutinePreviewCard extends StatelessWidget {
  final Routine routine;
  final bool isSaved;
  final bool isDiscarded;
  final VoidCallback onSave;
  final VoidCallback onEdit;
  final VoidCallback onDiscard;

  const AiRoutinePreviewCard({
    super.key,
    required this.routine,
    required this.isSaved,
    required this.isDiscarded,
    required this.onSave,
    required this.onEdit,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (isDiscarded) {
      return _StatusBanner(
        icon: Icons.delete_outline,
        text: l10n.routineDiscarded,
        color: AppColors.textMuted,
      );
    }

    if (isSaved) {
      return _StatusBanner(
        icon: Icons.check_circle,
        text: l10n.routineSaved,
        color: AppColors.orange,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  routine.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          if (routine.description != null && routine.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              routine.description!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
          if (routine.targetMuscles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              routine.targetMuscles.join(' · '),
              style: const TextStyle(color: AppColors.orange, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          ...routine.exercises.take(8).map(_exerciseLine),
          if (routine.exercises.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.moreExercises(routine.exercises.length - 8),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDiscard,
                  child: Text(l10n.discard),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  child: Text(l10n.edit),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onSave,
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _exerciseLine(RoutineExercise ex) {
    final weight = ex.targetWeight != null ? ' · ${ex.targetWeight!.toStringAsFixed(0)} kg' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.orange)),
          Expanded(
            child: Text(
              '${ex.exerciseName} — ${ex.targetSets}×${ex.targetReps}$weight',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }
}
