import 'package:fitforge/core/utils/workout_share_capture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('safeFileName uses ascii png extension', () {
    final name = WorkoutShareCapture.safeFileName();
    expect(name.endsWith('.png'), isTrue);
    expect(name.contains(' '), isFalse);
    expect(name.startsWith('fitforge_share_'), isTrue);
  });
}
