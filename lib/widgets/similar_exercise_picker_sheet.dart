import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/cloud_exercise_catalog.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/exercise_picker_merge.dart';
import '../core/utils/similar_exercises.dart';
import '../l10n/l10n_extensions.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../providers/app_providers.dart';
import '../providers/cloud_exercise_search_notifier.dart';
import 'cloud_exercise_load_more_footer.dart';
import 'exercise_card.dart';
import 'fitforge_loading_indicator.dart';

class SimilarExercisePickerSheet extends ConsumerWidget {
  final WorkoutExercise current;
  final Set<String> excludeExerciseIds;

  const SimilarExercisePickerSheet({
    super.key,
    required this.current,
    this.excludeExerciseIds = const {},
  });

  static Future<Exercise?> show(
    BuildContext context, {
    required WorkoutExercise current,
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
        builder: (_, __) => SimilarExercisePickerSheet(
          current: current,
          excludeExerciseIds: excludeExerciseIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final exercisesAsync = ref.watch(exercisesProvider);
    final isCloudExercise = CloudExerciseCatalogIds.isCloudId(current.exerciseId);
    final cloudSourceAsync = isCloudExercise
        ? ref.watch(cloudExerciseByIdProvider(current.exerciseId))
        : const AsyncValue<Exercise?>.data(null);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.swapSimilar,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      current.exerciseName,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: exercisesAsync.when(
            loading: () => const Center(child: FitForgeLoadingIndicator(size: 48)),
            error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
            data: (catalog) {
              if (isCloudExercise && cloudSourceAsync.isLoading) {
                return const Center(child: FitForgeLoadingIndicator(size: 48));
              }

              final bundledSource = SimilarExercises.findInCatalog(catalog, current.exerciseId);
              final source = bundledSource ?? cloudSourceAsync.valueOrNull;
              final primaryGroup = SimilarExercises.resolvePrimaryGroup(
                exerciseName: current.exerciseName,
                exerciseId: current.exerciseId,
                catalogMatch: source,
              );

              if (primaryGroup == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.noSimilarFound,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                );
              }

              return _SimilarExerciseResults(
                catalog: catalog,
                current: current,
                excludeExerciseIds: excludeExerciseIds,
                primaryGroup: primaryGroup,
                sourceExercise: source,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SimilarExerciseResults extends ConsumerStatefulWidget {
  final List<Exercise> catalog;
  final WorkoutExercise current;
  final Set<String> excludeExerciseIds;
  final String primaryGroup;
  final Exercise? sourceExercise;

  const _SimilarExerciseResults({
    required this.catalog,
    required this.current,
    required this.excludeExerciseIds,
    required this.primaryGroup,
    required this.sourceExercise,
  });

  @override
  ConsumerState<_SimilarExerciseResults> createState() => _SimilarExerciseResultsState();
}

class _SimilarExerciseResultsState extends ConsumerState<_SimilarExerciseResults> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sourceCategory = widget.sourceExercise?.category ?? '';
    final hasSearch = _search.trim().isNotEmpty;

    final String cloudKey;
    if (hasSearch) {
      cloudKey = cloudExerciseCatalogNotifierKey(
            search: _search,
            muscleFilter: widget.primaryGroup,
          ) ??
          SimilarExercises.cloudSearchQueryForPrimaryGroup(widget.primaryGroup);
    } else {
      cloudKey = SimilarExercises.cloudSearchQueryForPrimaryGroup(widget.primaryGroup);
    }

    final cloudState = ref.watch(cloudExerciseSearchNotifierProvider(cloudKey));

    final List<Exercise> similar;
    if (hasSearch) {
      final bundledMatches = SimilarExercises.searchInPrimaryGroup(
        catalog: widget.catalog,
        primaryGroup: widget.primaryGroup,
        search: _search,
        exerciseId: widget.current.exerciseId,
        excludeIds: widget.excludeExerciseIds,
      );
      final cloudMatches = SimilarExercises.filterCloudCandidates(
        cloud: cloudState.exercises,
        primaryGroup: widget.primaryGroup,
        exerciseId: widget.current.exerciseId,
        excludeIds: widget.excludeExerciseIds,
        sourceCategory: sourceCategory,
      ).where((e) => exerciseMatchesTextFilter(e, _search)).toList();
      similar = mergeBundledAndCloudExercises(
        bundled: bundledMatches,
        cloud: cloudMatches,
      );
      similar.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      final bundledSimilar = SimilarExercises.find(
        exerciseName: widget.current.exerciseName,
        exerciseId: widget.current.exerciseId,
        catalog: widget.catalog,
        excludeIds: widget.excludeExerciseIds,
        primaryGroup: widget.primaryGroup,
        sourceExercise: widget.sourceExercise,
      );
      final cloudSimilar = SimilarExercises.filterCloudCandidates(
        cloud: cloudState.exercises,
        primaryGroup: widget.primaryGroup,
        exerciseId: widget.current.exerciseId,
        excludeIds: widget.excludeExerciseIds,
        sourceCategory: sourceCategory,
      );
      similar = mergeBundledAndCloudExercises(
        bundled: bundledSimilar,
        cloud: cloudSimilar,
      );
      SimilarExercises.sortByRelevance(similar, sourceCategory: sourceCategory);
    }

    if (similar.isEmpty && !cloudState.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.noSimilarFound,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final showLoadMore = cloudState.hasMore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchField(),
        CloudExerciseSearchStatus(
          isLoading: cloudState.isLoading,
          error: cloudState.error,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.exerciseCount(similar.length),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: similar.length + (showLoadMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (showLoadMore && i == similar.length) {
                return CloudExerciseLoadMoreFooter(
                  isLoadingMore: cloudState.isLoadingMore,
                  onLoadMore: () => ref
                      .read(cloudExerciseSearchNotifierProvider(cloudKey).notifier)
                      .loadMore(),
                );
              }
              final exercise = similar[i];
              return ExerciseCard(
                exercise: exercise,
                onTap: () => Navigator.pop(context, exercise),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
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
        onChanged: (value) => setState(() => _search = value),
      ),
    );
  }
}
