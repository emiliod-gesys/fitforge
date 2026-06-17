import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/exercise_service.dart';
import '../../models/exercise.dart';
import '../../providers/app_providers.dart';
import '../../widgets/exercise_thumbnail.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final String exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: const FitForgeAppBar(title: 'Ejercicio'),
      body: exercisesAsync.when(
        data: (exercises) {
          final exercise = exercises.cast<Exercise?>().firstWhere(
                (e) => e?.id == exerciseId,
                orElse: () => null,
              );

          if (exercise == null) {
            return const Center(child: Text('Ejercicio no encontrado'));
          }

          final wgerId = exercise.wgerId;
          final mediaAsync = (wgerId != null && wgerId > 0)
              ? ref.watch(exerciseMediaProvider(wgerId))
              : const AsyncValue.data(ExerciseMedia());

          return mediaAsync.when(
            data: (media) => _ExerciseBody(exercise: exercise, media: media),
            loading: () => const FitForgeLoadingScreen(),
            error: (_, __) => _ExerciseBody(exercise: exercise, media: const ExerciseMedia()),
          );
        },
        loading: () => const FitForgeLoadingScreen(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ExerciseBody extends StatelessWidget {
  final Exercise exercise;
  final ExerciseMedia media;

  const _ExerciseBody({
    required this.exercise,
    required this.media,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExerciseThumbnail(
            imageUrl: exercise.imageUrl,
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
                    if (exercise.isCustom)
                      const Chip(label: Text('FitForge'), avatar: Icon(Icons.star, size: 16)),
                    ...exercise.muscles.map((m) => Chip(label: Text(m))),
                  ],
                ),
                if (exercise.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Instrucciones', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(exercise.description),
                ],
                if (media.videoUrl != null) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(media.videoUrl!)),
                    icon: const Icon(Icons.play_circle),
                    label: const Text('Ver video demostrativo'),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  exercise.isCustom
                      ? 'Ejercicio del catálogo FitForge'
                      : 'Imágenes y videos de wger.de (CC-BY-SA)',
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
