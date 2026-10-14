import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size;

import 'package:image/image.dart' as img;

/// Relación de la foto del entreno, igual que la tarjeta del feed.
const workoutFinishPhotoAspectRatio = 4 / 3;

/// Recorte centrado de [frame] con [aspect] (ancho / alto).
Rect centeredAspectRect(Size frame, double aspect) {
  if (frame.width <= 0 || frame.height <= 0 || aspect <= 0) {
    return Offset.zero & frame;
  }
  final frameAspect = frame.width / frame.height;
  if ((frameAspect - aspect).abs() < 0.01) {
    return Offset.zero & frame;
  }
  if (frameAspect > aspect) {
    final width = frame.height * aspect;
    final left = (frame.width - width) / 2;
    return Rect.fromLTWH(left, 0, width, frame.height);
  }
  final height = frame.width / aspect;
  final top = (frame.height - height) / 2;
  return Rect.fromLTWH(0, top, frame.width, height);
}

/// Recorta el JPEG al centro en [workoutFinishPhotoAspectRatio].
///
/// [mirrorHorizontally] replica el espejo de la previsualización frontal.
Uint8List cropJpegToCenterAspect(Uint8List bytes, {bool mirrorHorizontally = false}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  var oriented = img.bakeOrientation(decoded);
  if (mirrorHorizontally) {
    oriented = img.flipHorizontal(oriented);
  }
  final crop = centeredAspectRect(
    Size(oriented.width.toDouble(), oriented.height.toDouble()),
    workoutFinishPhotoAspectRatio,
  );
  final coversFrame = crop.width >= oriented.width - 1 && crop.height >= oriented.height - 1;
  if (coversFrame && !mirrorHorizontally) return bytes;

  final cropped = coversFrame
      ? oriented
      : img.copyCrop(
          oriented,
          x: crop.left.round(),
          y: crop.top.round(),
          width: crop.width.round(),
          height: crop.height.round(),
        );
  return Uint8List.fromList(img.encodeJpg(cropped, quality: 92));
}

/// Argumento de [compute] para recortar y, si hace falta, reflejar la foto.
Uint8List prepareWorkoutFinishPhoto((Uint8List bytes, bool mirrorHorizontally) input) {
  return cropJpegToCenterAspect(input.$1, mirrorHorizontally: input.$2);
}
