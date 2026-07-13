/// Tipo de rutina runner de sistema.
enum RunnerType {
  outdoor,
  treadmill;

  String get code => switch (this) {
        RunnerType.outdoor => 'outdoor',
        RunnerType.treadmill => 'treadmill',
      };

  static RunnerType? fromCode(String? value) => switch (value) {
        'outdoor' => RunnerType.outdoor,
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
