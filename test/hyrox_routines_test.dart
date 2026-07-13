import 'package:fitforge/core/hyrox/hyrox_routine_builder.dart';
import 'package:fitforge/core/hyrox/hyrox_standards.dart';
import 'package:fitforge/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UserProfile profile({
    Gender? gender,
    double? bodyWeight,
  }) {
    return UserProfile(
      id: 'u1',
      gender: gender,
      bodyWeight: bodyWeight,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  test('race day women uses open women loads', () {
    final t = HyroxStandards.targetsFor(
      profile: profile(gender: Gender.female, bodyWeight: 65),
      level: HyroxLevel.race,
    );
    expect(t.runMeters, 1000);
    expect(t.sledPushKg, 102);
    expect(t.farmersPerHandKg, 16);
    expect(t.wallBallKg, 4);
  });

  test('race day men uses open men loads', () {
    final t = HyroxStandards.targetsFor(
      profile: profile(gender: Gender.male, bodyWeight: 80),
      level: HyroxLevel.race,
    );
    expect(t.sledPushKg, 152);
    expect(t.farmersPerHandKg, 24);
    expect(t.wallBallKg, 6);
    expect(t.wallBallReps, 100);
  });

  test('prep is easier than build is easier than race', () {
    final p = profile(gender: Gender.male, bodyWeight: 80);
    final prep = HyroxStandards.targetsFor(profile: p, level: HyroxLevel.prep);
    final build = HyroxStandards.targetsFor(profile: p, level: HyroxLevel.build);
    final race = HyroxStandards.targetsFor(profile: p, level: HyroxLevel.race);

    expect(prep.runMeters, lessThan(build.runMeters));
    expect(build.runMeters, lessThan(race.runMeters));
    expect(prep.sledPushKg, lessThan(build.sledPushKg));
    expect(build.sledPushKg, lessThanOrEqualTo(race.sledPushKg));
  });

  test('builder creates 16 phases alternating run and stations', () {
    final routines = HyroxRoutineBuilder.buildAll(
      profile(gender: Gender.female, bodyWeight: 60),
    );
    expect(routines, hasLength(3));
    for (final r in routines) {
      expect(r.isHyroxSystem, isTrue);
      expect(r.exercises, hasLength(16));
      expect(r.exercises.first.exerciseId, 'ff_cardio_outdoor_running');
      expect(r.exercises[1].exerciseId, 'ff_cardio_ski_erg');
      expect(r.exercises.last.exerciseId, 'ff_cf_wall_ball');
    }
    expect(routines.map((r) => r.hyroxLevel).toList(), [
      HyroxLevel.prep,
      HyroxLevel.build,
      HyroxLevel.race,
    ]);
  });
}
