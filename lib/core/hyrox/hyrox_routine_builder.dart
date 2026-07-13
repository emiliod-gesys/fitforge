import 'package:uuid/uuid.dart';

import '../../models/exercise_logging.dart';
import '../../models/profile.dart';
import '../../models/routine.dart';
import 'hyrox_exercise_ids.dart';
import 'hyrox_standards.dart';

/// Construye las 3 rutinas Hyrox progresivas según perfil (género + peso).
abstract final class HyroxRoutineBuilder {
  static const _uuid = Uuid();

  static List<Routine> buildAll(UserProfile profile) {
    return [
      build(profile: profile, level: HyroxLevel.prep),
      build(profile: profile, level: HyroxLevel.build),
      build(profile: profile, level: HyroxLevel.race),
    ];
  }

  static Routine build({
    required UserProfile profile,
    required HyroxLevel level,
  }) {
    final t = HyroxStandards.targetsFor(profile: profile, level: level);
    final women = HyroxStandards.isWomenDivision(profile.gender);
    final division = women ? 'Women Open' : 'Men Open';
    final exercises = <RoutineExercise>[];
    var order = 0;

    void addRun() {
      exercises.add(_cardio(
        orderIndex: order++,
        exerciseId: HyroxExerciseIds.run,
        name: 'Carrera Hyrox',
        meters: t.runMeters,
      ));
    }

    addRun();
    exercises.add(_cardio(
      orderIndex: order++,
      exerciseId: HyroxExerciseIds.skiErg,
      name: 'SkiErg',
      meters: t.skiMeters,
    ));
    addRun();
    exercises.add(_loadedDistance(
      orderIndex: order++,
      exerciseId: HyroxExerciseIds.sledPush,
      name: 'Sled Push',
      weightKg: t.sledPushKg,
      meters: t.sledPushMeters,
      perArm: false,
    ));
    addRun();
    exercises.add(_loadedDistance(
      orderIndex: order++,
      exerciseId: HyroxExerciseIds.sledPull,
      name: 'Sled Pull',
      weightKg: t.sledPullKg,
      meters: t.sledPullMeters,
      perArm: false,
    ));
    addRun();
    exercises.add(_loadedDistance(
      orderIndex: order++,
      exerciseId: HyroxExerciseIds.burpeeBroadJump,
      name: 'Burpee Broad Jump',
      weightKg: null,
      meters: t.burpeeBroadJumpMeters,
      perArm: false,
      bodyweight: true,
    ));
    addRun();
    exercises.add(_cardio(
      orderIndex: order++,
      exerciseId: HyroxExerciseIds.rowing,
      name: 'Remo',
      meters: t.rowMeters,
    ));
    addRun();
    exercises.add(_loadedDistance(
      orderIndex: order++,
      exerciseId: HyroxExerciseIds.farmers,
      name: 'Farmers Carry',
      weightKg: t.farmersPerHandKg,
      meters: t.farmersMeters,
      perArm: true,
    ));
    addRun();
    exercises.add(_loadedDistance(
      orderIndex: order++,
      exerciseId: HyroxExerciseIds.sandbagLunges,
      name: 'Sandbag Lunges',
      weightKg: t.lungesKg,
      meters: t.lungesMeters,
      perArm: false,
    ));
    addRun();
    exercises.add(_wallBalls(
      orderIndex: order++,
      weightKg: t.wallBallKg,
      reps: t.wallBallReps,
    ));

    final now = DateTime.now();
    return Routine(
      id: '',
      userId: profile.id,
      name: _name(level),
      description: _description(level, division, t),
      targetMuscles: const ['Full body', 'Cardio', 'Hyrox'],
      exercises: exercises,
      createdAt: now,
      updatedAt: now,
      isAiGenerated: false,
      isFavorite: false,
      isHyroxSystem: true,
      hyroxLevel: level,
    );
  }

  static String _name(HyroxLevel level) => switch (level) {
        HyroxLevel.prep => 'Hyrox 1 · Prep',
        HyroxLevel.build => 'Hyrox 2 · Build',
        HyroxLevel.race => 'Hyrox 3 · Race Day',
      };

  static String _description(
    HyroxLevel level,
    String division,
    HyroxStationTargets t,
  ) {
    final pct = (level.distanceScale * 100).round();
    final base = switch (level) {
      HyroxLevel.prep =>
        'Fundamentos Hyrox (~$pct% distancias oficiales). Enfócate en técnica y ritmo.',
      HyroxLevel.build =>
        'Volumen intermedio (~$pct%). Acerca cargas y splits al ritmo de carrera.',
      HyroxLevel.race =>
        'Simulación Race Day a estándares $division (100%). Cronometra cada fase.',
    };
    return '$base\n'
        'Circuito: 8×carrera + 8 estaciones (SkiErg → Sled Push → Sled Pull → '
        'BBJ → Row → Farmers → Lunges → Wall Balls).\n'
        'Cargas: sled push ${t.sledPushKg.toStringAsFixed(0)} kg · '
        'farmers ${t.farmersPerHandKg.toStringAsFixed(0)} kg/mano · '
        'wall ball ${t.wallBallKg.toStringAsFixed(0)} kg × ${t.wallBallReps}.';
  }

  static RoutineExercise _cardio({
    required int orderIndex,
    required String exerciseId,
    required String name,
    required double meters,
  }) {
    final metersRound = meters.round();
    // Estimación suave ~5:00/km para sugerir duración objetivo.
    final durationHint = (metersRound / 1000 * 300).round();
    return RoutineExercise(
      id: _uuid.v4(),
      exerciseId: exerciseId,
      exerciseName: name,
      orderIndex: orderIndex,
      targetSets: 1,
      targetReps: 0,
      targetWeight: null,
      restSeconds: 0,
      loggingType: ExerciseLoggingType.cardio,
      targetDurationSeconds: durationHint,
      targetDistanceMeters: metersRound.toDouble(),
      targetSetDetails: const [RoutineSetTarget(reps: 0)],
    );
  }

  static RoutineExercise _loadedDistance({
    required int orderIndex,
    required String exerciseId,
    required String name,
    required double? weightKg,
    required double meters,
    required bool perArm,
    bool bodyweight = false,
  }) {
    // 1 "serie" = completar la distancia; el tiempo lo captura el timer de fase.
    const reps = 1;
    return RoutineExercise(
      id: _uuid.v4(),
      exerciseId: exerciseId,
      exerciseName: name,
      orderIndex: orderIndex,
      targetSets: 1,
      targetReps: reps,
      targetWeight: weightKg,
      restSeconds: 0,
      loggingType: ExerciseLoggingType.strength,
      targetDistanceMeters: meters,
      perArmWeight: perArm,
      targetSetDetails: [
        RoutineSetTarget(reps: reps, weight: bodyweight ? null : weightKg),
      ],
    );
  }

  static RoutineExercise _wallBalls({
    required int orderIndex,
    required double weightKg,
    required int reps,
  }) {
    return RoutineExercise(
      id: _uuid.v4(),
      exerciseId: HyroxExerciseIds.wallBall,
      exerciseName: 'Wall Balls',
      orderIndex: orderIndex,
      targetSets: 1,
      targetReps: reps,
      targetWeight: weightKg,
      restSeconds: 0,
      loggingType: ExerciseLoggingType.strength,
      targetSetDetails: [RoutineSetTarget(reps: reps, weight: weightKg)],
    );
  }
}
