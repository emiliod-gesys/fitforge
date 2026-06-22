import 'dart:async';

import 'package:flutter/services.dart';

import '../models/watch_session.dart';

/// Platform channel bridge between Flutter and native watch connectivity.
class WatchSessionBridge {
  WatchSessionBridge({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel =
            methodChannel ?? const MethodChannel('io.fitforge.fitforge/watch'),
        _eventChannel = eventChannel ??
            const EventChannel('io.fitforge.fitforge/watch_events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<WatchWorkoutAction>? _actionStream;

  Stream<WatchWorkoutAction> get actions {
    _actionStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      if (event is String) {
        return WatchWorkoutAction.decode(event);
      }
      if (event is Map) {
        return WatchWorkoutAction.fromJson(Map<String, dynamic>.from(event));
      }
      return null;
    }).where((action) => action != null).cast<WatchWorkoutAction>();
    return _actionStream!;
  }

  Future<void> publishSession(WatchWorkoutSnapshot snapshot) async {
    await _methodChannel.invokeMethod<void>(
      'publishSession',
      snapshot.encode(),
    );
  }

  Future<void> clearSession() async {
    await _methodChannel.invokeMethod<void>('clearSession');
  }

  Future<bool> isWatchAvailable() async {
    try {
      final available =
          await _methodChannel.invokeMethod<bool>('isWatchAvailable');
      return available ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
