// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'FitForge';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get notDefined => 'No definido';

  @override
  String get user => 'Usuario';

  @override
  String errorGeneric(String message) {
    return 'Error: $message';
  }

  @override
  String get enterValue => 'Ingresa el valor';

  @override
  String get years => 'años';

  @override
  String get loading => 'Cargando…';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get apply => 'Aplicar';

  @override
  String get generate => 'Generar';

  @override
  String get close => 'Cerrar';

  @override
  String get share => 'Compartir';

  @override
  String get view => 'Ver';

  @override
  String get active => 'Activo';

  @override
  String get minutes => 'min';

  @override
  String minSuffix(int n) {
    return '$n min';
  }

  @override
  String get navWorkout => 'Entreno';

  @override
  String get navTrain => 'Entrenar';

  @override
  String get navRoutines => 'Rutinas';

  @override
  String get trainTabToday => 'Entrenamiento';

  @override
  String get trainTabRoutines => 'Rutinas';

  @override
  String get navCoach => 'Coach';

  @override
  String get navFood => 'Comida';

  @override
  String get navProgress => 'Progreso';

  @override
  String get navSocial => 'Social';

  @override
  String get navStudents => 'Alumnos';

  @override
  String get navProfile => 'Perfil';

  @override
  String get coachAi => 'Coach IA';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileDedication =>
      'Esta app nunca hubiera existido sin la motivación de mis hermanos Diego y Rodrigo, que me inspiraron a buscar un estilo de vida más saludable, LIGHT WEIGHT BABY!';

  @override
  String get personalData => 'Datos personales';

  @override
  String get profileOnboardingTitle => 'Completa tu perfil';

  @override
  String get profileOnboardingSubtitle =>
      'Necesitamos estos datos para personalizar entrenamientos, nutrición y progreso.';

  @override
  String get profileOnboardingNickname => 'Nombre o apodo';

  @override
  String get profileOnboardingContinue => 'Continuar';

  @override
  String get weightUpdateTitle => 'Actualiza tu peso';

  @override
  String get weightUpdateMessage =>
      'Han pasado más de 15 días desde tu último registro. Actualiza tu peso para mantener tus métricas precisas.';

  @override
  String get weightUpdateSave => 'Guardar peso';

  @override
  String get weightInvalid => 'Indica un peso válido';

  @override
  String get genderRequired => 'Selecciona tu género';

  @override
  String get heightInvalid => 'Indica una altura válida (50–280 cm)';

  @override
  String get ageInvalid => 'Indica una edad válida (13–119 años)';

  @override
  String get displayName => 'Nombre';

  @override
  String get displayNameTitle => 'Tu nombre';

  @override
  String get displayNameRequired => 'Escribe un nombre';

  @override
  String get age => 'Edad';

  @override
  String get gender => 'Género';

  @override
  String get height => 'Altura';

  @override
  String get preferredLanguage => 'Idioma preferido';

  @override
  String get unitSystem => 'Sistema de unidades';

  @override
  String get accentColor => 'Color de acento';

  @override
  String get accentColorHint => 'Personaliza el color principal de la app';

  @override
  String get accentGold => 'Dorado';

  @override
  String get accentOrange => 'Naranja';

  @override
  String get accentCobalt => 'Azul';

  @override
  String get accentViolet => 'Violeta';

  @override
  String get accentEmerald => 'Verde';

  @override
  String get accentRose => 'Rosado';

  @override
  String get accentCrimson => 'Carmesí';

  @override
  String get kilograms => 'Kilogramos';

  @override
  String get pounds => 'Libras';

  @override
  String get bodyMetrics => 'Métricas corporales';

  @override
  String get trainingConfig => 'Configuración de entrenamiento';

  @override
  String get personalTrainerMode => 'Modo entrenador personal';

  @override
  String get personalTrainerModeSubtitle =>
      'Activa la pestaña Alumnos para monitorear clientes';

  @override
  String get personalTrainerModeEnabled =>
      'Modo entrenador activado. Pestaña Alumnos disponible.';

  @override
  String get personalTrainerModeDisabled => 'Modo entrenador desactivado.';

  @override
  String personalTrainerModeFailed(String message) {
    return 'No se pudo cambiar el modo: $message';
  }

  @override
  String get trainerModeRequired =>
      'Activa el modo entrenador personal en tu Perfil para usar esta sección.';

  @override
  String get studentsScreenHint =>
      'Envía una solicitud a tus amigos para agregarlos como alumnos. Solo verás sus datos cuando la acepten.';

  @override
  String studentsCount(int count) {
    return 'Alumnos ($count)';
  }

  @override
  String get studentsEmpty =>
      'Aún no tienes alumnos. Envía una solicitud a tus amigos desde la lista de abajo.';

  @override
  String get addStudentFromFriends => 'Agregar desde amigos';

  @override
  String get addStudentEmpty =>
      'No hay amigos disponibles. Primero deben ser amigos aceptados.';

  @override
  String get addStudentAction => 'Agregar alumno';

  @override
  String get sendStudentRequestAction => 'Enviar solicitud';

  @override
  String get studentAdded => 'Alumno agregado';

  @override
  String get studentRequestSent =>
      'Solicitud enviada. El alumno debe aceptarla.';

  @override
  String get studentRequestCanceled => 'Solicitud cancelada';

  @override
  String get studentRequestsSentSection => 'Solicitudes enviadas';

  @override
  String get studentRequestPendingLabel => 'Pendiente de aprobación';

  @override
  String get trainerRequestAccepted =>
      'Solicitud aceptada. Ahora tienes un entrenador.';

  @override
  String get trainerRequestDeclined => 'Solicitud rechazada';

  @override
  String addStudentFailed(String message) {
    return 'No se pudo agregar: $message';
  }

  @override
  String get removeStudentTitle => 'Quitar alumno';

  @override
  String removeStudentMessage(String name) {
    return '¿Quitar a $name de tus alumnos?';
  }

  @override
  String get removeStudentAction => 'Eliminar alumno';

  @override
  String get studentDetailTitle => 'Alumno';

  @override
  String get studentNotFound => 'Alumno no encontrado';

  @override
  String get studentRecoveryTitle => 'Recuperación muscular';

  @override
  String get studentNutritionTitle => 'Nutrición de hoy';

  @override
  String studentNutritionTitleDate(String date) {
    return 'Nutrición del $date';
  }

  @override
  String get studentWorkoutsTitle => 'Entrenos recientes';

  @override
  String get studentWorkoutsEmpty =>
      'Este alumno aún no ha registrado entrenos completados.';

  @override
  String get studentRoutinesTitle => 'Rutinas del alumno';

  @override
  String get studentRoutinesEmpty => 'Este alumno aún no tiene rutinas.';

  @override
  String get studentRoutineNew => 'Nueva rutina para alumno';

  @override
  String get studentRoutineEdit => 'Editar rutina del alumno';

  @override
  String get deleteRoutineTitle => 'Eliminar rutina';

  @override
  String deleteRoutineMessage(String name) {
    return '¿Eliminar la rutina \"$name\"?';
  }

  @override
  String get goal => 'Objetivo';

  @override
  String get experienceLevel => 'Nivel de experiencia';

  @override
  String get activityLevel => 'Actividad fuera del gym';

  @override
  String get activityLevelTitle => 'Actividad diaria aparte del gym';

  @override
  String get activityLevelHint =>
      'Tu rutina diaria sin contar entrenamientos de fuerza ni cardio';

  @override
  String get activitySedentary => 'Sedentario';

  @override
  String get activityModerate => 'Moderado';

  @override
  String get activityHigh => 'Alto';

  @override
  String get activitySedentaryDescription => 'Menos de 4 mil pasos diarios';

  @override
  String get activityModerateDescription =>
      'Entre 4 mil y 10 mil pasos diarios';

  @override
  String get activityHighDescription => 'Más de 10 mil pasos diarios';

  @override
  String get activityLevelFootnote =>
      'Estas son aproximaciones de actividad física para ayudar a orientar al usuario.';

  @override
  String get restTimerAlert => 'Aviso de descanso';

  @override
  String get restTimerAlertTitle => 'Fin del descanso';

  @override
  String get restTimerAlertSound => 'Sonido';

  @override
  String get restTimerAlertVibration => 'Vibración';

  @override
  String get restTimerAlertBoth => 'Sonido y vibración';

  @override
  String get aiSection => 'Inteligencia artificial';

  @override
  String get apiKeys => 'API Keys (OpenAI / Gemini)';

  @override
  String apiKeysConfigured(String provider) {
    return 'Configurado ($provider)';
  }

  @override
  String get apiKeysNotConfigured => 'No configurado';

  @override
  String get advancedSettings => 'Ajustes avanzados';

  @override
  String get advancedSettingsHint => 'Opciones para usuarios con experiencia';

  @override
  String get bringYourOwnAi => 'Conectar tu cuenta de IA';

  @override
  String get bringYourOwnAiSubtitle =>
      'Usa tu propia cuenta de OpenAI, Gemini o Claude';

  @override
  String get apiKeysNotAvailableOnPaidPlan =>
      'Tu plan ya incluye IA — no necesitas una API key propia';

  @override
  String get featureGymratPlansOnly => 'Solo para usuarios Gymrat y Gymrat Pro';

  @override
  String get featureGymratProOnly => 'Solo para usuarios Gymrat Pro';

  @override
  String get subscriptionTierGymrat => 'Gymrat';

  @override
  String get subscriptionTierGymratPro => 'Gymrat Pro';

  @override
  String get hyroxMode => 'Modo Hyrox';

  @override
  String get hyroxModeSubtitle =>
      'Añade 3 rutinas progresivas (Prep → Build → Race). No cuentan en tu límite de rutinas.';

  @override
  String get hyroxModeEnabled =>
      'Modo Hyrox activado · 3 rutinas listas en Rutinas';

  @override
  String get hyroxModeDisabled =>
      'Modo Hyrox desactivado · rutinas Hyrox eliminadas';

  @override
  String get hyroxRoutinePrepName => 'Hyrox 1 · Preparación';

  @override
  String get hyroxRoutineBuildName => 'Hyrox 2 · Progresión';

  @override
  String get hyroxRoutineRaceName => 'Hyrox 3 · Día de carrera';

  @override
  String get hyroxRoutinePrepSubtitle =>
      'Fundamentos Hyrox (~50% distancias oficiales). Enfócate en técnica y ritmo.';

  @override
  String get hyroxRoutineBuildSubtitle =>
      'Volumen intermedio (~75%). Acerca cargas y splits al ritmo de carrera.';

  @override
  String get hyroxRoutineRaceSubtitle =>
      'Simulación Race Day a estándares oficiales (100%). Cronometra cada fase.';

  @override
  String get runnerMode => 'Modo runner';

  @override
  String get runnerModeSubtitle =>
      'Añade Salir a correr (GPS) y Correr en cinta. No cuentan en tu límite de rutinas.';

  @override
  String get runnerModeEnabled =>
      'Modo runner activado · 2 rutinas listas en Rutinas';

  @override
  String get runnerModeDisabled =>
      'Modo runner desactivado · rutinas runner eliminadas';

  @override
  String get runnerSystemBadge => 'Runner';

  @override
  String get runnerSystemLocked =>
      'Rutina del sistema runner · no se puede editar ni eliminar';

  @override
  String get runnerStart => 'Iniciar';

  @override
  String get runnerStartOutdoor => 'Salir a correr';

  @override
  String get runnerStartTreadmill => 'Correr en cinta';

  @override
  String get runnerRoutineOutdoorSubtitle =>
      'Carrera outdoor con GPS, ritmo, splits y desnivel.';

  @override
  String get runnerRoutineTreadmillSubtitle =>
      'Carrera en cinta con inclinación, distancia y ritmo.';

  @override
  String get runnerSurfaceTitle => '¿Dónde vas a correr?';

  @override
  String get runnerSurfaceHint =>
      'Esto ayuda a contextualizar tu sesión en el historial.';

  @override
  String get runnerSurfaceAsphalt => 'Asfalto / calle';

  @override
  String get runnerSurfaceAsphaltDesc =>
      'Carretera, aceras urbanas o paseos pavimentados.';

  @override
  String get runnerSurfaceTrack => 'Pista';

  @override
  String get runnerSurfaceTrackDesc =>
      'Pista de atletismo o superficie sintética uniforme.';

  @override
  String get runnerSurfaceTrail => 'Trail / sendero';

  @override
  String get runnerSurfaceTrailDesc => 'Tierra, montaña o terreno irregular.';

  @override
  String get runnerAcquiringGps => 'Obteniendo señal GPS…';

  @override
  String get runnerGpsDenied =>
      'Activa la ubicación y concede permisos para registrar tu carrera.';

  @override
  String get runnerNoDistance =>
      'No se registró distancia. Espera unos segundos con GPS activo o muévete un poco más.';

  @override
  String get runnerTime => 'Tiempo';

  @override
  String get runnerDistance => 'Distancia';

  @override
  String get runnerPace => 'Ritmo';

  @override
  String get runnerPause => 'Pausar';

  @override
  String get runnerResume => 'Reanudar';

  @override
  String get runnerFinish => 'Finalizar';

  @override
  String get runnerSplitsTitle => 'Splits por km';

  @override
  String runnerSplitKm(int km) {
    return 'Km $km';
  }

  @override
  String get runnerInclineLabel => 'Inclinación de la cinta';

  @override
  String get runnerInclineHelper => '0% si está plana';

  @override
  String get runnerInclineRequired => 'Indica la inclinación (puede ser 0%)';

  @override
  String get runnerTreadmillHint =>
      'Pulsa iniciar cuando estés en la cinta. Al terminar, indica inclinación y distancia.';

  @override
  String get runnerSummaryTitle => 'Resumen de carrera';

  @override
  String get runnerRouteTitle => 'Ruta';

  @override
  String get runnerAvgPace => 'Ritmo medio';

  @override
  String get runnerElevationLabel => 'Desnivel';

  @override
  String get runnerElevationGain => 'Elevación +';

  @override
  String get runnerElevationLoss => 'Elevación −';

  @override
  String get runnerAutoStartHint =>
      '¡A correr! El cronómetro y las métricas iniciarán solas al detectar movimiento.';

  @override
  String get hyroxSystemBadge => 'Hyrox';

  @override
  String get hyroxSystemLocked =>
      'Rutina sistema Hyrox. Desactiva el modo Hyrox en Perfil para quitarla.';

  @override
  String hyroxPhaseTimer(int phase, int total) {
    return 'Fase $phase/$total';
  }

  @override
  String get hyroxPhaseSplit => 'Split de fase';

  @override
  String hyroxTargetDistance(int meters) {
    return 'Objetivo: $meters m';
  }

  @override
  String get hyroxStationDone => 'Hecho';

  @override
  String get hyroxStartRace => 'Iniciar';

  @override
  String get hyroxReadyToStart =>
      'Pulsa Iniciar cuando estés listo. El cronómetro global arranca al darle.';

  @override
  String get hyroxStationCompleted => 'Completado';

  @override
  String get hyroxStationFixedHint => 'Peso y distancia fijos (estándar Hyrox)';

  @override
  String get hyroxSplitsSummaryTitle => 'Tiempos por estación';

  @override
  String get leaderboardMetricHyrox => 'Hyrox Race';

  @override
  String get aiCoachSubtitle => 'Recomendaciones personalizadas';

  @override
  String get proactiveAi => 'IA proactiva';

  @override
  String get proactiveAiSubtitleOff => 'La IA solo responde cuando le escribes';

  @override
  String get proactiveAiSubtitleOn => 'Activada · puede consumir más tokens';

  @override
  String get proactiveAiEnableTitle => '¿Activar IA proactiva?';

  @override
  String get proactiveAiEnableMessage =>
      'FitForge podrá usar tu API key para enviarte sugerencias sin que las pidas. Esto puede aumentar el consumo de tokens.';

  @override
  String get proactiveAiEnableConfirm => 'Activar';

  @override
  String get aiCalculatingWorkoutSuggestions => 'Calculando sugerencias de IA…';

  @override
  String get aiWorkoutSuggestionsApplied =>
      'Series sugeridas por IA según tu historial y objetivo';

  @override
  String get fitnessGoalTitle => 'Objetivo fitness';

  @override
  String get fitnessGoalHint =>
      'Tu objetivo ajusta cómo la IA programa tus entrenos y tu objetivo calórico diario.';

  @override
  String get fitnessGoalTrainingLabel => 'Entreno';

  @override
  String get fitnessGoalDietLabel => 'Dieta';

  @override
  String get goalHypertrophyTraining =>
      '3-5 series de trabajo, 8-12 reps, progresión de peso y volumen. Compuestos + aislamiento.';

  @override
  String get goalHypertrophyDiet =>
      'Ligero superávit calórico (+8%), ~2 g de proteína por kg de peso.';

  @override
  String get goalStrengthTraining =>
      '3-6 series, 3-6 reps con cargas altas. Aproximaciones en levantamientos compuestos.';

  @override
  String get goalStrengthDiet =>
      'Superávit moderado (+8%), alta proteína (~2 g/kg) para recuperación y fuerza.';

  @override
  String get goalFatLossTraining =>
      '2-4 series, 12-20 reps, descansos cortos. Prioriza volumen y densidad de entreno.';

  @override
  String get goalFatLossDiet =>
      'Déficit calórico (~15%), proteína alta (~2,2 g/kg) para preservar músculo.';

  @override
  String get goalEnduranceTraining =>
      '2-3 series, 15+ reps o cardio por tiempo/distancia. Menos carga, más repeticiones.';

  @override
  String get goalEnduranceDiet =>
      'Calorías de mantenimiento, macros equilibrados (~1,6 g proteína/kg).';

  @override
  String get goalMaintenanceTraining =>
      'Respeta tu historial reciente, sin forzar progresión agresiva.';

  @override
  String get goalMaintenanceDiet =>
      'Calorías de mantenimiento (TDEE), macros equilibrados (~1,6 g proteína/kg).';

  @override
  String get fitnessGoalFootnote =>
      'La IA proactiva y tu presupuesto calórico usan este objetivo. Puedes cambiarlo cuando quieras.';

  @override
  String get experienceTitle => 'Nivel de experiencia';

  @override
  String get genderMale => 'Masculino';

  @override
  String get genderFemale => 'Femenino';

  @override
  String get genderNonBinary => 'No binario';

  @override
  String get genderPreferNotSay => 'Prefiero no decir';

  @override
  String get genderTitle => 'Género';

  @override
  String get ageTitle => 'Edad';

  @override
  String get heightTitle => 'Altura';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageEs => 'Español';

  @override
  String get languageEn => 'English';

  @override
  String get feet => 'Pies';

  @override
  String get inches => 'Pulgadas';

  @override
  String get goalHypertrophy => 'Hipertrofia';

  @override
  String get goalStrength => 'Fuerza';

  @override
  String get goalFatLoss => 'Pérdida de grasa';

  @override
  String get goalEndurance => 'Resistencia';

  @override
  String get goalMaintenance => 'Mantenimiento';

  @override
  String get expBeginner => 'principiante';

  @override
  String get expIntermediate => 'intermedio';

  @override
  String get expAdvanced => 'avanzado';

  @override
  String get progressTitle => 'Progreso';

  @override
  String get progressMyTrainerLabel => 'Tu entrenador personal';

  @override
  String progressTotalXp(int total) {
    return '$total XP totales';
  }

  @override
  String progressXpToNext(int remaining, int level) {
    return 'Faltan $remaining XP para nivel $level';
  }

  @override
  String get progressStatsNewPrs => 'PRs nuevos';

  @override
  String get progressStatsMonthlyWorkouts => 'Entrenos del mes';

  @override
  String get progressStatsMonthlyVolume => 'Volumen del mes';

  @override
  String get progressStatsMonthlyPrs => 'PRs del mes';

  @override
  String progressStreakWeeks(int count) {
    return '$count sem';
  }

  @override
  String get progressRecentPrs => 'PRs recientes';

  @override
  String get progressAllRecords => 'Todos los récords';

  @override
  String get progressNewPrBadge => 'Nuevo';

  @override
  String get progressVolumeTrend => 'Tendencia de volumen';

  @override
  String get progressBodyTitle => 'Cuerpo';

  @override
  String progressMilestoneNext(String target) {
    return 'Siguiente: $target';
  }

  @override
  String playerLevelTitle(int level) {
    return 'Nivel $level';
  }

  @override
  String playerXpProgress(int current, int total) {
    return '$current / $total XP';
  }

  @override
  String get playerLevelMax => 'Nivel máximo alcanzado';

  @override
  String get playerLevelTierMythic => 'Mítico';

  @override
  String get playerLevelTierImmortal => 'Inmortal';

  @override
  String xpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String get levelUp => '¡Subiste de nivel!';

  @override
  String get rankUp => '¡Nuevo rango!';

  @override
  String shareRankUp(String rank, int level) {
    return '⭐ ¡Ascendiste a $rank! (Nivel $level)';
  }

  @override
  String streakXpBonus(String multiplier) {
    return 'Bonus racha ×$multiplier';
  }

  @override
  String get workouts30d => 'Entrenos (30 d)';

  @override
  String get volume30d => 'Volumen (30 d)';

  @override
  String get progressLast7Days => 'Últimos 7 días';

  @override
  String get progressAllTime => 'Histórico';

  @override
  String get progressWorkoutsLabel => 'Entrenos';

  @override
  String get progressVolumeLabel => 'Volumen';

  @override
  String get progressCaloriesLabel => 'Calorías';

  @override
  String get volumePerWorkout => 'Volumen por día';

  @override
  String get last10Days => 'Últimos 10 días';

  @override
  String get completeWorkoutsForVolume =>
      'Completa entrenamientos para ver tu volumen';

  @override
  String get milestonesTitle => 'Medallas';

  @override
  String get milestonesSubtitle =>
      'Desbloquea medallas al alcanzar metas acumuladas';

  @override
  String get milestoneCategoryReps => 'Reps';

  @override
  String get milestoneCategoryVolume => 'Volumen';

  @override
  String get milestoneCategoryDistance => 'Distancia';

  @override
  String get milestoneCategoryCalories => 'Calorías';

  @override
  String get milestoneCategoryWorkouts => 'Entrenos';

  @override
  String milestoneTotal(String value) {
    return 'Total: $value';
  }

  @override
  String milestoneUnlockedCount(int unlocked, int total) {
    return '$unlocked/$total';
  }

  @override
  String milestoneNextTarget(String target) {
    return 'Siguiente meta: $target';
  }

  @override
  String milestoneDetailRemaining(String remaining, String target) {
    return 'Faltan $remaining para $target';
  }

  @override
  String get milestoneAllUnlocked => '¡Todas las medallas desbloqueadas!';

  @override
  String get milestoneTierBronze => 'Bronce';

  @override
  String get milestoneTierSilver => 'Plata';

  @override
  String get milestoneTierGold => 'Oro';

  @override
  String get milestoneTierPlatinum => 'Platino';

  @override
  String get milestoneTierDiamond => 'Diamante';

  @override
  String get milestoneTierMaster => 'Maestro';

  @override
  String get milestoneTierGrandmaster => 'Gran maestro';

  @override
  String get milestoneTierLegend => 'Leyenda';

  @override
  String get personalRecords => 'Records personales';

  @override
  String get all => 'Todos';

  @override
  String get noRecordsYet => 'Completa entrenamientos para registrar PRs';

  @override
  String noRecordsForMuscle(String muscle) {
    return 'Sin records para $muscle';
  }

  @override
  String get oneRm => '1RM';

  @override
  String get exercisesTitle => 'Ejercicios';

  @override
  String get searchExercises => 'Buscar ejercicios…';

  @override
  String exerciseCount(int count) {
    return '$count ejercicios';
  }

  @override
  String get allCategories => 'Todas';

  @override
  String get exerciseNotFound => 'Ejercicio no encontrado';

  @override
  String get exerciseDetailTitle => 'Ejercicio';

  @override
  String get instructions => 'Instrucciones';

  @override
  String get watchDemoVideo => 'Ver video demostrativo';

  @override
  String get fitforgeCatalog => 'Ejercicio del catálogo FitForge';

  @override
  String get customExerciseTag => 'Personalizado';

  @override
  String get customExerciseAttribution =>
      'Ejercicio creado por ti en este dispositivo';

  @override
  String get createCustomExercise => 'Crear ejercicio personalizado';

  @override
  String get myCustomExercises => 'Mis ejercicios';

  @override
  String get customExerciseName => 'Nombre del ejercicio';

  @override
  String get customExerciseMuscles => 'Músculos trabajados';

  @override
  String get customExercisePhoto => 'Foto de la máquina (opcional)';

  @override
  String get takePhoto => 'Tomar foto';

  @override
  String get chooseFromGallery => 'Galería';

  @override
  String get customExerciseSaved => 'Ejercicio personalizado guardado';

  @override
  String get customExerciseDeleted => 'Ejercicio personalizado eliminado';

  @override
  String get deleteCustomExercise => 'Eliminar ejercicio';

  @override
  String get deleteCustomExerciseConfirm =>
      '¿Eliminar este ejercicio personalizado? Las rutinas guardadas conservarán el nombre.';

  @override
  String get customExerciseNameRequired =>
      'Escribe un nombre para el ejercicio';

  @override
  String get customExerciseMusclesRequired => 'Selecciona al menos un músculo';

  @override
  String get customExerciseLimitReached =>
      'Límite de ejercicios personalizados alcanzado (100)';

  @override
  String get customExercisePerArmWeight => 'Peso por brazo';

  @override
  String get customExercisePerArmWeightHint =>
      'Registra el peso de cada mancuerna o lado. El volumen suma ambos brazos (×2).';

  @override
  String weightPerArm(String unit) {
    return '$unit (por brazo)';
  }

  @override
  String get wgerAttribution => 'Imágenes y videos de wger.de (CC-BY-SA)';

  @override
  String get loadingImage => 'Cargando imagen…';

  @override
  String get metricWeight => 'Peso';

  @override
  String get metricBmi => 'Índice de masa corporal';

  @override
  String get metricBodyFat => 'Grasa corporal';

  @override
  String get metricSkeletalMuscle => 'Músculo esquelético';

  @override
  String get metricFatFreeMass => 'Peso corporal sin grasa';

  @override
  String get metricSubcutaneousFat => 'Grasa subcutánea';

  @override
  String get metricVisceralFat => 'Grasa visceral';

  @override
  String get metricBodyWater => 'Agua corporal';

  @override
  String get metricMuscleMass => 'Masa muscular';

  @override
  String get metricBoneMass => 'Masa ósea';

  @override
  String get metricProtein => 'Proteína';

  @override
  String get metricBmr => 'Tasa metabólica basal';

  @override
  String get metricCalculatedAutomatically => 'Calculado automáticamente';

  @override
  String get bodyMetricColorLegendTitle => 'Leyenda de colores';

  @override
  String get bodyMetricColorLegendNote =>
      'Aplica a peso, IMC, grasa corporal y grasa subcutánea.';

  @override
  String get bodyMetricHealthVeryLow => 'Muy bajo';

  @override
  String get bodyMetricHealthLow => 'Bajo';

  @override
  String get bodyMetricHealthAppropriate => 'Adecuado';

  @override
  String get bodyMetricHealthIdeal => 'Ideal';

  @override
  String get bodyMetricHealthHigh => 'Alto';

  @override
  String get bodyMetricHealthVeryBad => 'Muy alto';

  @override
  String get metricMetabolicAge => 'Edad metabólica';

  @override
  String get muscleChest => 'Pecho';

  @override
  String get muscleBack => 'Espalda';

  @override
  String get muscleShoulders => 'Hombros';

  @override
  String get muscleBiceps => 'Bíceps';

  @override
  String get muscleTriceps => 'Tríceps';

  @override
  String get muscleLegs => 'Piernas';

  @override
  String get muscleGlutes => 'Glúteos';

  @override
  String get muscleAbs => 'Abdominales';

  @override
  String get muscleForearms => 'Antebrazos';

  @override
  String get muscleCardio => 'Cardio';

  @override
  String get muscleCalves => 'Pantorrillas';

  @override
  String get workoutTitle => 'Entreno';

  @override
  String get routinesTitle => 'Rutinas';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get socialTitle => 'Social';

  @override
  String get socialHeroTitle => 'Tu círculo';

  @override
  String get socialHeroSubtitle => 'Entrenad juntos, subid de nivel';

  @override
  String socialHeroFriends(int count) {
    return '$count amigos';
  }

  @override
  String socialHeroPending(int count) {
    return '$count pendientes';
  }

  @override
  String socialHeroRank(int rank) {
    return '#$rank entre amigos';
  }

  @override
  String socialHeroRankGlobal(int rank) {
    return '#$rank global';
  }

  @override
  String get socialHeroNoRank => 'Compite con tus amigos';

  @override
  String get socialTabFriends => 'Amigos';

  @override
  String get socialTabFeed => 'Feed';

  @override
  String get socialTabLeaderboards => 'Clasificaciones';

  @override
  String get feedEmptyTitle => 'Tu feed está vacío';

  @override
  String get feedEmptySubtitle =>
      'Cuando tú o tus amigos entrenen, suban de nivel o desbloqueen medallas, lo verás aquí. Las publicaciones duran 24 horas.';

  @override
  String get feedExpiryHint =>
      'Solo se muestran publicaciones de las últimas 24 horas.';

  @override
  String get feedLongPressToReact =>
      'Mantén pulsado una publicación para reaccionar.';

  @override
  String feedMilestoneUnlock(String name, String category, String tier) {
    return '$name desbloqueó medalla $category — $tier';
  }

  @override
  String feedLevelUp(String name, int level) {
    return '$name subió al nivel $level';
  }

  @override
  String feedPrUnlock(String name, String exercise, String value) {
    return '$name batió un récord en $exercise: $value';
  }

  @override
  String feedPrUnlockSelf(String exercise, String value) {
    return 'Batiste un récord en $exercise: $value';
  }

  @override
  String feedMilestoneUnlockSelf(String category, String tier) {
    return 'Desbloqueaste la medalla $category — $tier';
  }

  @override
  String feedLevelUpSelf(int level) {
    return 'Subiste al nivel $level';
  }

  @override
  String feedWorkoutCompletedSelf(String workout) {
    return 'Completaste \"$workout\"';
  }

  @override
  String get feedSharePrTitle => 'Compartir en el feed';

  @override
  String get feedSharePrSubtitle =>
      'Elige qué récords quieren ver tus amigos. Se publican al cerrar.';

  @override
  String feedPrShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count récords compartidos en el feed de tus amigos',
      one: '1 récord compartido en el feed de tus amigos',
    );
    return '$_temp0';
  }

  @override
  String get feedPrShareFailed =>
      'No se pudo compartir en el feed. Inténtalo de nuevo.';

  @override
  String get leaderboardLoadMore => 'Ver más';

  @override
  String get leaderboardsTitle => 'Clasificaciones';

  @override
  String get leaderboardScopeFriends => 'Amigos';

  @override
  String get leaderboardScopeGlobal => 'Global';

  @override
  String get leaderboardMetricLevel => 'Nivel';

  @override
  String get leaderboardEmpty => 'Aún no hay datos en este ranking.';

  @override
  String get leaderboardYourPosition => 'Tu posición';

  @override
  String get leaderboardPeriodWeek => 'Semana';

  @override
  String get leaderboardPeriodMonth => 'Mes';

  @override
  String get leaderboardPeriodAll => 'Histórico';

  @override
  String leaderboardPeriodXp(int xp) {
    return '$xp XP';
  }

  @override
  String rankYou(String name) {
    return '$name (tú)';
  }

  @override
  String get loginTagline => 'Forja tu mejor versión';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get name => 'Nombre';

  @override
  String get email => 'Email';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get resetPasswordTitle => 'Nueva contraseña';

  @override
  String get resetPasswordSubtitle =>
      'Elige una contraseña segura para tu cuenta de FitForge.';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get resetPasswordAction => 'Actualizar contraseña';

  @override
  String get resetPasswordSuccess => 'Contraseña actualizada correctamente';

  @override
  String get resetPasswordFailed =>
      'No se pudo actualizar la contraseña. Pide un enlace nuevo e inténtalo otra vez.';

  @override
  String get resetPasswordTooShort =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get enter => 'Entrar';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get orContinueWith => 'o continúa con';

  @override
  String get googleSignInCancelled => 'Inicio de sesión con Google cancelado';

  @override
  String get googleSignInFailed =>
      'No se pudo iniciar sesión con Google. Inténtalo de nuevo.';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get completeSecurityVerification =>
      'Completa la verificación de seguridad';

  @override
  String get authError =>
      'Error de autenticación. Revisa tus datos e inténtalo de nuevo.';

  @override
  String get enterEmailFirst => 'Introduce tu email primero';

  @override
  String get passwordResetSent =>
      'Te enviamos un enlace para restablecer la contraseña';

  @override
  String get passwordResetFailed =>
      'No se pudo enviar el email de recuperación';

  @override
  String get haveAccountSignIn => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get noAccountSignUp => '¿No tienes cuenta? Regístrate';

  @override
  String get history => 'Historial';

  @override
  String get noWorkoutsYet => 'Sin entrenamientos aún. ¡Empieza hoy!';

  @override
  String get startToday => 'Sin entrenamientos aún. ¡Empieza hoy!';

  @override
  String get viewFullHistory => 'Ver historial completo';

  @override
  String get activeWorkout => 'Entrenamiento en curso';

  @override
  String get streakLabel => 'Racha';

  @override
  String get streakWeekly => 'Racha (≥4/sem)';

  @override
  String get streakWeeksSubtitle => 'semanas de racha (≥4/sem)';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String weeklyWorkoutsSubtitle(int goal) {
    return 'de $goal entrenamientos esta semana';
  }

  @override
  String get trainHeroReadyTitle => '¿Listo para entrenar?';

  @override
  String get trainHeroGoalMetTitle => '¡Meta semanal cumplida!';

  @override
  String trainHeroStreakWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¡Racha de $count semanas!',
      one: '¡Racha de 1 semana!',
    );
    return '$_temp0';
  }

  @override
  String trainWorkoutsRemaining(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'Te faltan $remaining entrenos esta semana',
      one: 'Te falta 1 entreno esta semana',
    );
    return '$_temp0';
  }

  @override
  String trainWeeklyProgress(int current, int goal) {
    return '$current de $goal esta semana';
  }

  @override
  String get trainSuggestedTitle => 'Siguiente entreno sugerido';

  @override
  String get trainSuggestedLastRoutine => 'Retoma tu última rutina';

  @override
  String get trainSuggestedRecovery => 'Músculos listos para esta sesión';

  @override
  String get trainSuggestedDefault => 'Un buen punto de partida';

  @override
  String get trainStartSuggested => 'Empezar entreno';

  @override
  String get recoveryViewDetail => 'Ver detalle';

  @override
  String get recoveryTopFatigued => 'Más fatigados';

  @override
  String get recoveryDetailTitle => 'Recuperación muscular';

  @override
  String get trainRecentWorkouts => 'Recientes';

  @override
  String get trainSwipeRepeat => 'Repetir';

  @override
  String get trainVolumePr => 'Mejor volumen';

  @override
  String get startWorkout => 'Iniciar entrenamiento';

  @override
  String get startingWorkout => 'Iniciando entrenamiento…';

  @override
  String startWorkoutError(String message) {
    return 'Error al iniciar entrenamiento: $message';
  }

  @override
  String get freeWorkout => 'Entrenamiento libre';

  @override
  String get loadingRoutines => 'Cargando rutinas...';

  @override
  String exercisesInRoutine(int count) {
    return '$count ejercicios';
  }

  @override
  String get noWorkoutsRegistered => 'Sin entrenamientos registrados';

  @override
  String get summaryTitle => 'Resumen';

  @override
  String get summaryWorkoutComplete => '¡Entreno completado!';

  @override
  String summaryVolumeUp(String percent) {
    return '+$percent% volumen vs última vez';
  }

  @override
  String get summaryMusclesTrained => 'Músculos trabajados';

  @override
  String get summaryPersonalRecords => 'Récords personales nuevos';

  @override
  String get summaryPersonalRecordBadge => 'PR';

  @override
  String get summaryExerciseImproved => 'Mejor que la última vez';

  @override
  String vsLastTime(String name) {
    return 'vs última vez ($name)';
  }

  @override
  String get exercisesCompleted => 'Ejercicios realizados';

  @override
  String setsReps(int sets, int reps) {
    return '$sets series · $reps reps';
  }

  @override
  String best(String value) {
    return 'mejor: $value';
  }

  @override
  String get today => 'Hoy';

  @override
  String get before => 'Antes';

  @override
  String recordLabel(String name) {
    return 'Récord: $name';
  }

  @override
  String durationMinutesExercises(int minutes, int count) {
    return '$minutes min · $count ejercicios';
  }

  @override
  String get caloriesBurned => 'Calorías';

  @override
  String caloriesKcal(int value) {
    return '$value kcal';
  }

  @override
  String get caloriesEstimateNote =>
      'Calorías activas estimadas (extra del entreno; el reposo basal ya está en tu meta diaria).';

  @override
  String get caloriesEstimateDefaultWeight =>
      'Estimación con peso de referencia (70 kg). Añade tu peso en el perfil para mayor precisión.';

  @override
  String get training => 'Entrenando';

  @override
  String get finish => 'Finalizar';

  @override
  String get cancelWorkout => 'Cancelar';

  @override
  String get cancelWorkoutTitle => '¿Cancelar entrenamiento?';

  @override
  String get cancelWorkoutMessage =>
      'Se eliminará este entrenamiento y no aparecerá en tu historial. No se puede deshacer.';

  @override
  String get cancelWorkoutConfirm => 'Cancelar entrenamiento';

  @override
  String get cancelWorkoutBack => 'Atrás';

  @override
  String get workoutCancelled => 'Entrenamiento cancelado';

  @override
  String cancelWorkoutFailed(String message) {
    return 'No se pudo cancelar el entrenamiento: $message';
  }

  @override
  String get leaveActiveWorkoutTitle => '¿Salir del entrenamiento?';

  @override
  String get leaveActiveWorkoutMessage =>
      'Tu progreso se guarda. Puedes volver a entrar desde Entrenar.';

  @override
  String get leaveActiveWorkoutConfirm => 'Salir';

  @override
  String get viewList => 'Ver lista';

  @override
  String get exerciseList => 'Lista de ejercicios';

  @override
  String get noActiveWorkout => 'No hay entrenamiento activo';

  @override
  String get addSet => 'Añadir serie';

  @override
  String get previous => 'Anterior';

  @override
  String get next => 'Siguiente';

  @override
  String exerciseProgress(int current, int total) {
    return 'Ejercicio $current de $total';
  }

  @override
  String exerciseAdded(String name) {
    return '$name añadido';
  }

  @override
  String get addingExercise => 'Añadiendo ejercicio…';

  @override
  String get exerciseRemoved => 'Ejercicio eliminado';

  @override
  String exerciseDeleteFailed(String message) {
    return 'No se pudo eliminar: $message';
  }

  @override
  String changedTo(String name) {
    return 'Cambiado a $name';
  }

  @override
  String finishFailed(String message) {
    return 'No se pudo finalizar: $message';
  }

  @override
  String get weightRequired =>
      'Indica el peso antes de marcar la serie como hecha';

  @override
  String get weightAdditionalSuffix => '(+ adicional)';

  @override
  String get weightPerArmSuffix => '(por brazo)';

  @override
  String get loadModePerArm => 'Por brazo';

  @override
  String get loadModeCombined => 'Conjunto';

  @override
  String get loadModeToggleHint =>
      'Alterna si trabajas ambos lados a la vez o por separado';

  @override
  String bodyweightLoadHint(String weight) {
    return 'Tu peso corporal ($weight) cuenta por defecto. El campo es carga adicional.';
  }

  @override
  String effectiveWeightLabel(String weight) {
    return 'Peso total: $weight';
  }

  @override
  String get reportExerciseProblem => 'Reportar problema con este ejercicio';

  @override
  String get exerciseReportTitle => 'Reportar problema';

  @override
  String get exerciseReportSubmit => 'Enviar reporte';

  @override
  String get exerciseReportThanks => 'Gracias, revisaremos tu reporte';

  @override
  String get exerciseReportWrongMetrics => 'Métricas incorrectas (peso/reps)';

  @override
  String get exerciseReportWrongGif => 'Imagen o GIF incorrecto';

  @override
  String get exerciseReportWrongName => 'Nombre o traducción incorrecta';

  @override
  String get exerciseReportWrongMuscles => 'Músculos o categoría incorrecta';

  @override
  String get exerciseReportOther => 'Otro';

  @override
  String get exerciseReportNotes => 'Detalles (opcional)';

  @override
  String get repsRequired => 'Indica las repeticiones';

  @override
  String get distanceRequired => 'Indica la distancia en metros';

  @override
  String get distanceMetersLabel => 'm';

  @override
  String setDeleteFailed(String message) {
    return 'No se pudo eliminar la serie: $message';
  }

  @override
  String get exerciseHistory => 'Historial del ejercicio';

  @override
  String get reps => 'Reps';

  @override
  String get done => 'Hecho';

  @override
  String get rirPickerTitle => '¿Cuántas repeticiones más pudiste haber hecho?';

  @override
  String get rirPickerSubtitle =>
      'Reps en reserva (RIR) del último set. La IA usará esto para ajustar tu próximo entreno.';

  @override
  String get rirPickerRepsLeft => 'reps más';

  @override
  String get rirPickerSkip => 'Omitir';

  @override
  String get newRoutine => 'Nueva rutina';

  @override
  String get generateWithAi => 'Generar con IA';

  @override
  String get noRoutines => 'Sin rutinas creadas';

  @override
  String get createRoutine => 'Crear rutina';

  @override
  String get generateAiRoutineTitle => 'Generar rutina con IA';

  @override
  String get targetMuscles => 'Músculos (ej: Pecho, Tríceps)';

  @override
  String get durationMin => 'Duración (min)';

  @override
  String get routineGenerated => 'Rutina generada y guardada';

  @override
  String alreadyInRoutine(String name) {
    return '\"$name\" ya está en la rutina';
  }

  @override
  String get editRoutine => 'Editar rutina';

  @override
  String get routineName => 'Nombre de la rutina';

  @override
  String get description => 'Descripción';

  @override
  String get discard => 'Descartar';

  @override
  String get routineDiscarded => 'Rutina descartada';

  @override
  String get routineSaved => 'Rutina guardada en Mis rutinas';

  @override
  String routineSavedNamed(String name) {
    return '\"$name\" guardada en Rutinas';
  }

  @override
  String get routineFavorite => 'Marcar como favorita';

  @override
  String get routineUnfavorite => 'Quitar de favoritas';

  @override
  String routineFavoritesMax(int max) {
    return 'Solo puedes tener $max rutinas favoritas en tu perfil';
  }

  @override
  String get friendFavoriteRoutines => 'Rutinas favoritas';

  @override
  String get noFavoriteRoutinesFriend =>
      'Este usuario no tiene rutinas favoritas públicas';

  @override
  String get previewRoutine => 'Previsualizar rutina';

  @override
  String get saveRoutine => 'Guardar rutina';

  @override
  String get shareRoutine => 'Compartir rutina';

  @override
  String get shareRoutineTitle => 'Enviar rutina a un amigo';

  @override
  String get shareRoutineSelectFriend =>
      'Selecciona un amigo para enviarle esta rutina';

  @override
  String shareRoutineSent(String name) {
    return 'Rutina enviada a $name';
  }

  @override
  String shareRoutineFailed(String message) {
    return 'No se pudo compartir: $message';
  }

  @override
  String get shareRoutineNoFriends => 'Agrega amigos para compartir rutinas';

  @override
  String get routineShareAccepted => 'Rutina guardada en tu biblioteca';

  @override
  String get routineShareDeclined => 'Solicitud de rutina rechazada';

  @override
  String get routineShareUnavailable => 'Esta solicitud ya no está disponible';

  @override
  String get accept => 'Aceptar';

  @override
  String get decline => 'Rechazar';

  @override
  String saveFailed(String message) {
    return 'No se pudo guardar: $message';
  }

  @override
  String moreExercises(int count) {
    return '+ $count ejercicios más';
  }

  @override
  String exercisesSection(int count) {
    return 'Ejercicios ($count)';
  }

  @override
  String get add => 'Añadir';

  @override
  String get coachTitle => 'Coach IA';

  @override
  String get coachWelcome => 'Tu entrenador personal con IA';

  @override
  String get coachWelcomeHint =>
      'Pídele una rutina y la guardarás cuando estés listo.\nConfigura tu API key en Perfil.';

  @override
  String coachDailyLimitReached(int limit) {
    return 'Has alcanzado el límite diario de $limit mensajes del Coach IA. Mejora tu plan para más.';
  }

  @override
  String coachDailyLimitRemaining(int remaining, int limit) {
    return '$remaining de $limit mensajes hoy';
  }

  @override
  String routineLimitReached(int limit) {
    return 'Has alcanzado el límite de $limit rutinas de tu plan. Mejora tu plan para guardar más.';
  }

  @override
  String routineLimitUsage(int used, int limit) {
    return '$used de $limit rutinas guardadas';
  }

  @override
  String get coachAskHint => 'Pregunta o pide una rutina…';

  @override
  String get coachRoutineReady =>
      'Aquí tienes tu rutina. Revísala y pulsa Guardar cuando estés listo.';

  @override
  String coachRoutinesReady(int count) {
    return 'Aquí tienes $count rutinas para la semana. Revísalas y guarda las que quieras.';
  }

  @override
  String get coachRoutineTooFewExercises =>
      'No pude armar una rutina variada con ejercicios del catálogo. Prueba pidiéndola de nuevo o elige músculos concretos.';

  @override
  String get coachRoutineFailed =>
      'No pude generar la rutina. Intenta ser más específico (músculos y duración).';

  @override
  String get aiConnectionError =>
      'Error en la conexión. Intenta de nuevo, por favor.';

  @override
  String get coachNoRoutineToSave =>
      'No hay ninguna rutina pendiente por guardar. Primero pídeme que cree una.';

  @override
  String get coachSuggestion1 => 'Crea una rutina de piernas de 45 minutos';

  @override
  String get coachSuggestion2 =>
      '¿Qué ejercicios me recomiendas para pecho hoy?';

  @override
  String get coachSuggestion3 =>
      'Hazme una rutina de espalda y bíceps para guardar';

  @override
  String get coachSuggestion4 =>
      '¿Cuándo debería descansar cada grupo muscular?';

  @override
  String get requestSent => 'Solicitud enviada';

  @override
  String requestFailed(String message) {
    return 'No se pudo enviar: $message';
  }

  @override
  String searchFailed(String message) {
    return 'Búsqueda falló: $message';
  }

  @override
  String get markRead => 'Marcar leídas';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get pendingRequests => 'Solicitudes pendientes';

  @override
  String get wantsToBeFriend => 'Quiere ser tu amigo';

  @override
  String get requestSentLabel => 'Solicitud enviada';

  @override
  String friendsCount(int count) {
    return 'Amigos ($count)';
  }

  @override
  String get searchFriendsHint => 'Buscar por correo o nombre…';

  @override
  String get removeFriendTitle => 'Eliminar amigo';

  @override
  String removeFriendBody(String name) {
    return '¿Quitar a $name de tu lista?';
  }

  @override
  String get muteFriend => 'Silenciar';

  @override
  String get unmuteFriend => 'Dejar de silenciar';

  @override
  String get friendMutedLabel => 'Silenciado';

  @override
  String friendMuted(String name) {
    return '$name silenciado';
  }

  @override
  String friendUnmuted(String name) {
    return '$name ya no está silenciado';
  }

  @override
  String get friendWorkoutNotify =>
      'Cuando un amigo complete un entreno, te avisaremos aquí.';

  @override
  String get noProfileAccess =>
      'No tienes acceso a este perfil o no sois amigos.';

  @override
  String levelLabel(String level) {
    return 'Nivel: $level';
  }

  @override
  String get noRecordsFriend => 'Aún no tiene records registrados.';

  @override
  String get muscleRecovery => 'Recuperación muscular';

  @override
  String get recoveryHint =>
      'Basado en tus entrenamientos recientes · recuperación en 48 h';

  @override
  String get rest => 'Descanso';

  @override
  String restRemaining(int seconds) {
    return '${seconds}s restantes';
  }

  @override
  String get skip => 'Saltar';

  @override
  String get minus15s => '-15s';

  @override
  String get plus15s => '+15s';

  @override
  String get customRest => 'Descanso personalizado';

  @override
  String get cardioDuration => 'Tiempo';

  @override
  String get cardioSecondsShort => 'seg';

  @override
  String get cardioDistance => 'Distancia';

  @override
  String get cardioIncline => 'Inclinación %';

  @override
  String get cardioDifficulty => 'Grado de dificultad';

  @override
  String get cardioSteps => 'Pasos';

  @override
  String get cardioMetricRequired => 'Indica al menos una métrica de cardio';

  @override
  String cardioSetLabel(int number) {
    return 'Intervalo $number';
  }

  @override
  String get cardioPrDistance => 'Distancia máx.';

  @override
  String get cardioPrDuration => 'Tiempo máx.';

  @override
  String get cardioPrSteps => 'Pasos máx.';

  @override
  String get cardioPrIncline => 'Inclinación máx.';

  @override
  String get cardioPrDifficulty => 'Dificultad máx.';

  @override
  String get exerciseTypeStrength => 'Fuerza';

  @override
  String get exerciseTypeCardio => 'Cardio';

  @override
  String get cardioPresetTreadmill => 'Cinta';

  @override
  String get cardioPresetElliptical => 'Elíptica';

  @override
  String get cardioPresetBike => 'Bici / spinning';

  @override
  String get cardioPresetStair => 'Escaladora';

  @override
  String get cardioPresetRowing => 'Remo';

  @override
  String get cardioPresetCustom => 'Personalizado';

  @override
  String get cardioMetricsLabel => 'Métricas a registrar';

  @override
  String get secondsLabel => 'Segundos';

  @override
  String get customRestChip => 'Personalizado';

  @override
  String restSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get addExercise => 'Añadir ejercicio';

  @override
  String get reorderExercise => 'Arrastrar para reordenar';

  @override
  String get searchByMuscle => 'Buscar por nombre, músculo o categoría…';

  @override
  String get searchExercise => 'Buscar ejercicio…';

  @override
  String inRoutine(int count) {
    return 'En rutina ($count)';
  }

  @override
  String get allGroups => 'Todos los grupos';

  @override
  String get noSearchInRoutine =>
      'Ningún ejercicio coincide con la búsqueda en tu rutina.';

  @override
  String get noExercisesFound => 'No se encontraron ejercicios.';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get swapSimilar => 'Intercambiar por similar';

  @override
  String get noSimilarFound =>
      'No encontramos ejercicios similares.\nPrueba añadir uno manualmente.';

  @override
  String get remove => 'Eliminar';

  @override
  String get noSets => 'Sin series';

  @override
  String get historyTitle => 'Historial';

  @override
  String get noExerciseHistory => 'Sin historial previo para este ejercicio.';

  @override
  String get loadingHistory => 'Cargando historial…';

  @override
  String setLine(int n, String detail) {
    return 'Serie $n: $detail';
  }

  @override
  String repsOnly(int reps) {
    return '$reps reps';
  }

  @override
  String get apiKeySaved =>
      'API key guardada de forma segura en el dispositivo';

  @override
  String get apiKeyDeleted => 'API key eliminada';

  @override
  String get apiKeysTitle => 'API Keys';

  @override
  String get apiKeyPrivacy =>
      'Tu API key se guarda solo en este dispositivo (almacenamiento seguro). Nunca se envía a nuestros servidores. Las llamadas a IA van directamente a OpenAI o Google.';

  @override
  String get saveApiKey => 'Guardar API Key';

  @override
  String get deleteApiKey => 'Eliminar API Key';

  @override
  String get openAiHint => 'Obtén tu key en platform.openai.com';

  @override
  String get geminiHint => 'Obtén tu key en aistudio.google.com';

  @override
  String get openAiKey => 'OpenAI API Key';

  @override
  String get geminiKey => 'Gemini API Key';

  @override
  String get claudeKey => 'Claude API Key';

  @override
  String get claudeHint =>
      'Obtén tu key en console.anthropic.com (API, no Claude Pro).';

  @override
  String get claudeApiNote =>
      'La suscripción Claude Pro no incluye API key. Necesitas crear una en Anthropic Console y pagar por uso.';

  @override
  String get apiGuidesTitle => 'Guías paso a paso';

  @override
  String get apiGuidesSubtitle =>
      'Si es tu primera vez, sigue estos instructivos. También puedes abrir el PDF completo.';

  @override
  String get apiGuideOpenPortal => 'Abrir sitio oficial';

  @override
  String get apiGuideOpenPdf => 'Ver instructivo PDF';

  @override
  String get openAiGuideTitle => 'Cómo obtener tu API Key de OpenAI';

  @override
  String get openAiGuidePortal => 'platform.openai.com/api-keys';

  @override
  String get openAiGuideStep1 =>
      'Abre platform.openai.com en tu navegador y crea una cuenta o inicia sesión con tu correo.';

  @override
  String get openAiGuideStep2 =>
      'Verifica tu correo si es la primera vez. OpenAI puede pedir un número de teléfono para seguridad.';

  @override
  String get openAiGuideStep3 =>
      'Entra a la sección API keys: platform.openai.com/api-keys (menú lateral → API keys).';

  @override
  String get openAiGuideStep4 =>
      'Pulsa «Create new secret key». Ponle un nombre que reconozcas, por ejemplo «FitForge».';

  @override
  String get openAiGuideStep5 =>
      'Copia la clave en cuanto aparezca. Solo se muestra una vez; si la pierdes, tendrás que crear otra.';

  @override
  String get openAiGuideStep6 =>
      'OpenAI puede pedir agregar un método de pago en Billing antes de usar la API (suele ser pago por uso).';

  @override
  String get openAiGuideStep7 =>
      'Vuelve a FitForge, pega la clave en el campo de arriba, elige OpenAI y pulsa «Guardar API Key».';

  @override
  String get geminiGuideTitle => 'Cómo obtener tu API Key de Gemini (Google)';

  @override
  String get geminiGuidePortal => 'aistudio.google.com/apikey';

  @override
  String get geminiGuideStep1 =>
      'Abre aistudio.google.com en tu navegador e inicia sesión con tu cuenta de Google.';

  @override
  String get geminiGuideStep2 =>
      'Si es la primera vez, acepta los términos de Google AI Studio cuando te lo pida.';

  @override
  String get geminiGuideStep3 =>
      'Ve a la sección de API keys: aistudio.google.com/apikey (menú «Get API key»).';

  @override
  String get geminiGuideStep4 =>
      'Pulsa «Create API key». Puedes crear un proyecto nuevo de Google Cloud o usar uno existente.';

  @override
  String get geminiGuideStep5 =>
      'Copia la API key generada. Guárdala en un lugar seguro; no la compartas con nadie.';

  @override
  String get geminiGuideStep6 =>
      'Google ofrece un nivel gratuito con límites de uso. Revisa los límites en la consola si lo necesitas.';

  @override
  String get geminiGuideStep7 =>
      'Vuelve a FitForge, pega la clave en el campo de arriba, elige Gemini y pulsa «Guardar API Key».';

  @override
  String get claudeGuideTitle =>
      'Cómo obtener tu API Key de Claude (Anthropic)';

  @override
  String get claudeGuidePortal => 'console.anthropic.com/settings/keys';

  @override
  String get claudeGuideStep1 =>
      'Abre console.anthropic.com e inicia sesión (cuenta distinta a claude.ai si solo usas el chat).';

  @override
  String get claudeGuideStep2 =>
      'Ve a Settings → API Keys (console.anthropic.com/settings/keys).';

  @override
  String get claudeGuideStep3 =>
      'Pulsa «Create Key», ponle un nombre (ej. FitForge) y confirma.';

  @override
  String get claudeGuideStep4 =>
      'Copia la key generada. Solo se muestra una vez; guárdala en un lugar seguro.';

  @override
  String get claudeGuideStep5 =>
      'Anthropic cobra por uso en la API (no usa tu suscripción Claude Pro del chat).';

  @override
  String get claudeGuideStep6 =>
      'Vuelve a FitForge, pega la clave, elige Claude y pulsa «Guardar API Key».';

  @override
  String setsRepsBest(int sets, int reps, String weight) {
    return '$sets series · $reps reps · mejor: $weight';
  }

  @override
  String get recordVolume => 'Volumen';

  @override
  String get recordReps => 'Repeticiones';

  @override
  String get recordMaxWeight => 'Peso máximo';

  @override
  String exercisesAndMuscles(int exercises, int muscles) {
    return '$exercises ejercicios · $muscles músculos';
  }

  @override
  String seriesCompleted(int total) {
    return '$total series · Completado';
  }

  @override
  String seriesProgress(int total, int done) {
    return '$total series · $done/$total hechas';
  }

  @override
  String seriesWithWeight(int total, String weight, int reps) {
    return '$total series · $weight × $reps';
  }

  @override
  String restPeriod(int seconds) {
    return '${seconds}s descanso';
  }

  @override
  String get timeNow => 'Ahora';

  @override
  String timeMinutesAgo(int n) {
    return 'Hace $n min';
  }

  @override
  String timeHoursAgo(int n) {
    return 'Hace $n h';
  }

  @override
  String timeDaysAgo(int n) {
    return 'Hace $n d';
  }

  @override
  String shareWorkoutTitle(String name) {
    return '$name — FitForge';
  }

  @override
  String shareDuration(int minutes) {
    return '⏱ $minutes min';
  }

  @override
  String shareExerciseCount(int count) {
    return '🏋️ $count ejercicios';
  }

  @override
  String shareTotalReps(int reps) {
    return '🔁 $reps reps totales';
  }

  @override
  String shareMaxWeight(String value) {
    return '📈 Peso máx: $value';
  }

  @override
  String shareVolume(String value) {
    return '📊 Volumen: $value';
  }

  @override
  String shareCalories(String value) {
    return '🔥 Calorías (est.): $value';
  }

  @override
  String get shareNewRecords => '🏆 ¡Nuevos récords vs última vez!';

  @override
  String shareMusclesTrained(String muscles) {
    return '💪 Músculos: $muscles';
  }

  @override
  String get sharePersonalRecords => '🏆 Récords personales:';

  @override
  String shareVolumeUp(String percent) {
    return '📈 +$percent% volumen vs última vez';
  }

  @override
  String get shareAchievementsHeader => '🎉 ¡Logros desbloqueados!';

  @override
  String shareLevelUp(int level) {
    return '⭐ ¡Subiste a nivel $level!';
  }

  @override
  String shareMilestoneUnlocked(String category, String tierName) {
    return '🏅 Medalla $category — $tierName';
  }

  @override
  String shareXpEarned(int xp) {
    return '⚡ +$xp XP';
  }

  @override
  String get summaryAchievementsTitle => '¡Logros desbloqueados!';

  @override
  String get summaryMilestoneUnlocked => 'Nueva medalla';

  @override
  String summaryMilestoneDetail(String category, String tierName) {
    return '$category · $tierName';
  }

  @override
  String get shareExercisesHeader => 'Ejercicios:';

  @override
  String shareExerciseLine(String name, int sets, int reps, String weight) {
    return '• $name: $sets× · $reps reps$weight';
  }

  @override
  String get shareHashtags => '#FitForge #Entrenamiento';

  @override
  String shareHyroxTitle(String name) {
    return 'HYROX · $name — FitForge';
  }

  @override
  String shareHyroxTotalTime(String time) {
    return 'Tiempo total: $time';
  }

  @override
  String shareHyroxStationLine(int index, String station, String time) {
    return '$index. $station: $time';
  }

  @override
  String shareRunnerTitle(String name) {
    return 'RUN · $name — FitForge';
  }

  @override
  String shareRunnerStats(String distance, String pace, String time) {
    return '$distance · $pace · $time';
  }

  @override
  String shareRunnerSurface(String surface) {
    return 'Superficie: $surface';
  }

  @override
  String shareRunnerSplitLine(int km, String time) {
    return 'Km $km: $time';
  }

  @override
  String get maxWeight => 'Peso máx';

  @override
  String get volume => 'Volumen';

  @override
  String get searchFriendsEmpty =>
      'Busca por correo o nombre para agregar amigos.';

  @override
  String get generatingRoutine => 'Generando rutina…';

  @override
  String get streakWeeks0 => '0 semanas';

  @override
  String get streakWeeks1 => '1 semana';

  @override
  String streakWeeksMany(int count) {
    return '$count semanas';
  }

  @override
  String get volumeShort => 'vol.';

  @override
  String get defaultWorkoutName => 'Entrenamiento';

  @override
  String get rotateBody => 'Girar maniquí';

  @override
  String get bodyFront => 'Frente';

  @override
  String get bodyBack => 'Espalda';

  @override
  String get chooseAvatar => 'Elige tu avatar';

  @override
  String get chooseAvatarHint => 'Selecciona un avatar del catálogo FitForge';

  @override
  String get changeAvatar => 'Cambiar avatar';

  @override
  String get foodTitle => 'Nutrición';

  @override
  String get foodEaten => 'Consumidas';

  @override
  String get foodBurned => 'Quemadas';

  @override
  String foodCaloriesLeft(int count) {
    return '$count kcal restantes';
  }

  @override
  String get foodDailyBudget => 'Presupuesto del día';

  @override
  String get foodCaloriesAvailable => 'kcal disponibles';

  @override
  String get foodCaloriesSurplus => 'kcal en exceso';

  @override
  String foodBudgetUsed(int percent) {
    return '$percent% usado';
  }

  @override
  String foodBudgetGoal(int goal) {
    return 'objetivo $goal kcal';
  }

  @override
  String get foodStatGoal => 'Objetivo';

  @override
  String foodBudgetSummary(int eaten, int burned, int goal) {
    return '$eaten consumidas · $burned quemadas · objetivo $goal kcal';
  }

  @override
  String get foodTimelineEmpty => 'Sin registros';

  @override
  String get foodEnergyOutputTitle => 'Energía gastada';

  @override
  String get foodEnergyOutputEmpty =>
      'Sin actividad registrada hoy. Añade entrenos en FitForge o actividades manuales.';

  @override
  String get foodAddActivity => 'Registrar actividad';

  @override
  String get foodFromFitForgeWorkout => 'Entrenamiento FitForge';

  @override
  String get foodManualActivityLabel => 'Actividad manual';

  @override
  String foodWorkoutBonus(int count) {
    return '+$count kcal activas por entrenamiento hoy';
  }

  @override
  String get foodMealsTitle => 'Comidas del día';

  @override
  String get foodActivitiesTitle => 'Actividades del día';

  @override
  String get foodActivityManual => 'Actividades manuales';

  @override
  String get foodActivityAdd => 'Agregar actividad';

  @override
  String get foodActivityAddHint =>
      'Registra entrenos u otras actividades que no hayas documentado en FitForge.';

  @override
  String get foodActivityName => 'Nombre de la actividad';

  @override
  String get foodActivityNameHint => 'Ej. Caminata, yoga, fútbol…';

  @override
  String get foodActivityNameRequired => 'Escribe un nombre para la actividad.';

  @override
  String get foodActivityCalories => 'Calorías quemadas';

  @override
  String get foodActivityCaloriesHint => '150';

  @override
  String get foodActivityCaloriesInvalid => 'Indica calorías entre 1 y 9999.';

  @override
  String get foodActivitySave => 'Guardar actividad';

  @override
  String foodManualActivityBonus(int count) {
    return '+$count kcal por actividades manuales';
  }

  @override
  String get mealBreakfast => 'Desayuno';

  @override
  String get mealLunch => 'Almuerzo';

  @override
  String get mealDinner => 'Cena';

  @override
  String get mealSnack => 'Otros';

  @override
  String get foodBmrMissingHint =>
      'Completa tu peso y datos en Perfil para calcular tu objetivo calórico personalizado.';

  @override
  String get foodSearchHint => 'Filtrar alimentos registrados';

  @override
  String get foodModeBarcode => 'Código';

  @override
  String get foodModeSearch => 'Buscar';

  @override
  String get foodModePhoto => 'Foto';

  @override
  String get foodModeQuick => 'Rápido';

  @override
  String get foodModeManual => 'Manual';

  @override
  String get foodRecentSearches => 'Alimentos recientes';

  @override
  String get foodNoRecent => 'Aún no has registrado alimentos.';

  @override
  String get foodAiFailed =>
      'No se pudo estimar el alimento. Revisa tu API key o intenta de nuevo.';

  @override
  String get foodBarcodeNotFound =>
      'Producto no encontrado en la base de datos.';

  @override
  String get foodBarcodeHint =>
      'Apunta la cámara al código de barras del empaque.';

  @override
  String get foodBarcodeCameraDenied =>
      'Se necesita permiso de cámara para escanear códigos.';

  @override
  String get foodBarcodeUnsupported =>
      'Este dispositivo no tiene cámara compatible con el escáner.';

  @override
  String get foodBarcodeGenericError =>
      'No se pudo abrir la cámara. Revisa permisos o prueba en un dispositivo físico.';

  @override
  String get foodBarcodeRetry => 'Reintentar';

  @override
  String get foodBarcodeOpenSettings => 'Abrir ajustes de la app';

  @override
  String get foodBarcodePhotoAction => 'Tomar foto';

  @override
  String get foodBarcodeGalleryAction => 'Galería';

  @override
  String get foodBarcodePhotoFallback =>
      'Si el visor en vivo no arranca, escanea desde una foto o la galería.';

  @override
  String get foodBarcodeNotDetectedInPhoto =>
      'No se detectó código de barras en la imagen. Acerca más el empaque e intenta de nuevo.';

  @override
  String get foodBarcodeLookupFailed =>
      'Error al consultar el código. Revisa tu conexión.';

  @override
  String get foodPer100gNote =>
      'Los valores nutricionales se calculan por cada 100 g/ml.';

  @override
  String get foodQuickAddHint =>
      'Describe lo que estás comiendo y la IA calculará calorías y macros.';

  @override
  String get foodQuickAddPlaceholder =>
      'Ej.: 2 huevos revueltos con queso y pan integral';

  @override
  String get foodQuickAddAction => 'Estimar con IA';

  @override
  String get foodManualAddHint =>
      'Introduce los datos de una porción. Se guardará en tu dispositivo para reutilizarlo.';

  @override
  String get foodManualAddAction => 'Continuar';

  @override
  String get foodManualSavedFoods => 'Guardados en este dispositivo';

  @override
  String get foodManualNoSaved => 'Aún no tienes alimentos manuales guardados.';

  @override
  String get foodManualNameRequired => 'Escribe el nombre del alimento.';

  @override
  String get foodManualCaloriesRequired =>
      'Introduce calorías mayores que cero.';

  @override
  String get foodManualGramsLabel => 'gramos totales (g)';

  @override
  String get foodPortionUnit => 'porción';

  @override
  String get foodManualQuantityHint =>
      'Ajusta las porciones; calorías y macros se recalculan solos.';

  @override
  String get foodPhotoHint =>
      'Toma una foto de tu plato. La IA identificará los alimentos y sugerirá los macros.';

  @override
  String get foodPhotoAction => 'Tomar foto';

  @override
  String get foodPhotoGalleryAction => 'Elegir de galería';

  @override
  String get foodPhotoReferenceCaption =>
      'Esta foto se usa al recalcular con IA';

  @override
  String get foodPhotoTapToExpand => 'Toca para ampliar';

  @override
  String foodQuantityLabel(String unit) {
    return 'Cantidad ($unit)';
  }

  @override
  String get foodNameLabel => 'Nombre';

  @override
  String get foodNameHint => 'ej. Pechuga a la plancha con arroz y brócoli';

  @override
  String get foodMacrosAutoHint =>
      'Ajusta los gramos; calorías y macros se recalculan solos.';

  @override
  String get foodAiCorrectionHint => '¿La IA se equivocó?';

  @override
  String get foodAiCorrectionPlaceholder =>
      'Ej.: eran 3 tortillas, no 2, y cada una tiene 56 kcal';

  @override
  String get foodAiCorrectionAction => 'Recalcular con IA';

  @override
  String get foodAnalyzing => 'Analizando…';

  @override
  String get foodDetailTitle => 'Detalle nutricional';

  @override
  String get foodAddThis => 'Añadir alimento';

  @override
  String get foodServingLabel => 'Porción';

  @override
  String get foodCaloriesLabel => 'Calorías (kcal)';

  @override
  String get foodIngredients => 'Ingredientes';

  @override
  String get foodIngredientBreakdownHint =>
      'Peso estimado por componente — corrige abajo si algo no cuadra';

  @override
  String foodIngredientGrams(String grams) {
    return '~$grams g';
  }

  @override
  String foodIngredientTotalGrams(String grams) {
    return 'Total estimado · ~$grams g';
  }

  @override
  String get macroProtein => 'Proteína';

  @override
  String get macroFat => 'Grasa';

  @override
  String get macroCarbs => 'Carbohidratos';

  @override
  String get macroFiber => 'Fibra';

  @override
  String foodMealGoalPlaceholder(int eaten, int goal) {
    return '$eaten / $goal kcal';
  }

  @override
  String get routineExerciseSets => 'Series';

  @override
  String routineExerciseWeight(String unit) {
    return 'Peso ($unit)';
  }

  @override
  String get routineAddSet => 'Añadir serie';

  @override
  String routineSetNumber(int number) {
    return 'Ser. $number';
  }
}
