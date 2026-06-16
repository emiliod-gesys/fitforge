import 'package:audioplayers/audioplayers.dart';

class RestSoundService {
  static final _player = AudioPlayer();

  static Future<void> playRestCompleteBell() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/boxing-bell.mp3'));
  }
}
