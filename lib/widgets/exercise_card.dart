import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/exercise.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback? onTap;

  const ExerciseCard({super.key, required this.exercise, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: exercise.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: exercise.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.white12,
                          child: const Icon(Icons.fitness_center),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.white12,
                          child: const Icon(Icons.fitness_center),
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: Colors.white12,
                        child: const Icon(Icons.fitness_center),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.category}${exercise.muscles.isNotEmpty ? ' · ${exercise.muscles.first}' : ''}',
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
