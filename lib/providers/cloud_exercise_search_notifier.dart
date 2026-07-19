import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/cloud_exercise_catalog.dart';
import '../core/utils/exercise_picker_merge.dart';
import '../models/exercise.dart';
import 'app_providers.dart';

class CloudExerciseSearchState {
  final List<Exercise> exercises;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const CloudExerciseSearchState({
    this.exercises = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
  });

  CloudExerciseSearchState copyWith({
    List<Exercise>? exercises,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return CloudExerciseSearchState(
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CloudExerciseSearchNotifier extends StateNotifier<CloudExerciseSearchState> {
  CloudExerciseSearchNotifier(this.ref, this.query)
      : super(const CloudExerciseSearchState(isLoading: true)) {
    loadInitial();
  }

  final Ref ref;
  final String query;
  int _offset = 0;

  Future<void> loadInitial() async {
    _offset = 0;
    state = const CloudExerciseSearchState(isLoading: true);
    await _fetchPage(append: false);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    await _fetchPage(append: true);
  }

  Future<void> _fetchPage({required bool append}) async {
    try {
      final lang = ref.read(preferredLanguageProvider);
      final service = ref.read(exerciseServiceProvider);
      service.configure(language: lang);
      final page = cloudExerciseCatalogIsBrowseMode(query)
          ? await service.browseCloudExercises(
              offset: append ? _offset : 0,
              limit: CloudExerciseCatalogIds.pageSize,
            )
          : await service.searchCloudExercises(
              query,
              offset: append ? _offset : 0,
              limit: CloudExerciseCatalogIds.pageSize,
            );
      if (!append) _offset = 0;
      _offset += page.length;
      final merged = append ? dedupeExercisesById([...state.exercises, ...page]) : page;
      state = CloudExerciseSearchState(
        exercises: merged,
        hasMore: page.length >= CloudExerciseCatalogIds.pageSize,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: '$e',
      );
    }
  }
}

final cloudExerciseSearchNotifierProvider = StateNotifierProvider.autoDispose
    .family<CloudExerciseSearchNotifier, CloudExerciseSearchState, String>(
  (ref, query) {
    ref.watch(preferredLanguageProvider);
    return CloudExerciseSearchNotifier(ref, query.trim());
  },
);
