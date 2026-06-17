import '../../models/body_metric.dart';
import '../../models/profile.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import 'player_level.dart';
import 'unit_converter.dart';
import 'workout_streak.dart';

/// Construye el contexto del usuario para el AI Coach.
abstract final class AiCoachContextBuilder {
  static String build({
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
    WorkoutWeeklyStats? weeklyStats,
    List<PersonalRecord>? personalRecords,
    List<Workout>? recentWorkouts,
    List<Routine>? routines,
  }) {
    final buffer = StringBuffer();

    if (profile != null) {
      buffer.writeln('=== PERFIL PERSONAL ===');
      if (profile.displayName != null && profile.displayName!.isNotEmpty) {
        buffer.writeln('Nombre: ${profile.displayName}');
      }
      if (profile.age != null) {
        buffer.writeln('Edad: ${profile.age} años');
      }
      buffer.writeln('Género: ${_genderLabel(profile.gender)}');
      if (profile.heightCm != null) {
        buffer.writeln('Altura: ${profile.heightCm!.toStringAsFixed(0)} cm');
      }
      final weightText = profile.bodyWeight != null
          ? UnitConverter.formatMass(profile.bodyWeight, profile.unitSystem)
          : 'no registrado';
      buffer.writeln('Peso corporal (perfil): $weightText');
      buffer.writeln('Unidades preferidas: ${profile.unitSystem == 'lb' ? 'libras' : 'kilogramos'}');
      buffer.writeln('Idioma preferido: ${profile.preferredLanguage == 'en' ? 'inglés' : 'español'}');

      buffer.writeln('\n=== OBJETIVO Y EXPERIENCIA ===');
      buffer.writeln('Objetivo fitness: ${_goalLabel(profile.fitnessGoal)}');
      buffer.writeln('Nivel de experiencia (autoreportado): ${_experienceLabel(profile.experienceLevel)}');

      final level = PlayerLevelCalculator.fromTotalXp(profile.totalXp);
      buffer.writeln('\n=== PROGRESO EN LA APP ===');
      buffer.writeln('Nivel del jugador: ${level.level}');
      buffer.writeln('XP total: ${level.totalXp}');
      if (!level.isMaxLevel) {
        buffer.writeln(
          'Progreso al siguiente nivel: ${level.xpInCurrentLevel}/${level.xpToNextLevel} XP',
        );
      }
    }

    if (weeklyStats != null) {
      buffer.writeln('Racha semanal (≥4 entrenos/semana): ${weeklyStats.streakWeeks} semanas');
      buffer.writeln(
        'Entrenos esta semana: ${weeklyStats.currentWeekCount}/${weeklyStats.weeklyGoal}',
      );
    }

    _appendBodyMetrics(buffer, bodyMetrics, profile?.unitSystem ?? 'kg');
    _appendPersonalRecords(buffer, personalRecords, profile?.unitSystem ?? 'kg');
    _appendWorkouts(buffer, recentWorkouts, profile?.unitSystem ?? 'kg');
    _appendRoutines(buffer, routines);

    final text = buffer.toString().trim();
    return text.isEmpty ? 'Sin datos de perfil registrados aún.' : text;
  }

  static void _appendBodyMetrics(
    StringBuffer buffer,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
    String unitSystem,
  ) {
    if (bodyMetrics == null || bodyMetrics.isEmpty) return;

    final lines = <String>[];
    for (final def in BodyMetricDefinition.all) {
      final snap = bodyMetrics[def.key];
      if (snap == null || !snap.hasValue) continue;
      lines.add('- ${_metricLabel(def.key)}: ${_formatMetric(def, snap, unitSystem)}');
    }

    if (lines.isEmpty) return;
    buffer.writeln('\n=== MÉTRICAS CORPORALES ===');
    for (final line in lines) {
      buffer.writeln(line);
    }
  }

  static void _appendPersonalRecords(
    StringBuffer buffer,
    List<PersonalRecord>? records,
    String unitSystem,
  ) {
    if (records == null || records.isEmpty) return;

    buffer.writeln('\n=== RECORDS PERSONALES (top 12 por 1RM) ===');
    final sorted = [...records]..sort((a, b) => b.oneRepMax.compareTo(a.oneRepMax));
    for (final pr in sorted.take(12)) {
      buffer.writeln(
        '- ${pr.exerciseName}: ${UnitConverter.formatSetLine(pr.weight, pr.reps, unitSystem)} '
        '(1RM ~${UnitConverter.formatMass(pr.oneRepMax, unitSystem)})',
      );
    }
  }

  static void _appendWorkouts(
    StringBuffer buffer,
    List<Workout>? workouts,
    String unitSystem,
  ) {
    if (workouts == null || workouts.isEmpty) return;

    buffer.writeln('\n=== ÚLTIMOS ENTRENAMIENTOS ===');
    for (final w in workouts.take(5)) {
      buffer.writeln(
        '- ${w.name} (${w.durationMinutes} min, volumen: ${UnitConverter.formatVolume(w.totalVolume, unitSystem)})',
      );
      for (final ex in w.exercises.take(4)) {
        final sets = ex.sets
            .where((s) => s.completed && s.weight != null)
            .map((s) => UnitConverter.formatSetLine(s.weight!, s.reps, unitSystem))
            .join(', ');
        if (sets.isNotEmpty) {
          buffer.writeln('  ${ex.exerciseName}: $sets');
        }
      }
    }
  }

  static void _appendRoutines(StringBuffer buffer, List<Routine>? routines) {
    if (routines == null || routines.isEmpty) return;

    buffer.writeln('\n=== RUTINAS GUARDADAS ===');
    for (final r in routines.take(8)) {
      final muscles = r.targetMuscles.isEmpty ? '' : ' [${r.targetMuscles.join(', ')}]';
      final exerciseCount = r.exercises.length;
      buffer.writeln('- ${r.name}$muscles ($exerciseCount ejercicios)');
      if (r.description != null && r.description!.isNotEmpty) {
        buffer.writeln('  ${r.description}');
      }
    }
  }

  static String _formatMetric(
    BodyMetricDefinition def,
    BodyMetricSnapshot snap,
    String unitSystem,
  ) {
    switch (def.kind) {
      case BodyMetricKind.mass:
        return UnitConverter.formatMass(snap.valueKg, unitSystem);
      case BodyMetricKind.percent:
        return '${snap.rawValue!.toStringAsFixed(1)} %';
      case BodyMetricKind.score:
        if (def.key == 'bmi') {
          return snap.rawValue!.toStringAsFixed(1);
        }
        return snap.rawValue!.toStringAsFixed(0);
      case BodyMetricKind.kcal:
        return '${snap.rawValue!.toStringAsFixed(0)} kcal';
      case BodyMetricKind.years:
        return '${snap.rawValue!.toStringAsFixed(0)} años';
    }
  }

  static String _metricLabel(String key) {
    return switch (key) {
      'weight' => 'Peso',
      'bmi' => 'IMC',
      'body_fat' => 'Grasa corporal',
      'skeletal_muscle' => 'Músculo esquelético',
      'fat_free_mass' => 'Masa libre de grasa',
      'subcutaneous_fat' => 'Grasa subcutánea',
      'visceral_fat' => 'Grasa visceral',
      'body_water' => 'Agua corporal',
      'muscle_mass' => 'Masa muscular',
      'bone_mass' => 'Masa ósea',
      'protein' => 'Proteína',
      'bmr' => 'Tasa metabólica basal',
      'metabolic_age' => 'Edad metabólica',
      _ => key,
    };
  }

  static String _genderLabel(Gender? gender) {
    return switch (gender) {
      Gender.male => 'Masculino',
      Gender.female => 'Femenino',
      Gender.nonBinary => 'No binario',
      Gender.preferNotToSay => 'Prefiere no decir',
      null => 'no definido',
    };
  }

  static String _goalLabel(String? goal) {
    return switch (goal) {
      'Hipertrofia' || 'Hypertrophy' => 'Hipertrofia',
      'Fuerza' || 'Strength' => 'Fuerza',
      'Pérdida de grasa' || 'Fat loss' => 'Pérdida de grasa',
      'Resistencia' || 'Endurance' => 'Resistencia',
      'Mantenimiento' || 'Maintenance' => 'Mantenimiento',
      _ => goal ?? 'no definido',
    };
  }

  static String _experienceLabel(String? level) {
    return switch (level) {
      'principiante' || 'beginner' => 'Principiante',
      'intermedio' || 'intermediate' => 'Intermedio',
      'avanzado' || 'advanced' => 'Avanzado',
      _ => level ?? 'Intermedio',
    };
  }
}
