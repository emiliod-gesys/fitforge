import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/cloud_exercise_catalog.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/exercise.dart';
import '../../providers/app_providers.dart';
import '../../services/custom_exercise_repository.dart';
import '../../services/exercise_service.dart';
import '../../widgets/exercise_thumbnail.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final String exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  Future<void> _deleteCustom(BuildContext context, WidgetRef ref, Exercise exercise) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCustomExercise),
        content: Text(l10n.deleteCustomExerciseConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final customId = CustomExerciseRepository.parseCustomId(exercise.id);
    if (customId == null) return;

    await ref.read(customExerciseRepositoryProvider).delete(customId);
    ref.read(customExerciseRepositoryProvider).clearCache();
    ref.read(exerciseServiceProvider).clearCache();
    ref.invalidate(exercisesProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.customExerciseDeleted)));
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    if (CloudExerciseCatalogIds.isCloudId(exerciseId)) {
      final cloudAsync = ref.watch(cloudExerciseByIdProvider(exerciseId));
      return Scaffold(
        appBar: FitForgeAppBar(title: l10n.exerciseDetailTitle),
        body: cloudAsync.when(
          data: (exercise) {
            if (exercise == null) {
              return Center(child: Text(l10n.exerciseNotFound));
            }
            return _ExerciseBody(
              exercise: exercise,
              media: ExerciseMedia(videoUrl: exercise.videoUrl),
            );
          },
          loading: () => const FitForgeLoadingScreen(),
          error: (e, _) => Center(child: Text(l10n.errorGeneric(e.toString()))),
        ),
      );
    }

    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: FitForgeAppBar(title: l10n.exerciseDetailTitle),
      body: exercisesAsync.when(
        data: (exercises) {
          final exercise = exercises.cast<Exercise?>().firstWhere(
                (e) => e?.id == exerciseId,
                orElse: () => null,
              );

          if (exercise == null) {
            return Center(child: Text(l10n.exerciseNotFound));
          }

          final wgerId = exercise.wgerId;
          final mediaAsync = (wgerId != null && wgerId > 0)
              ? ref.watch(exerciseMediaProvider(wgerId))
              : const AsyncValue.data(ExerciseMedia());

          return mediaAsync.when(
            data: (media) => _ExerciseBody(
              exercise: exercise,
              media: media,
              onDeleteCustom: exercise.isUserCustom
                  ? () => _deleteCustom(context, ref, exercise)
                  : null,
            ),
            loading: () => const FitForgeLoadingScreen(),
            error: (_, __) => _ExerciseBody(
              exercise: exercise,
              media: const ExerciseMedia(),
              onDeleteCustom: exercise.isUserCustom
                  ? () => _deleteCustom(context, ref, exercise)
                  : null,
            ),
          );
        },
        loading: () => const FitForgeLoadingScreen(),
        error: (e, _) => Center(child: Text(l10n.errorGeneric(e.toString()))),
      ),
    );
  }
}

class _ExerciseBody extends StatelessWidget {
  final Exercise exercise;
  final ExerciseMedia media;
  final VoidCallback? onDeleteCustom;

  const _ExerciseBody({
    required this.exercise,
    required this.media,
    this.onDeleteCustom,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExerciseThumbnail(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            category: exercise.category,
            muscles: exercise.muscles,
            height: 250,
            fullWidth: true,
            borderRadius: BorderRadius.zero,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text(exercise.category)),
                    if (exercise.isUserCustom)
                      Chip(
                        label: Text(l10n.customExerciseTag),
                        avatar: const Icon(Icons.person, size: 16),
                      )
                    else if (exercise.isCustom)
                      const Chip(label: Text('FitForge'), avatar: Icon(Icons.star, size: 16)),
                    if (exercise.isUserCustom && exercise.perArmWeight)
                      Chip(
                        label: Text(l10n.customExercisePerArmWeight),
                        avatar: const Icon(Icons.fitness_center, size: 16),
                      ),
                    ...exercise.muscles.map((m) => Chip(label: Text(m))),
                  ],
                ),
                if (exercise.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(l10n.instructions, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(exercise.description),
                ],
                if (media.videoUrl != null) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(media.videoUrl!)),
                    icon: const Icon(Icons.play_circle),
                    label: Text(l10n.watchDemoVideo),
                  ),
                ],
                if (onDeleteCustom != null) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: onDeleteCustom,
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    label: Text(l10n.deleteCustomExercise, style: const TextStyle(color: Colors.redAccent)),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  exercise.isUserCustom
                      ? l10n.customExerciseAttribution
                      : CloudExerciseCatalogIds.isCloudId(exercise.id)
                          ? l10n.gymVisualAttribution
                          : exercise.imageUrl != null &&
                                  exercise.imageUrl!.contains('exercisedb.dev')
                              ? l10n.wgerAttribution
                              : exercise.isBundled
                                  ? l10n.fitforgeCatalog
                                  : l10n.wgerAttribution,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
