import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class RestSoundService {
  static const _bellDuration = Duration(seconds: 2);

  static final _player = AudioPlayer();
  static Timer? _stopTimer;

  static Future<void> playRestCompleteBell() async {
    _stopTimer?.cancel();
    await _player.stop();
    await _player.play(AssetSource('sounds/boxing-bell.mp3'));
    _stopTimer = Timer(_bellDuration, () {
      _player.stop();
    });
  }
}
