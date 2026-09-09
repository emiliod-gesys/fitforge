/// Evita que un entreno olvidado abierto inflé duración y calorías.
///
/// El reloj de pared cuenta hasta que pulsan Terminar. Si se les olvida,
/// recortamos al último momento con actividad (+ un descanso) y un tope.
abstract final class WorkoutDurationGuard {
  static const restBufferMinutes = 3;
  static const idlePauseAfter = Duration(minutes: 25);
  static const slackMinutes = 10;
  static const maxStrengthMinutes = 240;
  static const maxEnduranceMinutes = 12 * 60;

  static WorkoutDurationResolution resolve({
    required int wallClockMinutes,
    required DateTime startedAt,
    DateTime? lastActivityAt,
    DateTime? now,
    bool skipIdleTrim = false,
  }) {
    final maxMinutes =
        skipIdleTrim ? maxEnduranceMinutes : maxStrengthMinutes;
    final wall = wallClockMinutes < 0 ? 0 : wallClockMinutes;

    if (skipIdleTrim) {
      final capped = wall.clamp(0, maxMinutes);
      return WorkoutDurationResolution(
        minutes: capped == 0 ? 0 : capped,
        wallClockMinutes: wall,
      );
    }

    var used = wall;
    if (lastActivityAt != null) {
      final sessionEnd = lastActivityAt.add(
        const Duration(minutes: restBufferMinutes),
      );
      var activityMinutes = sessionEnd.difference(startedAt).inMinutes;
      if (activityMinutes < 1) activityMinutes = wall > 0 ? 1 : 0;
      if (wall > activityMinutes + slackMinutes) {
        used = activityMinutes;
      }
    }

    used = used.clamp(0, maxMinutes);
    return WorkoutDurationResolution(
      minutes: used,
      wallClockMinutes: wall,
    );
  }

  static bool shouldPauseForIdle({
    required DateTime lastActivityAt,
    required DateTime now,
    bool restTimerActive = false,
    bool skip = false,
  }) {
    if (skip || restTimerActive) return false;
    return now.difference(lastActivityAt) >= idlePauseAfter;
  }
}

class WorkoutDurationResolution {
  const WorkoutDurationResolution({
    required this.minutes,
    required this.wallClockMinutes,
  });

  final int minutes;
  final int wallClockMinutes;

  int get trimmedMinutes =>
      wallClockMinutes > minutes ? wallClockMinutes - minutes : 0;

  bool get trimmed => trimmedMinutes >= slackDisplayMinutes;

  static const slackDisplayMinutes = 15;
}
