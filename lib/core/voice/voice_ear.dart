import 'dart:math' as math;
import 'dart:typed_data';

/// Mantiene el micrófono en una sola toma y, cada poco, entrega el audio nuevo
/// si alguien habló. El tramo anterior se conserva para no cortar la frase.
class VoiceEar {
  VoiceEar({
    this.sampleRate = 16000,
    this.hop = const Duration(seconds: 2),
    this.overlap = const Duration(milliseconds: 1000),
  });

  final int sampleRate;
  final Duration hop;
  final Duration overlap;

  final List<int> _pcm = [];
  int _loudMs = 0;
  int _newSamples = 0;
  bool _take = false;
  bool _takeSpeaking = false;
  int _takeSpeechMs = 0;
  int _takeSilenceMs = 0;
  int _takeElapsedMs = 0;
  DateTime _ignoreUntil = DateTime.fromMillisecondsSinceEpoch(0);

  static const speechRms = 280.0;
  static const minLoud = Duration(milliseconds: 200);

  void ignoreFor(Duration duration) {
    _ignoreUntil = DateTime.now().add(duration);
    reset();
  }

  void reset() {
    _pcm.clear();
    _loudMs = 0;
    _newSamples = 0;
    _takeSpeaking = false;
    _takeSpeechMs = 0;
    _takeSilenceMs = 0;
    _takeElapsedMs = 0;
  }

  /// Empieza una frase nueva, aparte de los tramos de activación.
  void beginTake() {
    _take = true;
    _ignoreUntil = DateTime.fromMillisecondsSinceEpoch(0);
    reset();
  }

  void cancelTake() {
    _take = false;
    reset();
  }

  /// Vuelve a aceptar audio en cuanto Forgen termina de hablar.
  void releaseIgnore() {
    _ignoreUntil = DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Devuelve el PCM del tramo listo para transcribir, o null si sigue en silencio.
  Uint8List? add(Uint8List chunk) {
    if (DateTime.now().isBefore(_ignoreUntil) || chunk.length < 2) return null;
    if (_take) return _addTake(chunk);

    final data = ByteData.sublistView(chunk);
    var sum = 0.0;
    var count = 0;
    for (var i = 0; i + 1 < chunk.length; i += 2) {
      final sample = data.getInt16(i, Endian.little);
      sum += sample * sample;
      count++;
    }
    if (count == 0) return null;

    final rms = math.sqrt(sum / count);
    final ms = (count * 1000) ~/ sampleRate;
    _pcm.addAll(chunk);
    _newSamples += count;
    if (rms >= speechRms) _loudMs += ms;

    final hopSamples = sampleRate * hop.inMilliseconds ~/ 1000;
    if (_newSamples < hopSamples) return null;

    final snapshot = Uint8List.fromList(_pcm);
    final overlapSamples = sampleRate * overlap.inMilliseconds ~/ 1000;
    final keepBytes = math.min(_pcm.length, overlapSamples * 2);
    _pcm.removeRange(0, _pcm.length - keepBytes);
    final loud = _loudMs;
    _loudMs = 0;
    _newSamples = 0;
    if (loud < minLoud.inMilliseconds) return null;
    return snapshot;
  }

  Uint8List? _addTake(Uint8List chunk) {
    final data = ByteData.sublistView(chunk);
    var sum = 0.0;
    var count = 0;
    for (var i = 0; i + 1 < chunk.length; i += 2) {
      final sample = data.getInt16(i, Endian.little);
      sum += sample * sample;
      count++;
    }
    if (count == 0) return null;

    final rms = math.sqrt(sum / count);
    final ms = (count * 1000) ~/ sampleRate;
    final loud = rms >= speechRms;

    if (!_takeSpeaking) {
      if (!loud) return null;
      _takeSpeaking = true;
      _takeSpeechMs = ms;
      _takeSilenceMs = 0;
      _takeElapsedMs = ms;
      _pcm
        ..clear()
        ..addAll(chunk);
      return null;
    }

    _pcm.addAll(chunk);
    _takeElapsedMs += ms;
    if (loud) {
      _takeSpeechMs += ms;
      _takeSilenceMs = 0;
    } else {
      _takeSilenceMs += ms;
    }

    final ended = _takeSilenceMs >= 500 || _takeElapsedMs >= 4500;
    if (!ended) return null;

    final spoken = _takeSpeechMs;
    final bytes = Uint8List.fromList(_pcm);
    _take = false;
    reset();
    if (spoken < minLoud.inMilliseconds) return null;
    return bytes;
  }
}

/// PCM 16-bit mono a WAV, para mandarlo a transcribir.
Uint8List pcm16ToWav(Uint8List pcm, {int sampleRate = 16000}) {
  final dataSize = pcm.length;
  final out = BytesBuilder(copy: false);
  void bytes(List<int> value) => out.add(value);
  void ascii(String value) => bytes(value.codeUnits);
  void u32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    bytes(data.buffer.asUint8List());
  }

  void u16(int value) {
    final data = ByteData(2)..setUint16(0, value, Endian.little);
    bytes(data.buffer.asUint8List());
  }

  ascii('RIFF');
  u32(36 + dataSize);
  ascii('WAVE');
  ascii('fmt ');
  u32(16);
  u16(1);
  u16(1);
  u32(sampleRate);
  u32(sampleRate * 2);
  u16(2);
  u16(16);
  ascii('data');
  u32(dataSize);
  bytes(pcm);
  return out.toBytes();
}
