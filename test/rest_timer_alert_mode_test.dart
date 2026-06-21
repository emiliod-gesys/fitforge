import 'package:fitforge/models/rest_timer_alert_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromCode defaults to both', () {
    expect(RestTimerAlertMode.fromCode(null), RestTimerAlertMode.both);
    expect(RestTimerAlertMode.fromCode('unknown'), RestTimerAlertMode.both);
  });

  test('fromCode parses stored values', () {
    expect(RestTimerAlertMode.fromCode('sound'), RestTimerAlertMode.sound);
    expect(RestTimerAlertMode.fromCode('vibration'), RestTimerAlertMode.vibration);
    expect(RestTimerAlertMode.fromCode('both'), RestTimerAlertMode.both);
  });
}
