import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import 'exercise_thumbnail.dart';

class ExerciseCard extends ConsumerWidget {
  final Exercise exercise;
  final VoidCallback? onTap;

  const ExerciseCard({super.key, required this.exercise, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
