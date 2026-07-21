import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captura widgets de tarjeta para compartir como PNG.
abstract final class WorkoutShareCapture {
  static const _maxAttempts = 20;
  static const _frameDelay = Duration(milliseconds: 32);

  static String safeFileName() =>
      'fitforge_share_${DateTime.now().millisecondsSinceEpoch}.png';

  static Future<Uint8List?> capturePng(
    GlobalKey boundaryKey, {
    double pixelRatio = 3,
  }) async {
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      await _waitForFrame();

      final boundary =
          boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize || boundary.size.shortestSide <= 0) {
        if (attempt < _maxAttempts - 1) {
          await Future<void>.delayed(_frameDelay);
        }
        continue;
      }

      try {
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final bytes = data?.buffer.asUint8List();
        if (bytes != null && bytes.isNotEmpty) {
          return bytes;
        }
      } catch (_) {
        // Reintenta tras el siguiente frame (layout/fonts/imágenes pueden tardar).
      }

      if (attempt < _maxAttempts - 1) {
        await Future<void>.delayed(_frameDelay);
      }
    }
    return null;
  }

  static Future<void> _waitForFrame() async {
    final binding = WidgetsBinding.instance;
    await binding.endOfFrame;
    await Future<void>.delayed(_frameDelay);
    await binding.endOfFrame;
  }
}
