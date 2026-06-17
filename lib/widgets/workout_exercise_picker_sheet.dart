import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/exercise.dart';
import '../providers/app_providers.dart';
import 'exercise_card.dart';
import 'fitforge_loading_indicator.dart';

class WorkoutExercisePickerSheet extends ConsumerStatefulWidget {
  final Set<String> excludeExerciseIds;

  const WorkoutExercisePickerSheet({super.key, this.excludeExerciseIds = const {}});

  static Future<Exercise?> show(
    BuildContext context, {
    Set<String> excludeExerciseIds = const {},
  }) {
    return showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.85,
        child: WorkoutExercisePickerSheet(excludeExerciseIds: excludeExerciseIds),
      ),
    );
  }

  @override
  ConsumerState<WorkoutExercisePickerSheet> createState() => _WorkoutExercisePickerSheetState();
}

class _WorkoutExercisePickerSheetState extends ConsumerState<WorkoutExercisePickerSheet> {
  String _search = '';
  String? _muscleFilter;

  bool _matchesMuscleFilter(Exercise exercise, String muscle) {
    if (exercise.category == muscle) return true;

    final group = muscle.toLowerCase();
    return exercise.muscles.any((m) {
      final value = m.toLowerCase();
      return value.contains(group) || group.contains(value);
    });
  }

  List<Exercise> _filterExercises(List<Exercise> exercises) {
    return exercises.where((e) {
      if (widget.excludeExerciseIds.contains(e.id)) return false;
      if (_search.isNotEmpty && !e.name.toLowerCase().contains(_search)) return false;
      if (_muscleFilter != null && !_matchesMuscleFilter(e, _muscleFilter!)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
              const Expanded(
                child: Text(
                  'Añadir ejercicio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar ejercicio…',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
          ),
        ),
        const SizedBox(height: 8),
        exercisesAsync.when(
          loading: () => const Expanded(child: Center(child: FitForgeLoadingIndicator(size: 48))),
          error: (e, _) => Expanded(child: Center(child: Text('Error: $e'))),
          data: (exercises) {
            final filtered = _filterExercises(exercises);

            return Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${filtered.length} ejercicios',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        FilterChip(
                          label: const Text('Todos'),
                          selected: _muscleFilter == null,
                          onSelected: (_) => setState(() => _muscleFilter = null),
                        ),
                        ...AppConstants.muscleGroups.map(
                          (muscle) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilterChip(
                              label: Text(muscle),
                              selected: _muscleFilter == muscle,
                              onSelected: (_) => setState(() => _muscleFilter = muscle),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text('Sin resultados', style: TextStyle(color: AppColors.textMuted)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final exercise = filtered[i];
                              return ExerciseCard(
                                exercise: exercise,
                                onTap: () => Navigator.pop(context, exercise),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
