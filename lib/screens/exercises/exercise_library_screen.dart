import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/muscle_inference.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/exercise.dart';
import '../../providers/app_providers.dart';
import '../../widgets/create_custom_exercise_sheet.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String _search = '';
  String? _muscleFilter;
  bool _customOnly = false;

  List<Exercise> _filterExercises(List<Exercise> exercises) {
    return exercises.where((e) {
      if (_customOnly && !e.isUserCustom) return false;
      if (_search.isNotEmpty && !e.name.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      if (_muscleFilter != null &&
          !MuscleInference.matchesMuscleGroup(exercise: e, muscleGroup: _muscleFilter!)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: FitForgeAppBar(title: l10n.exercisesTitle),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchExercises,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => openCreateCustomExerciseSheet(context, ref),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(l10n.createCustomExercise),
                ),
              ],
            ),
          ),
          exercisesAsync.when(
            data: (exercises) {
              final filtered = _filterExercises(exercises);

              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.exerciseCount(filtered.length),
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
                            label: Text(l10n.allCategories),
                            selected: _muscleFilter == null && !_customOnly,
                            onSelected: (_) => setState(() {
                              _muscleFilter = null;
                              _customOnly = false;
                            }),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilterChip(
                              label: Text(l10n.myCustomExercises),
                              selected: _customOnly,
                              onSelected: (selected) => setState(() {
                                _customOnly = selected;
                                if (selected) _muscleFilter = null;
                              }),
                            ),
                          ),
                          ...AppConstants.muscleGroups.map(
                            (muscle) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: FilterChip(
                                label: Text(l10n.muscleLabel(muscle)),
                                selected: _muscleFilter == muscle,
                                onSelected: (selected) => setState(() {
                                  _muscleFilter = selected ? muscle : null;
                                  if (selected) _customOnly = false;
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => ExerciseCard(
                          exercise: filtered[i],
                          onTap: () => context.push('/exercises/${filtered[i].id}'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Expanded(child: FitForgeLoadingScreen()),
            error: (e, _) => Expanded(child: Center(child: Text(l10n.errorGeneric(e.toString())))),
          ),
        ],
      ),
    );
  }
}
