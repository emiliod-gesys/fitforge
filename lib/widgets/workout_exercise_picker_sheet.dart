import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/exercise_picker_merge.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../models/exercise.dart';
import '../providers/app_providers.dart';
import '../providers/cloud_exercise_search_notifier.dart';
import 'cloud_exercise_load_more_footer.dart';
import 'create_custom_exercise_sheet.dart';
import 'exercise_card.dart';
import 'localized_exercise_name.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final exercisesAsync = ref.watch(exercisesProvider);
    final cloudKey = cloudExerciseCatalogNotifierKey(
      search: _search,
      muscleFilter: _muscleFilter,
      cloudDisabled: _customOnly,
    );
    final cloudState = cloudKey != null
        ? ref.watch(cloudExerciseSearchNotifierProvider(cloudKey))
        : const CloudExerciseSearchState();
    final showCloudLoadMore = cloudKey != null && cloudState.hasMore && !_customOnly;

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
                  hintText: l10n.searchExercises,
                  prefixIcon: const Icon(Icons.search),
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
            ],
          ),
        ),
        const SizedBox(height: 8),
        exercisesAsync.when(
          loading: () => const Expanded(child: Center(child: FitForgeLoadingIndicator(size: 48))),
          error: (e, _) => Expanded(child: Center(child: Text(l10n.errorGeneric('$e')))),
          data: (exercises) {
            final filteredBundled = filterBundledPickerExercises(
              exercises: exercises,
              search: _search,
              muscleFilter: _muscleFilter,
              customOnly: _customOnly,
              excludeExerciseIds: widget.excludeExerciseIds,
            );
            final filteredCloud = filterCloudPickerExercises(
              exercises: cloudState.exercises,
              muscleFilter: _muscleFilter,
              customOnly: _customOnly,
              excludeExerciseIds: widget.excludeExerciseIds,
            );
            final filtered = mergeBundledAndCloudExercises(
              bundled: filteredBundled,
              cloud: filteredCloud,
            );

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
                            itemCount: filtered.length + (showCloudLoadMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (showCloudLoadMore && i == filtered.length) {
                                return CloudExerciseLoadMoreFooter(
                                  isLoadingMore: cloudState.isLoadingMore,
                                  onLoadMore: cloudKey == null
                                      ? null
                                      : () => ref
                                          .read(cloudExerciseSearchNotifierProvider(cloudKey).notifier)
                                          .loadMore(),
                                );
                              }
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
