/// Miniaturas de YouTube para usar como imagen de ejercicio cuando wger no tiene foto.
abstract final class YoutubeThumbnail {
  static String? videoIdFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      return id != null && id.isNotEmpty ? id : null;
    }

    if (host.contains('youtube.com') || host.contains('youtube-nocookie.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;

      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        final kind = segments[0];
        if (kind == 'embed' || kind == 'shorts' || kind == 'v') {
          return segments[1];
        }
      }
    }

    return null;
  }

  static String? urlFromVideo(String? videoUrl, {String quality = 'mqdefault'}) {
    final id = videoIdFromUrl(videoUrl);
    if (id == null) return null;
    return 'https://img.youtube.com/vi/$id/$quality.jpg';
  }
}
