import '../../models/profile.dart';

/// Niveles progresivos de preparación Hyrox (prep → build → race).
enum HyroxLevel {
  prep,
  build,
  race;

  String get code => name;

  static HyroxLevel fromCode(String? value) {
    return switch (value) {
      'build' => HyroxLevel.build,
      'race' => HyroxLevel.race,
      _ => HyroxLevel.prep,
    };
  }

  /// Fracción de distancias oficiales.
  double get distanceScale => switch (this) {
        HyroxLevel.prep => 0.5,
        HyroxLevel.build => 0.75,
        HyroxLevel.race => 1.0,
      };

  /// Fracción de cargas oficiales Open.
  double get loadScale => switch (this) {
        HyroxLevel.prep => 0.5,
        HyroxLevel.build => 0.75,
        HyroxLevel.race => 1.0,
      };
}

/// Estándares oficiales HYROX Open (temporada actual) + escalado por nivel.
class HyroxStationTargets {
  final double runMeters;
  final double skiMeters;
  final double sledPushKg;
  final double sledPushMeters;
  final double sledPullKg;
  final double sledPullMeters;
  final double burpeeBroadJumpMeters;
  final double rowMeters;
  final double farmersPerHandKg;
  final double farmersMeters;
  final double lungesKg;
  final double lungesMeters;
  final double wallBallKg;
  final int wallBallReps;

  const HyroxStationTargets({
    required this.runMeters,
    required this.skiMeters,
    required this.sledPushKg,
    required this.sledPushMeters,
    required this.sledPullKg,
    required this.sledPullMeters,
    required this.burpeeBroadJumpMeters,
    required this.rowMeters,
    required this.farmersPerHandKg,
    required this.farmersMeters,
    required this.lungesKg,
    required this.lungesMeters,
    required this.wallBallKg,
    required this.wallBallReps,
  });
}

abstract final class HyroxStandards {
  /// Open Women vs Open Men (Women Pro ≈ Men Open).
  static bool isWomenDivision(Gender? gender) => gender == Gender.female;

  static HyroxStationTargets targetsFor({
    required UserProfile profile,
    required HyroxLevel level,
  }) {
    final women = isWomenDivision(profile.gender);
    final d = level.distanceScale;
    final l = level.loadScale;

    // Oficiales Open.
    final sledPush = women ? 102.0 : 152.0;
    final sledPull = women ? 78.0 : 103.0;
    final farmers = women ? 16.0 : 24.0;
    final lunges = women ? 10.0 : 20.0;
    final wallBall = women ? 4.0 : 6.0;
    final wallReps = women && level == HyroxLevel.prep ? 40 : (women ? 75 : 100);

    // Ajuste suave por peso corporal (±10% si está muy lejos del promedio de división).
    final bw = profile.bodyWeight;
    var bwFactor = 1.0;
    if (bw != null && bw > 0) {
      final reference = women ? 65.0 : 80.0;
      bwFactor = (bw / reference).clamp(0.9, 1.1);
    }

    double scaleLoad(double official) =>
        _roundNice(official * l * bwFactor);

    int scaleReps(int official) {
      if (level == HyroxLevel.race) return official;
      return (official * d).round().clamp(20, official);
    }

    return HyroxStationTargets(
      runMeters: 1000 * d,
      skiMeters: 1000 * d,
      sledPushKg: scaleLoad(sledPush),
      sledPushMeters: 50 * d,
      sledPullKg: scaleLoad(sledPull),
      sledPullMeters: 50 * d,
      burpeeBroadJumpMeters: 80 * d,
      rowMeters: 1000 * d,
      farmersPerHandKg: scaleLoad(farmers),
      farmersMeters: 200 * d,
      lungesKg: scaleLoad(lunges),
      lungesMeters: 100 * d,
      wallBallKg: scaleLoad(wallBall),
      wallBallReps: scaleReps(wallReps),
    );
  }

  static double _roundNice(double kg) {
    if (kg < 8) return (kg * 2).round() / 2.0;
    if (kg < 40) return kg.roundToDouble();
    return (kg / 2).round() * 2.0;
  }
}
