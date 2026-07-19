import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/similar_exercises.dart';
import '../l10n/l10n_extensions.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../providers/app_providers.dart';
import 'exercise_card.dart';
import 'fitforge_loading_indicator.dart';

class SimilarExercisePickerSheet extends ConsumerWidget {
  final WorkoutExercise current;
  final Set<String> excludeExerciseIds;

  const SimilarExercisePickerSheet({
    super.key,
    required this.current,
    this.excludeExerciseIds = const {},
  });

  static Future<Exercise?> show(
    BuildContext context, {
    required WorkoutExercise current,
    Set<String> excludeExerciseIds = const {},
  }) {
    return showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, __) => SimilarExercisePickerSheet(
          current: current,
          excludeExerciseIds: excludeExerciseIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final exercisesAsync = ref.watch(exercisesProvider);

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.swapSimilar,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      current.exerciseName,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: exercisesAsync.when(
            loading: () => const Center(child: FitForgeLoadingIndicator(size: 48)),
            error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
            data: (catalog) {
              final similar = SimilarExercises.find(
                exerciseName: current.exerciseName,
                exerciseId: current.exerciseId,
                catalog: catalog,
                excludeIds: excludeExerciseIds,
              );

              if (similar.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.noSimilarFound,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: similar.length,
                itemBuilder: (_, i) {
                  final exercise = similar[i];
                  return ExerciseCard(
                    exercise: exercise,
                    onTap: () => Navigator.pop(context, exercise),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
