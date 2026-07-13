import 'dart:math';

import 'runner_standards.dart';
import 'runner_tracking.dart';

class RunnerRoutePoint {
  final double lat;
  final double lng;
  final int timestampMs;
  /// Altitud en metros sobre el nivel del mar (GPS), si está disponible.
  final double? alt;

  const RunnerRoutePoint({
    required this.lat,
    required this.lng,
    required this.timestampMs,
    this.alt,
  });

  factory RunnerRoutePoint.fromJson(Map<String, dynamic> json) {
    return RunnerRoutePoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      timestampMs: json['t'] as int? ?? json['timestamp_ms'] as int? ?? 0,
      alt: (json['alt'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        't': timestampMs,
        if (alt != null) 'alt': alt,
      };
}

class RunnerKmSplit {
  final int km;
  final int seconds;

  const RunnerKmSplit({required this.km, required this.seconds});

  factory RunnerKmSplit.fromJson(Map<String, dynamic> json) {
    return RunnerKmSplit(
      km: json['km'] as int? ?? 1,
      seconds: json['seconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'km': km, 'seconds': seconds};
}

class RunnerTrackingSnapshot {
  final String workoutId;
  final RunningSurface? surface;
  final DateTime startedAt;
  final DateTime? pausedAt;
  final int accumulatedPauseMs;
  final double distanceMeters;
  final double elevationGainMeters;
  final double elevationLossMeters;
  final List<RunnerRoutePoint> route;
  final List<RunnerKmSplit> splits;
  final bool isPaused;
  /// Cuando se detecta movimiento real (null = esperando arranque automático).
  final DateTime? movementStartedAt;

  const RunnerTrackingSnapshot({
    required this.workoutId,
    this.surface,
    required this.startedAt,
    this.pausedAt,
    this.accumulatedPauseMs = 0,
    this.distanceMeters = 0,
    this.elevationGainMeters = 0,
    this.elevationLossMeters = 0,
    this.route = const [],
    this.splits = const [],
    this.isPaused = false,
    this.movementStartedAt,
  });

  bool get hasMovementStarted =>
      movementStartedAt != null || distanceMeters >= RunnerTracking.minMovementStartMeters;

  int elapsedSeconds(DateTime now) {
    final origin = movementStartedAt;
    if (origin == null) return 0;
    var ms = now.difference(origin).inMilliseconds - accumulatedPauseMs;
    if (isPaused && pausedAt != null) {
      ms -= now.difference(pausedAt!).inMilliseconds;
    }
    return max(0, ms ~/ 1000);
  }

  double? avgPaceSecPerKm(DateTime now) {
    if (distanceMeters <= 0) return null;
    return elapsedSeconds(now) / (distanceMeters / 1000);
  }

  factory RunnerTrackingSnapshot.fromJson(Map<String, dynamic> json) {
    final routeRaw = json['route'] as List? ?? [];
    final splitsRaw = json['splits'] as List? ?? [];
    return RunnerTrackingSnapshot(
      workoutId: json['workout_id'] as String,
      surface: RunningSurface.fromCode(json['surface'] as String?),
      startedAt: DateTime.parse(json['started_at'] as String),
      pausedAt: json['paused_at'] != null ? DateTime.parse(json['paused_at'] as String) : null,
      accumulatedPauseMs: json['accumulated_pause_ms'] as int? ?? 0,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0,
      elevationGainMeters: (json['elevation_gain_m'] as num?)?.toDouble() ?? 0,
      elevationLossMeters: (json['elevation_loss_m'] as num?)?.toDouble() ?? 0,
      route: routeRaw
          .map((e) => RunnerRoutePoint.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      splits: splitsRaw
          .map((e) => RunnerKmSplit.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      isPaused: json['is_paused'] as bool? ?? false,
      movementStartedAt: json['movement_started_at'] != null
          ? DateTime.parse(json['movement_started_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'workout_id': workoutId,
        if (surface != null) 'surface': surface!.code,
        'started_at': startedAt.toIso8601String(),
        if (pausedAt != null) 'paused_at': pausedAt!.toIso8601String(),
        'accumulated_pause_ms': accumulatedPauseMs,
        'distance_meters': distanceMeters,
        'elevation_gain_m': elevationGainMeters,
        'elevation_loss_m': elevationLossMeters,
        'route': route.map((p) => p.toJson()).toList(),
        'splits': splits.map((s) => s.toJson()).toList(),
        'is_paused': isPaused,
        if (movementStartedAt != null)
          'movement_started_at': movementStartedAt!.toIso8601String(),
      };

  RunnerTrackingSnapshot copyWith({
    DateTime? pausedAt,
    int? accumulatedPauseMs,
    double? distanceMeters,
    double? elevationGainMeters,
    double? elevationLossMeters,
    List<RunnerRoutePoint>? route,
    List<RunnerKmSplit>? splits,
    bool? isPaused,
    DateTime? movementStartedAt,
    bool clearPausedAt = false,
  }) {
    return RunnerTrackingSnapshot(
      workoutId: workoutId,
      surface: surface,
      startedAt: startedAt,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      accumulatedPauseMs: accumulatedPauseMs ?? this.accumulatedPauseMs,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      elevationLossMeters: elevationLossMeters ?? this.elevationLossMeters,
      route: route ?? this.route,
      splits: splits ?? this.splits,
      isPaused: isPaused ?? this.isPaused,
      movementStartedAt: movementStartedAt ?? this.movementStartedAt,
    );
  }
}
