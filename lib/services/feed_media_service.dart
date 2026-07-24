import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/feed_image_compressor.dart';

/// Subida de imágenes del feed a Supabase Storage (`feed-media`).
class FeedMediaService {
  FeedMediaService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _bucket = 'feed-media';
  static const _signedUrlTtl = Duration(hours: 24);

  String? get _userId => _client.auth.currentUser?.id;

  Future<String> uploadFeedImage(File file) async {
    final uid = _userId;
    if (uid == null) throw StateError('not_authenticated');

    final compressed = await FeedImageCompressor.compressForUpload(file);
    if (compressed == null) throw StateError('image_too_large');

    final objectPath = '$uid/${const Uuid().v4()}.jpg';
    final bytes = await compressed.readAsBytes();

    await _client.storage.from(_bucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    return objectPath;
  }

  Future<String?> signedUrlForPath(String? objectPath) async {
    if (objectPath == null || objectPath.trim().isEmpty) return null;

    return _client.storage.from(_bucket).createSignedUrl(
          objectPath,
          _signedUrlTtl.inSeconds,
        );
  }

  Future<Map<String, String>> signedUrlsForPaths(Iterable<String> paths) async {
    final unique = paths.where((p) => p.trim().isNotEmpty).toSet();
    if (unique.isEmpty) return {};

    final result = <String, String>{};
    for (final path in unique) {
      try {
        final url = await signedUrlForPath(path);
        if (url != null) result[path] = url;
      } catch (_) {
        // Ignorar objetos expirados o eliminados.
      }
    }
    return result;
  }
}
