import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../models/rest_timer_alert_mode.dart';
import 'rest_preferences.dart';

class RestSoundService {
  static const _bellDuration = Duration(seconds: 2);
  static const _bellVolume = 0.85;
  static const _vibrationDuration = Duration(milliseconds: 1500);

  static final _player = AudioPlayer();
  static Timer? _stopTimer;
  static bool _contextConfigured = false;
  static int _configuredVersion = 0;
  static const _audioContextVersion = 2;

  /// Precarga el contexto de audio al arrancar la app (menos latencia en el primer descanso).
  static Future<void> warmUp() => _ensureAudioContext();

  static Future<void> _ensureAudioContext() async {
    if (_contextConfigured && _configuredVersion == _audioContextVersion) return;

    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setPlayerMode(PlayerMode.mediaPlayer);
    await _player.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: const AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
    _configuredVersion = _audioContextVersion;
    _contextConfigured = true;
  }

  static Future<void> playRestCompleteAlert([RestTimerAlertMode? mode]) async {
    final alertMode = mode ?? await RestPreferences.getRestTimerAlertMode();

    switch (alertMode) {
      case RestTimerAlertMode.sound:
        await _playBell();
      case RestTimerAlertMode.vibration:
        await _playStrongVibration();
      case RestTimerAlertMode.both:
        await Future.wait([
          _playBell(),
          _playStrongVibration(),
        ]);
    }
  }

  static Future<void> _playBell() async {
    try {
      await _ensureAudioContext();

      _stopTimer?.cancel();
      await _player.stop();
      await _player.setVolume(_bellVolume);
      await _player.play(AssetSource('sounds/boxing-bell.mp3'));
      _stopTimer = Timer(_bellDuration, () {
        unawaited(_player.stop());
      });
    } catch (e, st) {
      debugPrint('RestSoundService: fallo al reproducir campana — $e\n$st');
      await HapticFeedback.heavyImpact();
    }
  }

  static Future<void> _playStrongVibration() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      final hasAmplitude = await Vibration.hasAmplitudeControl();
      if (hasAmplitude == true) {
        await Vibration.vibrate(
          duration: _vibrationDuration.inMilliseconds,
          amplitude: 255,
        );
        return;
      }
      await Vibration.vibrate(duration: _vibrationDuration.inMilliseconds);
      return;
    }

    const pulseCount = 5;
    const step = Duration(milliseconds: 300);
    for (var i = 0; i < pulseCount; i++) {
      await HapticFeedback.heavyImpact();
      if (i < pulseCount - 1) {
        await Future.delayed(step);
      }
    }
  }

  static Future<void> cancelBell() async {
    _stopTimer?.cancel();
    _stopTimer = null;
    await _player.stop();
    await Vibration.cancel();
  }
}
