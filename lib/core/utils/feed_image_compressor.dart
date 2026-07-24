import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Compresión de imágenes para publicaciones del feed (objetivo ≤512 KB en servidor).
abstract final class FeedImageCompressor {
  static const maxUploadBytes = 512 * 1024;
  static const maxDimension = 1280;
  static const initialQuality = 78;

  /// Comprime [source] a JPEG en caché temporal listo para subir.
  static Future<File?> compressForUpload(File source) async {
    if (kIsWeb) return source;

    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      'feed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    var quality = initialQuality;
    File? output;

    for (var attempt = 0; attempt < 4; attempt++) {
      final compressed = await FlutterImageCompress.compressAndGetFile(
        source.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxDimension,
        minHeight: maxDimension,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      if (compressed == null) break;

      output = File(compressed.path);
      if (!await output.exists()) break;

      final bytes = await output.length();
      if (bytes <= maxUploadBytes) return output;

      quality -= 12;
      if (quality < 40) break;
    }

    if (output != null && await output.exists()) {
      final bytes = await output.length();
      if (bytes <= maxUploadBytes * 1.15) return output;
    }

    return null;
  }
}
