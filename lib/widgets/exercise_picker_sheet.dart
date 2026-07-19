import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/exercise_picker_merge.dart';
import '../core/utils/muscle_inference.dart';
import '../l10n/l10n_extensions.dart';
import '../models/exercise.dart';
import '../providers/app_providers.dart';
import '../providers/cloud_exercise_search_notifier.dart';
import 'cloud_exercise_load_more_footer.dart';
import 'create_custom_exercise_sheet.dart';
import 'exercise_thumbnail.dart';
import 'localized_exercise_name.dart';
import '../core/theme/app_accent.dart';

enum ExercisePickerFilter { all, inRoutine, custom }

class ExercisePickerSheet extends ConsumerStatefulWidget {
  final List<Exercise> exercises;
  final Set<String> selectedExerciseIds;

  const ExercisePickerSheet({
    super.key,
    required this.exercises,
    required this.selectedExerciseIds,
  });

  @override
  ConsumerState<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  final _searchController = TextEditingController();
  String _search = '';
  String? _muscleFilter;
  ExercisePickerFilter _filter = ExercisePickerFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Exercise> _filteredFrom(List<Exercise> bundled, List<Exercise> cloud) {
    final filteredBundled = filterBundledPickerExercises(
      exercises: bundled,
      search: _search,
      muscleFilter: _muscleFilter,
      customOnly: _filter == ExercisePickerFilter.custom,
      inRoutineOnly: _filter == ExercisePickerFilter.inRoutine,
      selectedExerciseIds: widget.selectedExerciseIds,
    );
    final filteredCloud = filterCloudPickerExercises(
      exercises: cloud,
      muscleFilter: _muscleFilter,
      customOnly: _filter == ExercisePickerFilter.custom,
      inRoutineOnly: _filter == ExercisePickerFilter.inRoutine,
      selectedExerciseIds: widget.selectedExerciseIds,
    );
    return mergeBundledAndCloudExercises(bundled: filteredBundled, cloud: filteredCloud);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final exercises = ref.watch(exercisesProvider).valueOrNull ?? widget.exercises;
    final cloudDisabled = _filter == ExercisePickerFilter.custom ||
        _filter == ExercisePickerFilter.inRoutine;
    final cloudKey = cloudExerciseCatalogNotifierKey(
      search: _search,
      muscleFilter: _muscleFilter,
      cloudDisabled: cloudDisabled,
    );
    final cloudState = cloudKey != null
        ? ref.watch(cloudExerciseSearchNotifierProvider(cloudKey))
        : const CloudExerciseSearchState();
    final filtered = _filteredFrom(exercises, cloudState.exercises);
    final showCloudLoadMore =
        cloudKey != null && cloudState.hasMore && !cloudDisabled;
    final inRoutineCount = widget.selectedExerciseIds.length;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.addExercise, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => openCreateCustomExerciseSheet(context, ref),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(l10n.createCustomExercise),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchExercises,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              if (cloudKey == null) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.cloudCatalogSearchHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
              CloudExerciseSearchStatus(
                isLoading: cloudState.isLoading,
                error: cloudState.error,
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.all),
                      selected: _filter == ExercisePickerFilter.all,
                      onSelected: (selected) => setState(
                        () => _filter = selected ? ExercisePickerFilter.all : ExercisePickerFilter.all,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.inRoutine(inRoutineCount)),
                      selected: _filter == ExercisePickerFilter.inRoutine,
                      onSelected: (selected) => setState(
                        () => _filter = selected
                            ? ExercisePickerFilter.inRoutine
                            : ExercisePickerFilter.all,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.myCustomExercises),
                      selected: _filter == ExercisePickerFilter.custom,
                      onSelected: (selected) => setState(
                        () => _filter = selected
                            ? ExercisePickerFilter.custom
                            : ExercisePickerFilter.all,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.allGroups),
                      selected: _muscleFilter == null,
                      onSelected: (_) => setState(() => _muscleFilter = null),
                    ),
                    ...AppConstants.muscleGroups.map(
                      (muscle) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(l10n.muscleLabel(muscle)),
                          selected: _muscleFilter == muscle,
                          onSelected: (selected) => setState(
                            () => _muscleFilter = selected ? muscle : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.exerciseCount(filtered.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _filter == ExercisePickerFilter.inRoutine
                          ? l10n.noSearchInRoutine
                          : l10n.noExercisesFound,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length + (showCloudLoadMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (showCloudLoadMore && i == filtered.length) {
                      return CloudExerciseLoadMoreFooter(
                        isLoadingMore: cloudState.isLoadingMore,
                        onLoadMore: () => ref
                            .read(cloudExerciseSearchNotifierProvider(cloudKey).notifier)
                            .loadMore(),
                      );
                    }
                    final ex = filtered[i];
                    final inRoutine = widget.selectedExerciseIds.contains(ex.id);
                    return ListTile(
                      leading: ExerciseThumbnail(
                        exerciseId: ex.id,
                        exerciseName: ex.name,
                        category: ex.category,
                        muscles: ex.muscles,
                        width: 48,
                        height: 48,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: LocalizedExerciseName(
                              ex.name,
                              exerciseId: ex.id,
                            ),
                          ),
                          if (ex.isUserCustom)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Chip(
                                label: Text(l10n.customExerciseTag, style: const TextStyle(fontSize: 10)),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        () {
                          final primaryGroup = MuscleInference.primaryRecoveryGroup(
                            category: ex.category,
                            muscles: ex.muscles,
                          );
                          final parts = <String>[
                            if (primaryGroup != null)
                              l10n.muscleLabel(primaryGroup)
                            else
                              l10n.exerciseCategoryLabel(ex.category),
                            if (ex.muscles.isNotEmpty) l10n.muscleLabel(ex.muscles.first),
                          ];
                          if (parts.length == 2 && parts[0] == parts[1]) {
                            return parts[0];
                          }
                          return parts.join(' · ');
                        }(),
                      ),
                      trailing: inRoutine
                          ? Icon(Icons.check_circle, color: context.accentColor)
                          : const Icon(Icons.add_circle_outline),
                      onTap: () => Navigator.pop(context, ex),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
