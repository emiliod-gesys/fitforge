import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../core/utils/connection_error.dart';
import '../../models/exercise.dart';
import 'offline_json_file.dart';

/// Descarga y guarda GIFs/imágenes del catálogo cloud para uso offline.
class CloudExerciseMediaCache {
  static const _mediaDirName = 'cloud_exercise_media';
  static const _concurrency = 6;
  static const _downloadTimeout = Duration(seconds: 45);

  Future<Directory> _mediaDirectory() async {
    final root = await OfflineJsonFile.root();
    final dir = Directory(p.join(root.path, _mediaDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static bool isRemoteUrl(String? url) =>
      url != null && (url.startsWith('http://') || url.startsWith('https://'));

  static bool hasLocalMedia(Exercise exercise) {
    bool isLocal(String? url) =>
        url != null &&
        url.isNotEmpty &&
        !url.startsWith('http://') &&
        !url.startsWith('https://');
    return isLocal(exercise.videoUrl) || isLocal(exercise.imageUrl);
  }

  static bool needsMediaDownload(Exercise exercise) {
    if (hasLocalMedia(exercise)) return false;
    return isRemoteUrl(exercise.videoUrl) || isRemoteUrl(exercise.imageUrl);
  }

  Future<List<Exercise>> cacheMediaForAll(
    List<Exercise> exercises, {
    required void Function(int downloaded, int total) onProgress,
  }) async {
    if (exercises.isEmpty) return exercises;

    final updated = List<Exercise>.from(exercises);
    var done = 0;

    for (var start = 0; start < exercises.length; start += _concurrency) {
      final end = (start + _concurrency).clamp(0, exercises.length);
      final chunk = exercises.sublist(start, end);
      final results = await Future.wait(chunk.map(_cacheMediaForExercise));
      for (var i = 0; i < results.length; i++) {
        updated[start + i] = results[i];
      }
      done += chunk.length;
      onProgress(done, exercises.length);
    }

    return updated;
  }

  Future<Exercise> _cacheMediaForExercise(Exercise exercise) async {
    final id = exercise.catalogId ?? exercise.id;
    if (id.isEmpty) return exercise;

    final dir = await _mediaDirectory();
    final safeId = _safeFileName(id);

    String? localGif;
    String? localImage;

    final gifUrl = exercise.videoUrl;
    if (isRemoteUrl(gifUrl)) {
      final ext = _extensionFromUrl(gifUrl!, fallback: '.gif');
      localGif = await _downloadToFile(
        url: gifUrl,
        destination: File(p.join(dir.path, '$safeId$ext')),
      );
    }

    final imageUrl = exercise.imageUrl;
    if (isRemoteUrl(imageUrl)) {
      final ext = _extensionFromUrl(imageUrl!, fallback: '.jpg');
      final imageDest = File(p.join(dir.path, '${safeId}_thumb$ext'));
      localImage = await _downloadToFile(url: imageUrl, destination: imageDest);
    }

    if (localGif == null && localImage == null) return exercise;

    return Exercise(
      catalogId: exercise.catalogId,
      supabaseId: exercise.supabaseId,
      name: exercise.name,
      description: exercise.description,
      category: exercise.category,
      muscles: exercise.muscles,
      equipment: exercise.equipment,
      imageUrl: localImage ?? localGif ?? exercise.imageUrl,
      videoUrl: localGif ?? exercise.videoUrl,
      perArmWeight: exercise.perArmWeight,
      unilateral: exercise.unilateral,
      weightOptional: exercise.weightOptional,
      loggingType: exercise.loggingType,
      loadMode: exercise.loadMode,
      isBundled: exercise.isBundled,
    );
  }

  Future<String?> _downloadToFile({
    required String url,
    required File destination,
  }) async {
    try {
      if (await destination.exists()) {
        final length = await destination.length();
        if (length > 0) return destination.path;
      }

      final response = await http.get(Uri.parse(url)).timeout(_downloadTimeout);
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;

      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(response.bodyBytes, flush: true);
      return destination.path;
    } catch (e) {
      if (isConnectionError(e)) rethrow;
      return null;
    }
  }

  bool _isRemoteUrl(String? url) => CloudExerciseMediaCache.isRemoteUrl(url);

  String _safeFileName(String id) => id.replaceAll(RegExp(r'[^\w.-]'), '_');

  String _extensionFromUrl(String url, {required String fallback}) {
    final path = Uri.parse(url).path.toLowerCase();
    final dot = path.lastIndexOf('.');
    if (dot >= 0 && dot < path.length - 1) {
      final ext = path.substring(dot);
      if (ext.length <= 5 && RegExp(r'^\.[a-z0-9]+$').hasMatch(ext)) {
        return ext;
      }
    }
    return fallback;
  }
}
