import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class RestSoundService {
  static const _bellDuration = Duration(seconds: 2);
  static const _bellVolume = 0.5;

  static final _player = AudioPlayer();
  static Timer? _stopTimer;
  static bool _contextConfigured = false;

  static Future<void> _ensureAudioContext() async {
    if (_contextConfigured) return;

    await _player.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );
    _contextConfigured = true;
  }

  /// Campana mezclada con la música del sistema + vibración suave.
  static Future<void> playRestCompleteBell() async {
    await HapticFeedback.lightImpact();

    _contextConfigured = false;
    await _ensureAudioContext();

    _stopTimer?.cancel();
    await _player.stop();
    await _player.setVolume(_bellVolume);
    await _player.play(AssetSource('sounds/boxing-bell.mp3'));
    _stopTimer = Timer(_bellDuration, () {
      _player.stop();
    });
  }

  static Future<void> cancelBell() async {
    _stopTimer?.cancel();
    _stopTimer = null;
    await _player.stop();
  }
}
