import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../models/exercise.dart';
import 'exercise_thumbnail.dart';
import 'localized_exercise_name.dart';

class ExerciseCard extends ConsumerWidget {
  final Exercise exercise;
  final VoidCallback? onTap;

  const ExerciseCard({super.key, required this.exercise, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ExerciseThumbnail(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                category: exercise.category,
                muscles: exercise.muscles,
                width: 56,
                height: 56,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LocalizedExerciseName(
                            exercise.name,
                            exerciseId: exercise.id,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (exercise.isUserCustom) ...[
                          const SizedBox(width: 6),
                          Chip(
                            label: Text(l10n.customExerciseTag, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      () {
                        final parts = <String>[
                          l10n.exerciseCategoryLabel(exercise.category),
                          if (exercise.muscles.isNotEmpty) l10n.muscleLabel(exercise.muscles.first),
                        ];
                        if (parts.length == 2 && parts[0] == parts[1]) {
                          return parts[0];
                        }
                        return parts.join(' · ');
                      }(),
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}
