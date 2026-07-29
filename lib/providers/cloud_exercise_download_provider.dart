import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/offline/cloud_exercise_download_service.dart';
import '../services/offline/cloud_exercise_media_cache.dart';

class CloudExerciseDownloadState {
  final bool isDownloading;
  final int downloaded;
  final int? total;
  final int cachedCount;
  final int mediaCount;
  final int pendingUpdateCount;
  final DateTime? downloadedAt;
  final String? error;
  final CloudExerciseDownloadPhase phase;
  final bool isUpToDate;

  const CloudExerciseDownloadState({
    this.isDownloading = false,
    this.downloaded = 0,
    this.total,
    this.cachedCount = 0,
    this.mediaCount = 0,
    this.pendingUpdateCount = 0,
    this.downloadedAt,
    this.error,
    this.phase = CloudExerciseDownloadPhase.catalog,
    this.isUpToDate = false,
  });

  CloudExerciseDownloadState copyWith({
    bool? isDownloading,
    int? downloaded,
    int? total,
    int? cachedCount,
    int? mediaCount,
    int? pendingUpdateCount,
    DateTime? downloadedAt,
    String? error,
    CloudExerciseDownloadPhase? phase,
    bool? isUpToDate,
    bool clearError = false,
  }) {
    return CloudExerciseDownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      downloaded: downloaded ?? this.downloaded,
      total: total ?? this.total,
      cachedCount: cachedCount ?? this.cachedCount,
      mediaCount: mediaCount ?? this.mediaCount,
      pendingUpdateCount: pendingUpdateCount ?? this.pendingUpdateCount,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      error: clearError ? null : (error ?? this.error),
      phase: phase ?? this.phase,
      isUpToDate: isUpToDate ?? this.isUpToDate,
    );
  }

  double? get progress {
    final goal = total;
    if (goal == null || goal <= 0) return null;
    return (downloaded / goal).clamp(0.0, 1.0);
  }
}

class CloudExerciseDownloadNotifier extends StateNotifier<CloudExerciseDownloadState> {
  CloudExerciseDownloadNotifier(this.ref) : super(const CloudExerciseDownloadState());

  final Ref ref;

  Future<CloudExerciseDownloadStatus> analyzeStatus() async {
    final service = ref.read(cloudExerciseDownloadServiceProvider);
    final locale = ref.read(preferredLanguageProvider);
    return service.analyzeStatus(locale);
  }

  Future<void> refreshMeta({bool checkRemote = false}) async {
    final store = ref.read(cloudExerciseCacheStoreProvider);
    await store.ensureLoaded();

    var pending = 0;
    var upToDate = false;
    var mediaCount = store.all.where(CloudExerciseMediaCache.hasLocalMedia).length;

    final online = ref.read(isOnlineProvider).valueOrNull ?? false;
    if (checkRemote && online && store.hasData) {
      try {
        final status = await analyzeStatus();
        pending = status.pendingCount;
        upToDate = status.isUpToDate;
        mediaCount = store.all.where(CloudExerciseMediaCache.hasLocalMedia).length;
      } catch (_) {}
    }

    state = state.copyWith(
      cachedCount: store.count,
      mediaCount: mediaCount,
      downloadedAt: store.downloadedAt,
      pendingUpdateCount: pending,
      isUpToDate: upToDate,
      clearError: true,
    );
  }

  Future<CloudExerciseDownloadResult> download() async {
    if (state.isDownloading) {
      throw StateError('download_in_progress');
    }

    state = state.copyWith(
      isDownloading: true,
      downloaded: 0,
      total: null,
      phase: CloudExerciseDownloadPhase.catalog,
      clearError: true,
    );

    try {
      final service = ref.read(cloudExerciseDownloadServiceProvider);
      final locale = ref.read(preferredLanguageProvider);
      final result = await service.downloadUpdates(
        locale: locale,
        onProgress: (downloaded, total, phase) {
          state = state.copyWith(
            downloaded: downloaded,
            total: total,
            phase: phase,
          );
        },
      );

      final store = ref.read(cloudExerciseCacheStoreProvider);
      state = state.copyWith(
        isDownloading: false,
        cachedCount: result.exerciseCount,
        mediaCount: result.mediaCount,
        downloadedAt: store.downloadedAt,
        downloaded: result.newlyDownloadedExercises > 0
            ? result.newlyDownloadedExercises
            : result.newlyDownloadedMedia,
        total: result.newlyDownloadedExercises > 0
            ? result.newlyDownloadedExercises
            : result.newlyDownloadedMedia,
        pendingUpdateCount: 0,
        isUpToDate: true,
        phase: CloudExerciseDownloadPhase.media,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
}

final cloudExerciseDownloadProvider =
    StateNotifierProvider<CloudExerciseDownloadNotifier, CloudExerciseDownloadState>((ref) {
  return CloudExerciseDownloadNotifier(ref);
});
