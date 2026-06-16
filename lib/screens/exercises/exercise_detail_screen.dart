import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/exercise.dart';
import '../../providers/app_providers.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final String exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del ejercicio')),
      body: exercisesAsync.when(
        data: (exercises) {
          final exercise = exercises.cast<Exercise?>().firstWhere(
                (e) => e?.id == exerciseId,
                orElse: () => null,
              );

          if (exercise == null) {
            return const Center(child: Text('Ejercicio no encontrado'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (exercise.imageUrl != null)
                  Image.network(
                    exercise.imageUrl!,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.white12,
                      child: const Icon(Icons.fitness_center, size: 64),
                    ),
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
                          ...exercise.muscles.map((m) => Chip(label: Text(m))),
                        ],
                      ),
                      if (exercise.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Instrucciones', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(exercise.description),
                      ],
                      if (exercise.videoUrl != null) ...[
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => launchUrl(Uri.parse(exercise.videoUrl!)),
                          icon: const Icon(Icons.play_circle),
                          label: const Text('Ver video demostrativo'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Imágenes y videos de wger.de (CC-BY-SA)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
