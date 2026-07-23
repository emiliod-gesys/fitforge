import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Resultado de una nota de voz grabada para Quick Add.
class FoodVoiceNoteResult {
  const FoodVoiceNoteResult({
    required this.bytes,
    required this.mimeType,
    required this.fileExtension,
  });

  final List<int> bytes;
  final String mimeType;
  final String fileExtension;
}

/// Graba notas de voz cortas (máx. 15 s) para estimación nutricional con IA.
class FoodVoiceNoteRecorder {
  FoodVoiceNoteRecorder({AudioRecorder? recorder}) : _recorder = recorder ?? AudioRecorder();

  static const maxDuration = Duration(seconds: 15);

  final AudioRecorder _recorder;
  Timer? _tickTimer;
  int _session = 0;
  bool _recording = false;
  bool _stopping = false;

  bool get isRecording => _recording;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start({
    required void Function(Duration elapsed) onTick,
    required Future<void> Function() onMaxDuration,
  }) async {
    if (_recording || _stopping) return;

    final session = ++_session;
    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'food_voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );

    final config = const RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      sampleRate: 44100,
    );

    if (!await _recorder.isEncoderSupported(config.encoder)) {
      throw StateError('Audio encoder not supported');
    }

    await _recorder.start(config, path: path);

    if (session != _session) {
      await _recorder.cancel();
      return;
    }

    _recording = true;
    var elapsed = Duration.zero;
    onTick(elapsed);

    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (session != _session || !_recording) {
        timer.cancel();
        return;
      }

      elapsed += const Duration(seconds: 1);
      onTick(elapsed);

      if (elapsed >= maxDuration) {
        timer.cancel();
        unawaited(onMaxDuration());
      }
    });
  }

  Future<FoodVoiceNoteResult?> stop() async {
    if (_stopping) return null;
    if (!_recording) return null;

    _stopping = true;
    _session++;
    _tickTimer?.cancel();
    _tickTimer = null;

    try {
      final path = await _recorder.stop();
      _recording = false;

      if (path == null || path.isEmpty) return null;

      final file = File(path);
      if (!await file.exists()) return null;

      try {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) return null;
        return FoodVoiceNoteResult(
          bytes: bytes,
          mimeType: 'audio/mp4',
          fileExtension: 'm4a',
        );
      } finally {
        try {
          await file.delete();
        } catch (_) {}
      }
    } finally {
      _stopping = false;
    }
  }

  Future<void> cancel() async {
    _session++;
    _tickTimer?.cancel();
    _tickTimer = null;

    if (_recording || _stopping) {
      _stopping = true;
      try {
        await _recorder.cancel();
      } finally {
        _recording = false;
        _stopping = false;
      }
    }
  }

  Future<void> shutdown() async {
    await cancel();
    await _recorder.dispose();
  }
}
