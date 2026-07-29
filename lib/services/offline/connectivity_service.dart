import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/utils/connection_error.dart';

/// Estado de red de la app. `isOnline` es heurístico (Wi‑Fi/datos ≠ internet real).
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _controller.stream;

  Future<void> initialize() async {
    _subscription ??= _connectivity.onConnectivityChanged.listen(_handleResults);
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleResults(results);
    } catch (_) {
      _setOnline(false);
    }
  }

  void _handleResults(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    _setOnline(online);
  }

  void _setOnline(bool value) {
    if (_isOnline == value) return;
    _isOnline = value;
    if (!_controller.isClosed) {
      _controller.add(value);
    }
  }

  /// Intenta la operación remota; devuelve `null` si no hay red o falla por conexión.
  Future<T?> tryRemote<T>(Future<T> Function() operation) async {
    if (!_isOnline) return null;
    try {
      return await operation();
    } catch (e) {
      if (isConnectionError(e)) {
        _setOnline(false);
        return null;
      }
      rethrow;
    }
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_controller.close());
  }
}
