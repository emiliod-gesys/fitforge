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
  String get navRoutines => 'Rutinas';

  @override
  String get navExercises => 'Ejercicios';

  @override
  String get navProgress => 'Progreso';

  @override
  String get navSocial => 'Social';

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
  String get kilograms => 'Kilogramos';

  @override
  String get pounds => 'Libras';

  @override
  String get bodyMetrics => 'Métricas corporales';

  @override
  String get trainingConfig => 'Configuración de entrenamiento';

  @override
  String get goal => 'Objetivo';

  @override
  String get experienceLevel => 'Nivel de experiencia';

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
  String get aiCoachSubtitle => 'Recomendaciones personalizadas';

  @override
  String get fitnessGoalTitle => 'Objetivo fitness';

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
  String xpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String get levelUp => '¡Subiste de nivel!';

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
  String get volumePerWorkout => 'Volumen por entrenamiento';

  @override
  String get last30Days => 'Últimos 30 días';

  @override
  String get completeWorkoutsForVolume =>
      'Completa entrenamientos para ver tu volumen';

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
  String get friendsRanking => 'Ranking de amigos';

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
  String get enter => 'Entrar';

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
  String get thisWeek => 'Esta semana';

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
      'Estimación según duración, volumen, peso y perfil metabólico.';

  @override
  String get caloriesEstimateDefaultWeight =>
      'Estimación con peso de referencia (70 kg). Añade tu peso en el perfil para mayor precisión.';

  @override
  String get training => 'Entrenando';

  @override
  String get finish => 'Finalizar';

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
  String get repsRequired => 'Indica las repeticiones';

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
  String get coachAskHint => 'Pregunta o pide una rutina…';

  @override
  String get coachRoutineReady =>
      'Aquí tienes tu rutina. Revísala y pulsa Guardar cuando estés listo.';

  @override
  String get coachRoutineFailed =>
      'No pude generar la rutina. Intenta ser más específico (músculos y duración).';

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
  String get shareExercisesHeader => 'Ejercicios:';

  @override
  String shareExerciseLine(String name, int sets, int reps, String weight) {
    return '• $name: $sets× · $reps reps$weight';
  }

  @override
  String get shareHashtags => '#FitForge #Entrenamiento';

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
}
