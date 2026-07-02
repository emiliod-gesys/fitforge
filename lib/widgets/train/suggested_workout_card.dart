import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/train_suggestion_resolver.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/routine.dart';

class SuggestedWorkoutCard extends StatelessWidget {
  final Routine routine;
  final TrainSuggestionReason reason;
  final VoidCallback onStart;

  const SuggestedWorkoutCard({
    super.key,
    required this.routine,
    required this.reason,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reasonLabel = switch (reason) {
      TrainSuggestionReason.lastRoutine => l10n.trainSuggestedLastRoutine,
      TrainSuggestionReason.recovery => l10n.trainSuggestedRecovery,
      TrainSuggestionReason.defaultPick => l10n.trainSuggestedDefault,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.orange, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.trainSuggestedTitle,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        routine.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              reasonLabel,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            if (routine.targetMuscles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: routine.targetMuscles.take(4).map((muscle) {
                  return Chip(
                    label: Text(l10n.muscleLabel(muscle)),
                    labelStyle: const TextStyle(fontSize: 12),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.cardElevated,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_circle_outline),
                label: Text(l10n.trainStartSuggested),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.orange,
                  side: const BorderSide(color: AppColors.orange),
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 80.ms, duration: 350.ms)
        .slideY(begin: 0.03, end: 0, delay: 80.ms, duration: 350.ms);
  }
}
