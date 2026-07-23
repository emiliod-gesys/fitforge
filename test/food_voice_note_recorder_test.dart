import 'package:fitforge/services/food_voice_note_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FoodVoiceNoteRecorder max duration is 15 seconds', () {
    expect(FoodVoiceNoteRecorder.maxDuration, const Duration(seconds: 15));
  });
}
