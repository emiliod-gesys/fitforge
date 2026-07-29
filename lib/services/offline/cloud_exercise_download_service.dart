import '../../data/cloud_exercise_catalog.dart';
import '../../models/exercise.dart';
import '../supabase_service.dart';
import 'cloud_exercise_cache_store.dart';
import 'cloud_exercise_media_cache.dart';

enum CloudExerciseDownloadPhase { catalog, media }

typedef CloudExerciseDownloadProgress = void Function(
  int downloaded,
  int? total,
  CloudExerciseDownloadPhase phase,
);

class CloudExerciseDownloadStatus {
  final int localCount;
  final int remoteCount;
  final int missingExerciseCount;
  final int missingMediaCount;
  final int localMediaCount;

  const CloudExerciseDownloadStatus({
    required this.localCount,
    required this.remoteCount,
    required this.missingExerciseCount,
    required this.missingMediaCount,
    required this.localMediaCount,
  });

  bool get hasLocalCache => localCount > 0;
  bool get isUpToDate => missingExerciseCount == 0 && missingMediaCount == 0;
  int get pendingCount => missingExerciseCount + missingMediaCount;
}

class CloudExerciseDownloadResult {
  final int exerciseCount;
  final int mediaCount;
  final int newlyDownloadedExercises;
  final int newlyDownloadedMedia;

  const CloudExerciseDownloadResult({
    required this.exerciseCount,
    required this.mediaCount,
    this.newlyDownloadedExercises = 0,
    this.newlyDownloadedMedia = 0,
  });
}

/// Descarga incremental del catálogo cloud y sus GIFs/imágenes.
class CloudExerciseDownloadService {
  CloudExerciseDownloadService({
    required CloudExerciseCatalog cloudCatalog,
    required CloudExerciseCacheStore cacheStore,
    required CloudExerciseMediaCache mediaCache,
  })  : _cloudCatalog = cloudCatalog,
        _cacheStore = cacheStore,
        _mediaCache = mediaCache;

  final CloudExerciseCatalog _cloudCatalog;
  final CloudExerciseCacheStore _cacheStore;
  final CloudExerciseMediaCache _mediaCache;

  Future<List<String>> fetchRemoteCatalogIds() async {
    final ids = <String>[];
    var offset = 0;
    const pageSize = 500;

    while (true) {
      final rows = await SupabaseService.client
          .from('catalog_exercises')
          .select('id')
          .order('id')
          .range(offset, offset + pageSize - 1);

      final page = (rows as List)
          .map((row) => (row as Map)['id'] as String)
          .toList();
      if (page.isEmpty) break;

      ids.addAll(page);
      if (page.length < pageSize) break;
      offset += page.length;
    }

    return ids;
  }

  Future<CloudExerciseDownloadStatus> analyzeStatus(String locale) async {
    await _cacheStore.ensureLoaded();
    final localById = {for (final e in _cacheStore.all) e.id: e};
    final remoteIds = await fetchRemoteCatalogIds();

    final missingExerciseCount =
        remoteIds.where((id) => !localById.containsKey(id)).length;
    final missingMediaCount =
        localById.values.where(CloudExerciseMediaCache.needsMediaDownload).length;
    final localMediaCount =
        localById.values.where(CloudExerciseMediaCache.hasLocalMedia).length;

    return CloudExerciseDownloadStatus(
      localCount: localById.length,
      remoteCount: remoteIds.length,
      missingExerciseCount: missingExerciseCount,
      missingMediaCount: missingMediaCount,
      localMediaCount: localMediaCount,
    );
  }

  Future<CloudExerciseDownloadResult> downloadUpdates({
    required String locale,
    required CloudExerciseDownloadProgress onProgress,
  }) async {
    await _cacheStore.ensureLoaded();
    final status = await analyzeStatus(locale);
    final localById = {for (final e in _cacheStore.all) e.id: e};

    final mediaBefore = localById.values.where(CloudExerciseMediaCache.hasLocalMedia).length;

    if (status.isUpToDate) {
      return CloudExerciseDownloadResult(
        exerciseCount: status.localCount,
        mediaCount: mediaBefore,
      );
    }

    final remoteIds = await fetchRemoteCatalogIds();
    final missingIds = remoteIds.where((id) => !localById.containsKey(id)).toList();

    final fetchedNew = missingIds.isEmpty
        ? <Exercise>[]
        : await _fetchNewExercises(
            missingIds: missingIds,
            locale: locale,
            onProgress: onProgress,
          );

    for (final exercise in fetchedNew) {
      localById[exercise.id] = exercise;
    }

    final needsMedia = <Exercise>[
      ...fetchedNew,
      ...localById.values.where(CloudExerciseMediaCache.needsMediaDownload),
    ];
    final uniqueNeedsMedia = {
      for (final exercise in needsMedia) exercise.id: exercise,
    }.values.toList();

    if (uniqueNeedsMedia.isNotEmpty) {
      final withMedia = await _mediaCache.cacheMediaForAll(
        uniqueNeedsMedia,
        onProgress: (done, total) {
          onProgress(done, total, CloudExerciseDownloadPhase.media);
        },
      );
      for (final exercise in withMedia) {
        localById[exercise.id] = exercise;
      }
    } else {
      onProgress(0, 0, CloudExerciseDownloadPhase.media);
    }

    final merged = localById.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    await _cacheStore.saveAll(merged, locale);
    _cloudCatalog.seedCache(merged);

    final mediaCount = merged.where(CloudExerciseMediaCache.hasLocalMedia).length;

    return CloudExerciseDownloadResult(
      exerciseCount: merged.length,
      mediaCount: mediaCount,
      newlyDownloadedExercises: fetchedNew.length,
      newlyDownloadedMedia: mediaCount - mediaBefore,
    );
  }

  Future<List<Exercise>> _fetchNewExercises({
    required List<String> missingIds,
    required String locale,
    required CloudExerciseDownloadProgress onProgress,
  }) async {
    final fetched = await _cloudCatalog.fetchByIdsRemote(ids: missingIds, locale: locale);
    var downloaded = 0;
    for (final _ in fetched) {
      downloaded++;
      onProgress(downloaded, missingIds.length, CloudExerciseDownloadPhase.catalog);
    }
    return fetched;
  }
}
