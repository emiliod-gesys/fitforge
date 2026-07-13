import '../../models/exercise_logging.dart';

abstract final class CardioFormat {
  static String duration(int? seconds) {
    if (seconds == null || seconds <= 0) return '—';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static int? parseDuration(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length != 2) return null;
      final m = int.tryParse(parts[0]);
      final s = int.tryParse(parts[1]);
      return durationFromParts(minutes: m, seconds: s);
    }
    return int.tryParse(trimmed);
  }

  static ({int minutes, int seconds}) durationParts(int? totalSeconds) {
    if (totalSeconds == null || totalSeconds <= 0) {
      return (minutes: 0, seconds: 0);
    }
    return (minutes: totalSeconds ~/ 60, seconds: totalSeconds % 60);
  }

  static int? durationFromParts({int? minutes, int? seconds}) {
    final m = minutes ?? 0;
    final s = seconds ?? 0;
    if (m <= 0 && s <= 0) return null;
    if (m < 0 || s < 0 || s >= 60) return null;
    return m * 60 + s;
  }

  static int? durationFromPartStrings(String minutesText, String secondsText) {
    final mTrim = minutesText.trim();
    final sTrim = secondsText.trim();
    if (mTrim.isEmpty && sTrim.isEmpty) return null;

    final m = mTrim.isEmpty ? 0 : int.tryParse(mTrim);
    final s = sTrim.isEmpty ? 0 : int.tryParse(sTrim);
    if (m == null || s == null) return null;
    return durationFromParts(minutes: m, seconds: s);
  }

  static String distance(double? meters, String unitSystem) {
    if (meters == null || meters <= 0) return '—';
    if (unitSystem == 'imperial') {
      final miles = meters / 1609.344;
      return '${miles.toStringAsFixed(2)} mi';
    }
    final km = meters / 1000;
    return '${km.toStringAsFixed(2)} km';
  }

  static double? parseDistanceMeters(String input, String unitSystem) {
    final parsed = double.tryParse(input.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return null;
    if (unitSystem == 'imperial') return parsed * 1609.344;
    return parsed * 1000;
  }

  static String distanceInputLabel(String unitSystem) {
    return unitSystem == 'imperial' ? 'mi' : 'km';
  }

  static String incline(double? percent) {
    if (percent == null || percent < 0) return '—';
    return '${percent.toStringAsFixed(1)}%';
  }

  /// Desnivel / elevación en metros o pies (2 decimales).
  static String elevation(double? meters, String unitSystem, {bool showSign = false}) {
    if (meters == null || meters <= 0) return '—';
    return _formatElevationMeters(meters, unitSystem, showSign: showSign);
  }

  static String elevationLive(double meters, String unitSystem) {
    return _formatElevationMeters(meters, unitSystem);
  }

  static String elevationNet({
    required double gainMeters,
    required double lossMeters,
    required String unitSystem,
  }) {
    return _formatElevationMeters(
      gainMeters - lossMeters,
      unitSystem,
      showSign: true,
    );
  }

  static String _formatElevationMeters(
    double meters,
    String unitSystem, {
    bool showSign = false,
  }) {
    if (unitSystem == 'imperial') {
      final feet = meters * 3.28084;
      final formatted = feet.toStringAsFixed(2);
      if (showSign && feet > 0) return '+$formatted ft';
      return '$formatted ft';
    }
    final formatted = meters.toStringAsFixed(2);
    if (showSign && meters > 0) return '+$formatted m';
    return '$formatted m';
  }

  static String elevationGainLoss({
    required double? gainMeters,
    required double? lossMeters,
    required String unitSystem,
  }) {
    final gain = elevation(gainMeters, unitSystem);
    final loss = elevation(lossMeters, unitSystem);
    if (gain == '—' && loss == '—') return '—';
    if (loss == '—') return '↑ $gain';
    if (gain == '—') return '↓ $loss';
    return '↑ $gain · ↓ $loss';
  }

  /// Pace from seconds per km (metric) or sec per mile (imperial).
  static String pace(double? secPerKm, String unitSystem) {
    if (secPerKm == null || secPerKm <= 0) return '—';
    final sec = unitSystem == 'imperial' ? secPerKm * 1.609344 : secPerKm;
    final m = sec ~/ 60;
    final s = (sec % 60).round().clamp(0, 59);
    final unit = unitSystem == 'imperial' ? '/mi' : '/km';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}$unit';
  }

  static String difficulty(double? level) {
    if (level == null || level <= 0) return '—';
    if (level % 1 == 0) return level.toInt().toString();
    return level.toStringAsFixed(1);
  }

  static String steps(int? count) {
    if (count == null || count <= 0) return '—';
    return count.toString();
  }

  static String setSummary({
    required CardioLoggingConfig config,
    required String unitSystem,
    int? durationSeconds,
    double? distanceMeters,
    double? inclinePercent,
    int? stepCount,
  }) {
    final parts = <String>[];
    if (config.tracksDuration) parts.add(duration(durationSeconds));
    if (config.tracksDistance) parts.add(distance(distanceMeters, unitSystem));
    if (config.tracksIncline) parts.add(incline(inclinePercent));
    if (config.tracksDifficulty) {
      final level = difficulty(inclinePercent);
      if (level != '—') parts.add('$level lvl');
    }
    if (config.tracksSteps) {
      final stepsText = CardioFormat.steps(stepCount);
      if (stepsText != '—') parts.add('$stepsText pasos');
    }
    return parts.where((p) => p != '—').join(' · ');
  }
}
