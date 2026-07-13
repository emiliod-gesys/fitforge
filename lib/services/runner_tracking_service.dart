import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../core/runner/runner_models.dart';
import '../core/runner/runner_session_storage.dart';
import '../core/runner/runner_standards.dart';
import '../core/runner/runner_tracking.dart';

enum RunnerTrackingStatus {
  idle,
  acquiringGps,
  running,
  paused,
  stopped,
}

class RunnerTrackingService {
  StreamSubscription<Position>? _sub;
  RunnerTrackingSnapshot? _snapshot;
  RunnerRoutePoint? _lastPoint;
  DateTime? _lastPositionAt;
  final _controller = StreamController<RunnerTrackingSnapshot>.broadcast();

  Stream<RunnerTrackingSnapshot> get stream => _controller.stream;
  RunnerTrackingSnapshot? get snapshot => _snapshot;
  RunnerTrackingStatus status = RunnerTrackingStatus.idle;

  Future<bool> ensurePermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  LocationSettings _locationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'FitForge',
          notificationText: 'Registrando tu carrera…',
          enableWakeLock: true,
        ),
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );
  }

  Future<void> start({
    required String workoutId,
    RunningSurface? surface,
  }) async {
    await stop(clearStorage: false);

    final restored = await RunnerSessionStorage.load(workoutId);
    _snapshot = restored ??
        RunnerTrackingSnapshot(
          workoutId: workoutId,
          surface: surface,
          startedAt: DateTime.now(),
        );
    if (surface != null && _snapshot!.surface == null) {
      _snapshot = RunnerTrackingSnapshot(
        workoutId: workoutId,
        surface: surface,
        startedAt: _snapshot!.startedAt,
        accumulatedPauseMs: _snapshot!.accumulatedPauseMs,
        distanceMeters: _snapshot!.distanceMeters,
        elevationGainMeters: _snapshot!.elevationGainMeters,
        elevationLossMeters: _snapshot!.elevationLossMeters,
        route: _snapshot!.route,
        splits: _snapshot!.splits,
      );
    }
    if (_snapshot!.route.isNotEmpty) {
      _lastPoint = _snapshot!.route.last;
    }

    status = RunnerTrackingStatus.acquiringGps;
    _emit();

    _sub = Geolocator.getPositionStream(locationSettings: _locationSettings()).listen(
      _onPosition,
      onError: (_) {},
    );

    status = _snapshot!.isPaused ? RunnerTrackingStatus.paused : RunnerTrackingStatus.running;
    _emit();
  }

  void _onPosition(Position position) {
    if (_snapshot == null || status == RunnerTrackingStatus.stopped) return;
    if (status == RunnerTrackingStatus.paused) return;

    final now = DateTime.now();
    final accuracy = position.accuracy;
    double? deltaMeters;
    var deltaSeconds = 0;

    if (_lastPoint != null && _lastPositionAt != null) {
      deltaMeters = RunnerTracking.haversineMeters(
        _lastPoint!.lat,
        _lastPoint!.lng,
        position.latitude,
        position.longitude,
      );
      deltaSeconds = now.difference(_lastPositionAt!).inSeconds.clamp(1, 120);
    }

    if (!RunnerTracking.isValidGpsPoint(
      accuracyMeters: accuracy,
      deltaMeters: deltaMeters,
      deltaSeconds: deltaSeconds,
    )) {
      return;
    }

    var distance = _snapshot!.distanceMeters;
    if (deltaMeters != null && deltaMeters > 0) {
      distance += deltaMeters;
    }

    double? alt;
    if (RunnerTracking.isValidAltitude(
      altitudeMeters: position.altitude,
      altitudeAccuracyMeters: position.altitudeAccuracy,
    )) {
      alt = position.altitude;
    }

    var gain = _snapshot!.elevationGainMeters;
    var loss = _snapshot!.elevationLossMeters;
    if (alt != null) {
      double? previousAlt = _lastPoint?.alt;
      if (previousAlt == null && _snapshot!.route.isNotEmpty) {
        for (var i = _snapshot!.route.length - 1; i >= 0; i--) {
          final candidate = _snapshot!.route[i].alt;
          if (candidate != null) {
            previousAlt = candidate;
            break;
          }
        }
      }
      final delta = RunnerTracking.elevationDelta(previousAlt: previousAlt, currentAlt: alt);
      gain += delta.gain;
      loss += delta.loss;
    }

    final point = RunnerRoutePoint(
      lat: position.latitude,
      lng: position.longitude,
      timestampMs: now.millisecondsSinceEpoch,
      alt: alt,
    );

    final route = [..._snapshot!.route, point];
    final elapsed = _snapshot!.elapsedSeconds(now);
    final newSplits = RunnerTracking.detectNewSplits(
      totalDistanceMeters: distance,
      elapsedSeconds: elapsed,
      existing: _snapshot!.splits,
    );
    final splits = [..._snapshot!.splits, ...newSplits];

    _snapshot = _snapshot!.copyWith(
      distanceMeters: distance,
      elevationGainMeters: gain,
      elevationLossMeters: loss,
      route: route,
      splits: splits,
    );
    _lastPoint = point;
    _lastPositionAt = now;
    status = RunnerTrackingStatus.running;

    unawaited(RunnerSessionStorage.save(_snapshot!));
    _emit();
  }

  Future<void> pause() async {
    if (_snapshot == null || status != RunnerTrackingStatus.running) return;
    status = RunnerTrackingStatus.paused;
    _snapshot = _snapshot!.copyWith(isPaused: true, pausedAt: DateTime.now());
    await RunnerSessionStorage.save(_snapshot!);
    _emit();
  }

  Future<void> resume() async {
    if (_snapshot == null || status != RunnerTrackingStatus.paused) return;
    final pausedAt = _snapshot!.pausedAt;
    var accumulated = _snapshot!.accumulatedPauseMs;
    if (pausedAt != null) {
      accumulated += DateTime.now().difference(pausedAt).inMilliseconds;
    }
    _snapshot = _snapshot!.copyWith(
      isPaused: false,
      accumulatedPauseMs: accumulated,
      clearPausedAt: true,
    );
    status = RunnerTrackingStatus.running;
    await RunnerSessionStorage.save(_snapshot!);
    _emit();
  }

  Future<RunnerTrackingSnapshot?> stop({bool clearStorage = true}) async {
    await _sub?.cancel();
    _sub = null;
    status = RunnerTrackingStatus.stopped;
    final result = _snapshot;
    if (clearStorage && result != null) {
      await RunnerSessionStorage.clear(result.workoutId);
    }
    _snapshot = null;
    _lastPoint = null;
    _lastPositionAt = null;
    return result;
  }

  void dispose() {
    unawaited(_sub?.cancel());
    _controller.close();
  }

  void _emit() {
    if (_snapshot != null && !_controller.isClosed) {
      _controller.add(_snapshot!);
    }
  }
}
