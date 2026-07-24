import '../../models/body_metric.dart';
import '../../models/coach_nutrition_snapshot.dart';
import '../../models/exercise_logging.dart';
import '../../models/food_entry.dart';
import '../../models/profile.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../../services/routine_limit_service.dart';
import 'ai_coach_routine_prompt.dart';
import 'cardio_format.dart';
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
    CoachNutritionSnapshot? nutrition,
    RoutineLimitStatus? routineLimit,
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
    _appendRoutineLimit(buffer, routineLimit, profile?.preferredLanguage ?? 'es');
    _appendNutrition(buffer, nutrition);

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

    buffer.writeln('\n=== RECORDS PERSONALES (top 12) ===');
    final sorted = [...records]
      ..sort((a, b) => _recordSortValue(b).compareTo(_recordSortValue(a)));
    for (final pr in sorted.take(12)) {
      if (pr.recordType == PersonalRecordType.strength) {
        buffer.writeln(
          '- ${pr.exerciseName}: ${UnitConverter.formatSetLine(pr.weight ?? 0, pr.reps, unitSystem)} '
          '(1RM ~${UnitConverter.formatMass(pr.oneRepMax ?? 0, unitSystem)})',
        );
      } else if (pr.recordType == PersonalRecordType.strengthMaxWeight) {
        buffer.writeln(
          '- ${pr.exerciseName}: ${UnitConverter.formatMass(pr.weight ?? 0, unitSystem)} '
          '(peso máx × ${pr.reps} reps)',
        );
      } else {
        buffer.writeln('- ${pr.exerciseName}: ${_cardioRecordLine(pr, unitSystem)}');
      }
    }
  }

  static double _recordSortValue(PersonalRecord pr) {
    switch (pr.recordType) {
      case PersonalRecordType.strength:
        return pr.oneRepMax ?? 0;
      case PersonalRecordType.strengthMaxWeight:
        return pr.weight ?? 0;
      case PersonalRecordType.cardioDistance:
        return pr.distanceMeters ?? 0;
      case PersonalRecordType.cardioDuration:
        return (pr.durationSeconds ?? 0).toDouble();
      case PersonalRecordType.cardioSteps:
        return (pr.steps ?? 0).toDouble();
      case PersonalRecordType.cardioIncline:
        return pr.inclinePercent ?? 0;
      case PersonalRecordType.cardioDifficulty:
        return pr.inclinePercent ?? 0;
    }
  }

  static String _cardioRecordLine(PersonalRecord pr, String unitSystem) {
    switch (pr.recordType) {
      case PersonalRecordType.cardioDistance:
        return 'distancia ${CardioFormat.distance(pr.distanceMeters, unitSystem)}';
      case PersonalRecordType.cardioDuration:
        return 'tiempo ${CardioFormat.duration(pr.durationSeconds)}';
      case PersonalRecordType.cardioSteps:
        return '${pr.steps ?? 0} pasos';
      case PersonalRecordType.cardioIncline:
        return 'inclinación ${CardioFormat.incline(pr.inclinePercent)}';
      case PersonalRecordType.cardioDifficulty:
        return 'dificultad ${CardioFormat.difficulty(pr.inclinePercent)}';
      case PersonalRecordType.strength:
      case PersonalRecordType.strengthMaxWeight:
        return '';
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

  static void _appendRoutineLimit(
    StringBuffer buffer,
    RoutineLimitStatus? status,
    String languageCode,
  ) {
    if (status == null) return;
    buffer.writeln(
      AiCoachRoutinePrompt.buildRoutineLimitSection(
        status: status,
        languageCode: languageCode,
      ),
    );
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

  static void _appendNutrition(StringBuffer buffer, CoachNutritionSnapshot? nutrition) {
    if (nutrition == null) return;

    final today = nutrition.today;
    final loaded = nutrition.loadedAt.toLocal();
    final timeLabel =
        '${loaded.hour.toString().padLeft(2, '0')}:${loaded.minute.toString().padLeft(2, '0')}';

    buffer.writeln('\n=== NUTRICIÓN HOY (tiempo real, actualizado $timeLabel) ===');
    _appendDayNutritionSummary(buffer, today, detailed: true);

    buffer.writeln('\n=== HISTORIAL NUTRICIONAL (últimos 7 días) ===');
    var daysWithLogs = 0;
    var totalKcal = 0;
    var totalProtein = 0.0;
    var totalCarbs = 0.0;
    var totalFat = 0.0;

    for (final day in nutrition.weekHistory) {
      final hasLogs = day.caloriesEaten > 0;
      if (hasLogs) {
        daysWithLogs++;
        totalKcal += day.caloriesEaten;
        totalProtein += day.eaten.proteinG;
        totalCarbs += day.eaten.carbsG;
        totalFat += day.eaten.fatG;
      }

      final label = _dayLabel(day.day);
      if (!hasLogs) {
        buffer.writeln('- $label: sin registros');
        continue;
      }

      final mealCount = day.entriesByMeal.values.fold<int>(0, (sum, list) => sum + list.length);
      buffer.writeln(
        '- $label: ${day.caloriesEaten} kcal '
        '(P ${day.eaten.proteinG.toStringAsFixed(0)}g, '
        'C ${day.eaten.carbsG.toStringAsFixed(0)}g, '
        'G ${day.eaten.fatG.toStringAsFixed(0)}g) — $mealCount comidas',
      );
    }

    if (daysWithLogs > 0) {
      final avgKcal = (totalKcal / daysWithLogs).round();
      buffer.writeln(
        'Promedio en días con registro ($daysWithLogs/7): '
        '$avgKcal kcal/día | '
        'P ${(totalProtein / daysWithLogs).toStringAsFixed(0)}g | '
        'C ${(totalCarbs / daysWithLogs).toStringAsFixed(0)}g | '
        'G ${(totalFat / daysWithLogs).toStringAsFixed(0)}g',
      );
    } else {
      buffer.writeln('Sin registros nutricionales en la última semana.');
    }
  }

  static void _appendDayNutritionSummary(
    StringBuffer buffer,
    DailyNutritionSummary summary, {
    required bool detailed,
  }) {
    if (summary.caloriesEaten == 0 && summary.entriesByMeal.values.every((e) => e.isEmpty)) {
      buffer.writeln('Sin comidas registradas hoy todavía.');
      if (summary.bmrAvailable) {
        buffer.writeln(
          'Presupuesto estimado del día: ${summary.calorieBudget} kcal '
          '(base ${summary.baseCalorieGoal} kcal'
          '${summary.totalCaloriesBurned > 0 ? ' + ${summary.totalCaloriesBurned} kcal actividad' : ''}).',
        );
      }
      return;
    }

    buffer.writeln(
      'Presupuesto: ${summary.calorieBudget} kcal '
      '(base ${summary.baseCalorieGoal}'
      '${summary.workoutCaloriesBurned > 0 ? ' + ${summary.workoutCaloriesBurned} entreno' : ''}'
      '${summary.manualActivityCaloriesBurned > 0 ? ' + ${summary.manualActivityCaloriesBurned} actividad manual' : ''})',
    );
    buffer.writeln(
      'Consumido: ${summary.caloriesEaten} kcal | '
      '${summary.isCaloricSurplus ? 'Superávit: ${summary.caloriesSurplus} kcal' : 'Restante: ${summary.caloriesRemaining} kcal'}',
    );
    buffer.writeln(
      'Macros vs objetivo: '
      'P ${summary.eaten.proteinG.toStringAsFixed(0)}/${summary.targets.proteinG.toStringAsFixed(0)}g, '
      'C ${summary.eaten.carbsG.toStringAsFixed(0)}/${summary.targets.carbsG.toStringAsFixed(0)}g, '
      'G ${summary.eaten.fatG.toStringAsFixed(0)}/${summary.targets.fatG.toStringAsFixed(0)}g, '
      'Fibra ${summary.eaten.fiberG.toStringAsFixed(0)}/${summary.targets.fiberG.toStringAsFixed(0)}g',
    );

    if (!detailed) return;

    for (final meal in MealType.values) {
      final entries = summary.entriesByMeal[meal] ?? const [];
      if (entries.isEmpty) continue;

      final mealTotals = summary.eatenForMeal(meal);
      buffer.writeln('\n${_mealLabel(meal)} (${mealTotals.caloriesKcal} kcal):');
      for (final entry in entries) {
        final portion = entry.servingDescription != null && entry.servingDescription!.isNotEmpty
            ? ' — ${entry.servingDescription}'
            : '';
        buffer.writeln(
          '- ${entry.name}$portion: ${entry.caloriesKcal} kcal '
          '(P${entry.proteinG.toStringAsFixed(0)} C${entry.carbsG.toStringAsFixed(0)} G${entry.fatG.toStringAsFixed(0)})',
        );
      }
    }
  }

  static String _dayLabel(DateTime day) {
    const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final local = day.toLocal();
    final weekday = weekdays[local.weekday - 1];
    final date =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
    return '$weekday $date';
  }

  static String _mealLabel(MealType meal) {
    return switch (meal) {
      MealType.breakfast => 'Desayuno',
      MealType.lunch => 'Comida',
      MealType.dinner => 'Cena',
      MealType.snack => 'Snack',
    };
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
      'bmr' => 'Tasa metabólica basal',
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
