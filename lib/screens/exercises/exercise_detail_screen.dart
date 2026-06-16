import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/exercise_service.dart';
import '../../models/exercise.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';

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
            loading: () => _ExerciseBody(exercise: exercise, media: const ExerciseMedia(), loadingMedia: true),
            error: (_, __) => _ExerciseBody(exercise: exercise, media: const ExerciseMedia()),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ExerciseBody extends StatelessWidget {
  final Exercise exercise;
  final ExerciseMedia media;
  final bool loadingMedia;

  const _ExerciseBody({
    required this.exercise,
    required this.media,
    this.loadingMedia = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (media.imageUrl != null)
            Image.network(
              media.imageUrl!,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          else if (loadingMedia)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text('Cargando imagen…', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            )
          else
            _placeholder(),
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

  Widget _placeholder() {
    return Container(
      height: 200,
      color: Colors.white12,
      child: const Icon(Icons.fitness_center, size: 64),
    );
  }
}
