import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/exercise_picker_merge.dart';
import '../core/utils/muscle_inference.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../models/exercise.dart';
import '../providers/app_providers.dart';
import 'create_custom_exercise_sheet.dart';
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
        builder: (_, __) => WorkoutExercisePickerSheet(excludeExerciseIds: excludeExerciseIds),
      ),
    );
  }

  @override
  ConsumerState<WorkoutExercisePickerSheet> createState() => _WorkoutExercisePickerSheetState();
}

class _WorkoutExercisePickerSheetState extends ConsumerState<WorkoutExercisePickerSheet> {
  String _search = '';
  String? _muscleFilter;
  bool _customOnly = false;

  List<Exercise> _filterExercises(List<Exercise> exercises) {
    return exercises.where((e) {
      if (widget.excludeExerciseIds.contains(e.id)) return false;
      if (_customOnly && !e.isUserCustom) return false;
      if (_search.isNotEmpty && !e.name.toLowerCase().contains(_search)) return false;
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
    final cloudAsync = shouldQueryCloudExerciseCatalog(_search)
        ? ref.watch(cloudExerciseSearchProvider(_search))
        : const AsyncValue.data(<Exercise>[]);

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
                child: Text(
                  l10n.addExercise,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: () => openCreateCustomExerciseSheet(context, ref),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(l10n.createCustomExercise),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: l10n.searchExercise,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        exercisesAsync.when(
          loading: () => const Expanded(child: Center(child: FitForgeLoadingIndicator(size: 48))),
          error: (e, _) => Expanded(child: Center(child: Text(l10n.errorGeneric('$e')))),
          data: (exercises) {
            final merged = mergeBundledAndCloudExercises(
              bundled: exercises,
              cloud: cloudAsync.valueOrNull ?? const [],
            );
            final filtered = _filterExercises(merged);

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
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        FilterChip(
                          label: Text(l10n.all),
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
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(l10n.noResults, style: const TextStyle(color: AppColors.textMuted)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
