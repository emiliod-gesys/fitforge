import 'dart:typed_data';
import 'dart:ui';

import 'package:fitforge/core/utils/center_aspect_crop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('centered 4:3 window crops the top and bottom of a portrait frame', () {
    final hole = centeredAspectRect(const Size(300, 400), workoutFinishPhotoAspectRatio);

    expect(hole.left, 0);
    expect(hole.width, 300);
    expect(hole.height, closeTo(225, 0.01));
    expect(hole.top, closeTo(87.5, 0.01));
  });

  test('jpeg crop keeps the center 4:3 band', () {
    final source = img.Image(width: 300, height: 400);
    final bytes = cropJpegToCenterAspect(Uint8List.fromList(img.encodeJpg(source)));
    final cropped = img.decodeImage(bytes)!;

    expect(cropped.width, 300);
    expect(cropped.height, 225);
  });

  test('front-camera mirror moves a left pixel to the right before cropping', () {
    final source = img.Image(width: 300, height: 400);
    source.setPixelRgb(0, 200, 255, 0, 0);
    final bytes = cropJpegToCenterAspect(
      Uint8List.fromList(img.encodeJpg(source)),
      mirrorHorizontally: true,
    );
    final cropped = img.decodeImage(bytes)!;
    final cropTop = centeredAspectRect(
      const Size(300, 400),
      workoutFinishPhotoAspectRatio,
    ).top.round();

    final moved = cropped.getPixel(299, 200 - cropTop);
    final stayed = cropped.getPixel(0, 200 - cropTop);
    expect(moved.r.toInt(), greaterThan(200));
    expect(stayed.r.toInt(), lessThan(40));
  });
}