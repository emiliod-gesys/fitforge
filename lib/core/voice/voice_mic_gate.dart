import 'package:flutter/foundation.dart';

/// Pausa a Hey Forgen mientras otra pantalla usa el micrófono.
abstract final class VoiceMicGate {
  static final holdCount = ValueNotifier<int>(0);

  static void acquire() => holdCount.value++;

  static void release() {
    if (holdCount.value == 0) return;
    holdCount.value--;
  }
}
