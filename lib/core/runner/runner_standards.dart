/// Tipo de rutina runner de sistema.
enum RunnerType {
  outdoor,
  outdoorWalk,
  treadmill;

  String get code => switch (this) {
        RunnerType.outdoor => 'outdoor',
        RunnerType.outdoorWalk => 'outdoor_walk',
        RunnerType.treadmill => 'treadmill',
      };

  /// Carrera o caminata outdoor: misma sesión GPS.
  bool get usesOutdoorGps =>
      this == RunnerType.outdoor || this == RunnerType.outdoorWalk;

  bool get isWalk => this == RunnerType.outdoorWalk;

  static RunnerType? fromCode(String? value) => switch (value) {
        'outdoor' => RunnerType.outdoor,
        'outdoor_walk' => RunnerType.outdoorWalk,
        'treadmill' => RunnerType.treadmill,
        _ => null,
      };
}

/// Superficie para carrera outdoor.
enum RunningSurface {
  asphalt,
  track,
  trail;

  String get code => switch (this) {
        RunningSurface.asphalt => 'asphalt',
        RunningSurface.track => 'track',
        RunningSurface.trail => 'trail',
      };

  static RunningSurface? fromCode(String? value) => switch (value) {
        'asphalt' => RunningSurface.asphalt,
        'track' => RunningSurface.track,
        'trail' => RunningSurface.trail,
        _ => null,
      };
}
