import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'FitForge'**
  String get appTitle;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @notDefined.
  ///
  /// In es, this message translates to:
  /// **'No definido'**
  String get notDefined;

  /// No description provided for @user.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get user;

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Error: {message}'**
  String errorGeneric(String message);

  /// No description provided for @enterValue.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el valor'**
  String get enterValue;

  /// No description provided for @years.
  ///
  /// In es, this message translates to:
  /// **'años'**
  String get years;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando…'**
  String get loading;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @apply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get apply;

  /// No description provided for @generate.
  ///
  /// In es, this message translates to:
  /// **'Generar'**
  String get generate;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @share.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get share;

  /// No description provided for @view.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get view;

  /// No description provided for @active.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get active;

  /// No description provided for @minutes.
  ///
  /// In es, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @minSuffix.
  ///
  /// In es, this message translates to:
  /// **'{n} min'**
  String minSuffix(int n);

  /// No description provided for @navWorkout.
  ///
  /// In es, this message translates to:
  /// **'Entreno'**
  String get navWorkout;

  /// No description provided for @navTrain.
  ///
  /// In es, this message translates to:
  /// **'Entrenar'**
  String get navTrain;

  /// No description provided for @navRoutines.
  ///
  /// In es, this message translates to:
  /// **'Rutinas'**
  String get navRoutines;

  /// No description provided for @trainTabToday.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento'**
  String get trainTabToday;

  /// No description provided for @trainTabRoutines.
  ///
  /// In es, this message translates to:
  /// **'Rutinas'**
  String get trainTabRoutines;

  /// No description provided for @navCoach.
  ///
  /// In es, this message translates to:
  /// **'Coach'**
  String get navCoach;

  /// No description provided for @navFood.
  ///
  /// In es, this message translates to:
  /// **'Comida'**
  String get navFood;

  /// No description provided for @navProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get navProgress;

  /// No description provided for @navSocial.
  ///
  /// In es, this message translates to:
  /// **'Social'**
  String get navSocial;

  /// No description provided for @navStudents.
  ///
  /// In es, this message translates to:
  /// **'Alumnos'**
  String get navStudents;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @coachAi.
  ///
  /// In es, this message translates to:
  /// **'Coach IA'**
  String get coachAi;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @profileDedication.
  ///
  /// In es, this message translates to:
  /// **'Esta app nunca hubiera existido sin la motivación de mis hermanos Diego y Rodrigo, que me inspiraron a buscar un estilo de vida más saludable, LIGHT WEIGHT BABY!'**
  String get profileDedication;

  /// No description provided for @personalData.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get personalData;

  /// No description provided for @profileOnboardingTitle.
  ///
  /// In es, this message translates to:
  /// **'Completa tu perfil'**
  String get profileOnboardingTitle;

  /// No description provided for @profileOnboardingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos estos datos para personalizar entrenamientos, nutrición y progreso.'**
  String get profileOnboardingSubtitle;

  /// No description provided for @profileOnboardingNickname.
  ///
  /// In es, this message translates to:
  /// **'Nombre o apodo'**
  String get profileOnboardingNickname;

  /// No description provided for @profileOnboardingContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get profileOnboardingContinue;

  /// No description provided for @weightUpdateTitle.
  ///
  /// In es, this message translates to:
  /// **'Actualiza tu peso'**
  String get weightUpdateTitle;

  /// No description provided for @weightUpdateMessage.
  ///
  /// In es, this message translates to:
  /// **'Han pasado más de 15 días desde tu último registro. Actualiza tu peso para mantener tus métricas precisas.'**
  String get weightUpdateMessage;

  /// No description provided for @weightUpdateSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar peso'**
  String get weightUpdateSave;

  /// No description provided for @weightInvalid.
  ///
  /// In es, this message translates to:
  /// **'Indica un peso válido'**
  String get weightInvalid;

  /// No description provided for @genderRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu género'**
  String get genderRequired;

  /// No description provided for @heightInvalid.
  ///
  /// In es, this message translates to:
  /// **'Indica una altura válida (50–280 cm)'**
  String get heightInvalid;

  /// No description provided for @ageInvalid.
  ///
  /// In es, this message translates to:
  /// **'Indica una edad válida (13–119 años)'**
  String get ageInvalid;

  /// No description provided for @displayName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get displayName;

  /// No description provided for @displayNameTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get displayNameTitle;

  /// No description provided for @displayNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre'**
  String get displayNameRequired;

  /// No description provided for @age.
  ///
  /// In es, this message translates to:
  /// **'Edad'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In es, this message translates to:
  /// **'Género'**
  String get gender;

  /// No description provided for @height.
  ///
  /// In es, this message translates to:
  /// **'Altura'**
  String get height;

  /// No description provided for @preferredLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma preferido'**
  String get preferredLanguage;

  /// No description provided for @unitSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema de unidades'**
  String get unitSystem;

  /// No description provided for @accentColor.
  ///
  /// In es, this message translates to:
  /// **'Color de acento'**
  String get accentColor;

  /// No description provided for @accentColorHint.
  ///
  /// In es, this message translates to:
  /// **'Personaliza el color principal de la app'**
  String get accentColorHint;

  /// No description provided for @accentGold.
  ///
  /// In es, this message translates to:
  /// **'Dorado'**
  String get accentGold;

  /// No description provided for @accentOrange.
  ///
  /// In es, this message translates to:
  /// **'Naranja'**
  String get accentOrange;

  /// No description provided for @accentCobalt.
  ///
  /// In es, this message translates to:
  /// **'Azul'**
  String get accentCobalt;

  /// No description provided for @accentViolet.
  ///
  /// In es, this message translates to:
  /// **'Violeta'**
  String get accentViolet;

  /// No description provided for @accentEmerald.
  ///
  /// In es, this message translates to:
  /// **'Verde'**
  String get accentEmerald;

  /// No description provided for @accentRose.
  ///
  /// In es, this message translates to:
  /// **'Rosado'**
  String get accentRose;

  /// No description provided for @accentCrimson.
  ///
  /// In es, this message translates to:
  /// **'Carmesí'**
  String get accentCrimson;

  /// No description provided for @kilograms.
  ///
  /// In es, this message translates to:
  /// **'Kilogramos'**
  String get kilograms;

  /// No description provided for @pounds.
  ///
  /// In es, this message translates to:
  /// **'Libras'**
  String get pounds;

  /// No description provided for @bodyMetrics.
  ///
  /// In es, this message translates to:
  /// **'Métricas corporales'**
  String get bodyMetrics;

  /// No description provided for @trainingConfig.
  ///
  /// In es, this message translates to:
  /// **'Configuración de entrenamiento'**
  String get trainingConfig;

  /// No description provided for @personalTrainerMode.
  ///
  /// In es, this message translates to:
  /// **'Modo entrenador personal'**
  String get personalTrainerMode;

  /// No description provided for @personalTrainerModeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Activa la pestaña Alumnos para monitorear clientes'**
  String get personalTrainerModeSubtitle;

  /// No description provided for @personalTrainerModeEnabled.
  ///
  /// In es, this message translates to:
  /// **'Modo entrenador activado. Pestaña Alumnos disponible.'**
  String get personalTrainerModeEnabled;

  /// No description provided for @personalTrainerModeDisabled.
  ///
  /// In es, this message translates to:
  /// **'Modo entrenador desactivado.'**
  String get personalTrainerModeDisabled;

  /// No description provided for @personalTrainerModeFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cambiar el modo: {message}'**
  String personalTrainerModeFailed(String message);

  /// No description provided for @trainerModeRequired.
  ///
  /// In es, this message translates to:
  /// **'Activa el modo entrenador personal en tu Perfil para usar esta sección.'**
  String get trainerModeRequired;

  /// No description provided for @studentsScreenHint.
  ///
  /// In es, this message translates to:
  /// **'Envía una solicitud a tus amigos para agregarlos como alumnos. Solo verás sus datos cuando la acepten.'**
  String get studentsScreenHint;

  /// No description provided for @studentsCount.
  ///
  /// In es, this message translates to:
  /// **'Alumnos ({count})'**
  String studentsCount(int count);

  /// No description provided for @studentsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes alumnos. Envía una solicitud a tus amigos desde la lista de abajo.'**
  String get studentsEmpty;

  /// No description provided for @addStudentFromFriends.
  ///
  /// In es, this message translates to:
  /// **'Agregar desde amigos'**
  String get addStudentFromFriends;

  /// No description provided for @addStudentEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay amigos disponibles. Primero deben ser amigos aceptados.'**
  String get addStudentEmpty;

  /// No description provided for @addStudentAction.
  ///
  /// In es, this message translates to:
  /// **'Agregar alumno'**
  String get addStudentAction;

  /// No description provided for @sendStudentRequestAction.
  ///
  /// In es, this message translates to:
  /// **'Enviar solicitud'**
  String get sendStudentRequestAction;

  /// No description provided for @studentAdded.
  ///
  /// In es, this message translates to:
  /// **'Alumno agregado'**
  String get studentAdded;

  /// No description provided for @studentRequestSent.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada. El alumno debe aceptarla.'**
  String get studentRequestSent;

  /// No description provided for @studentRequestCanceled.
  ///
  /// In es, this message translates to:
  /// **'Solicitud cancelada'**
  String get studentRequestCanceled;

  /// No description provided for @studentRequestsSentSection.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes enviadas'**
  String get studentRequestsSentSection;

  /// No description provided for @studentRequestPendingLabel.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de aprobación'**
  String get studentRequestPendingLabel;

  /// No description provided for @trainerRequestAccepted.
  ///
  /// In es, this message translates to:
  /// **'Solicitud aceptada. Ahora tienes un entrenador.'**
  String get trainerRequestAccepted;

  /// No description provided for @trainerRequestDeclined.
  ///
  /// In es, this message translates to:
  /// **'Solicitud rechazada'**
  String get trainerRequestDeclined;

  /// No description provided for @addStudentFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo agregar: {message}'**
  String addStudentFailed(String message);

  /// No description provided for @removeStudentTitle.
  ///
  /// In es, this message translates to:
  /// **'Quitar alumno'**
  String get removeStudentTitle;

  /// No description provided for @removeStudentMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar a {name} de tus alumnos?'**
  String removeStudentMessage(String name);

  /// No description provided for @removeStudentAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar alumno'**
  String get removeStudentAction;

  /// No description provided for @studentDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Alumno'**
  String get studentDetailTitle;

  /// No description provided for @studentNotFound.
  ///
  /// In es, this message translates to:
  /// **'Alumno no encontrado'**
  String get studentNotFound;

  /// No description provided for @studentRecoveryTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperación muscular'**
  String get studentRecoveryTitle;

  /// No description provided for @studentNutritionTitle.
  ///
  /// In es, this message translates to:
  /// **'Nutrición de hoy'**
  String get studentNutritionTitle;

  /// No description provided for @studentNutritionTitleDate.
  ///
  /// In es, this message translates to:
  /// **'Nutrición del {date}'**
  String studentNutritionTitleDate(String date);

  /// No description provided for @studentWorkoutsTitle.
  ///
  /// In es, this message translates to:
  /// **'Entrenos recientes'**
  String get studentWorkoutsTitle;

  /// No description provided for @studentWorkoutsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Este alumno aún no ha registrado entrenos completados.'**
  String get studentWorkoutsEmpty;

  /// No description provided for @studentRoutinesTitle.
  ///
  /// In es, this message translates to:
  /// **'Rutinas del alumno'**
  String get studentRoutinesTitle;

  /// No description provided for @studentRoutinesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Este alumno aún no tiene rutinas.'**
  String get studentRoutinesEmpty;

  /// No description provided for @studentRoutineNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva rutina para alumno'**
  String get studentRoutineNew;

  /// No description provided for @studentRoutineEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar rutina del alumno'**
  String get studentRoutineEdit;

  /// No description provided for @deleteRoutineTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar rutina'**
  String get deleteRoutineTitle;

  /// No description provided for @deleteRoutineMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar la rutina \"{name}\"?'**
  String deleteRoutineMessage(String name);

  /// No description provided for @goal.
  ///
  /// In es, this message translates to:
  /// **'Objetivo'**
  String get goal;

  /// No description provided for @experienceLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel de experiencia'**
  String get experienceLevel;

  /// No description provided for @activityLevel.
  ///
  /// In es, this message translates to:
  /// **'Actividad fuera del gym'**
  String get activityLevel;

  /// No description provided for @activityLevelTitle.
  ///
  /// In es, this message translates to:
  /// **'Actividad diaria aparte del gym'**
  String get activityLevelTitle;

  /// No description provided for @activityLevelHint.
  ///
  /// In es, this message translates to:
  /// **'Tu rutina diaria sin contar entrenamientos de fuerza ni cardio'**
  String get activityLevelHint;

  /// No description provided for @activitySedentary.
  ///
  /// In es, this message translates to:
  /// **'Sedentario'**
  String get activitySedentary;

  /// No description provided for @activityModerate.
  ///
  /// In es, this message translates to:
  /// **'Moderado'**
  String get activityModerate;

  /// No description provided for @activityHigh.
  ///
  /// In es, this message translates to:
  /// **'Alto'**
  String get activityHigh;

  /// No description provided for @activitySedentaryDescription.
  ///
  /// In es, this message translates to:
  /// **'Menos de 4 mil pasos diarios'**
  String get activitySedentaryDescription;

  /// No description provided for @activityModerateDescription.
  ///
  /// In es, this message translates to:
  /// **'Entre 4 mil y 10 mil pasos diarios'**
  String get activityModerateDescription;

  /// No description provided for @activityHighDescription.
  ///
  /// In es, this message translates to:
  /// **'Más de 10 mil pasos diarios'**
  String get activityHighDescription;

  /// No description provided for @activityLevelFootnote.
  ///
  /// In es, this message translates to:
  /// **'Estas son aproximaciones de actividad física para ayudar a orientar al usuario.'**
  String get activityLevelFootnote;

  /// No description provided for @restTimerAlert.
  ///
  /// In es, this message translates to:
  /// **'Aviso de descanso'**
  String get restTimerAlert;

  /// No description provided for @restTimerAlertTitle.
  ///
  /// In es, this message translates to:
  /// **'Fin del descanso'**
  String get restTimerAlertTitle;

  /// No description provided for @restTimerAlertSound.
  ///
  /// In es, this message translates to:
  /// **'Sonido'**
  String get restTimerAlertSound;

  /// No description provided for @restTimerAlertVibration.
  ///
  /// In es, this message translates to:
  /// **'Vibración'**
  String get restTimerAlertVibration;

  /// No description provided for @restTimerAlertBoth.
  ///
  /// In es, this message translates to:
  /// **'Sonido y vibración'**
  String get restTimerAlertBoth;

  /// No description provided for @aiSection.
  ///
  /// In es, this message translates to:
  /// **'Inteligencia artificial'**
  String get aiSection;

  /// No description provided for @apiKeys.
  ///
  /// In es, this message translates to:
  /// **'API Keys (OpenAI / Gemini)'**
  String get apiKeys;

  /// No description provided for @apiKeysConfigured.
  ///
  /// In es, this message translates to:
  /// **'Configurado ({provider})'**
  String apiKeysConfigured(String provider);

  /// No description provided for @apiKeysNotConfigured.
  ///
  /// In es, this message translates to:
  /// **'No configurado'**
  String get apiKeysNotConfigured;

  /// No description provided for @advancedSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes avanzados'**
  String get advancedSettings;

  /// No description provided for @advancedSettingsHint.
  ///
  /// In es, this message translates to:
  /// **'Opciones para usuarios con experiencia'**
  String get advancedSettingsHint;

  /// No description provided for @bringYourOwnAi.
  ///
  /// In es, this message translates to:
  /// **'Conectar tu cuenta de IA'**
  String get bringYourOwnAi;

  /// No description provided for @bringYourOwnAiSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Usa tu propia cuenta de OpenAI, Gemini o Claude'**
  String get bringYourOwnAiSubtitle;

  /// No description provided for @apiKeysNotAvailableOnPaidPlan.
  ///
  /// In es, this message translates to:
  /// **'Tu plan ya incluye IA — no necesitas una API key propia'**
  String get apiKeysNotAvailableOnPaidPlan;

  /// No description provided for @featureGymratPlansOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo para usuarios Gymrat y Gymrat Pro'**
  String get featureGymratPlansOnly;

  /// No description provided for @featureGymratProOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo para usuarios Gymrat Pro'**
  String get featureGymratProOnly;

  /// No description provided for @aiCoachSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones personalizadas'**
  String get aiCoachSubtitle;

  /// No description provided for @proactiveAi.
  ///
  /// In es, this message translates to:
  /// **'IA proactiva'**
  String get proactiveAi;

  /// No description provided for @proactiveAiSubtitleOff.
  ///
  /// In es, this message translates to:
  /// **'La IA solo responde cuando le escribes'**
  String get proactiveAiSubtitleOff;

  /// No description provided for @proactiveAiSubtitleOn.
  ///
  /// In es, this message translates to:
  /// **'Activada · puede consumir más tokens'**
  String get proactiveAiSubtitleOn;

  /// No description provided for @proactiveAiEnableTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Activar IA proactiva?'**
  String get proactiveAiEnableTitle;

  /// No description provided for @proactiveAiEnableMessage.
  ///
  /// In es, this message translates to:
  /// **'FitForge podrá usar tu API key para enviarte sugerencias sin que las pidas. Esto puede aumentar el consumo de tokens.'**
  String get proactiveAiEnableMessage;

  /// No description provided for @proactiveAiEnableConfirm.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get proactiveAiEnableConfirm;

  /// No description provided for @aiCalculatingWorkoutSuggestions.
  ///
  /// In es, this message translates to:
  /// **'Calculando sugerencias de IA…'**
  String get aiCalculatingWorkoutSuggestions;

  /// No description provided for @aiWorkoutSuggestionsApplied.
  ///
  /// In es, this message translates to:
  /// **'Series sugeridas por IA según tu historial y objetivo'**
  String get aiWorkoutSuggestionsApplied;

  /// No description provided for @fitnessGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'Objetivo fitness'**
  String get fitnessGoalTitle;

  /// No description provided for @experienceTitle.
  ///
  /// In es, this message translates to:
  /// **'Nivel de experiencia'**
  String get experienceTitle;

  /// No description provided for @genderMale.
  ///
  /// In es, this message translates to:
  /// **'Masculino'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In es, this message translates to:
  /// **'Femenino'**
  String get genderFemale;

  /// No description provided for @genderNonBinary.
  ///
  /// In es, this message translates to:
  /// **'No binario'**
  String get genderNonBinary;

  /// No description provided for @genderPreferNotSay.
  ///
  /// In es, this message translates to:
  /// **'Prefiero no decir'**
  String get genderPreferNotSay;

  /// No description provided for @genderTitle.
  ///
  /// In es, this message translates to:
  /// **'Género'**
  String get genderTitle;

  /// No description provided for @ageTitle.
  ///
  /// In es, this message translates to:
  /// **'Edad'**
  String get ageTitle;

  /// No description provided for @heightTitle.
  ///
  /// In es, this message translates to:
  /// **'Altura'**
  String get heightTitle;

  /// No description provided for @languageTitle.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageTitle;

  /// No description provided for @languageEs.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageEs;

  /// No description provided for @languageEn.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @feet.
  ///
  /// In es, this message translates to:
  /// **'Pies'**
  String get feet;

  /// No description provided for @inches.
  ///
  /// In es, this message translates to:
  /// **'Pulgadas'**
  String get inches;

  /// No description provided for @goalHypertrophy.
  ///
  /// In es, this message translates to:
  /// **'Hipertrofia'**
  String get goalHypertrophy;

  /// No description provided for @goalStrength.
  ///
  /// In es, this message translates to:
  /// **'Fuerza'**
  String get goalStrength;

  /// No description provided for @goalFatLoss.
  ///
  /// In es, this message translates to:
  /// **'Pérdida de grasa'**
  String get goalFatLoss;

  /// No description provided for @goalEndurance.
  ///
  /// In es, this message translates to:
  /// **'Resistencia'**
  String get goalEndurance;

  /// No description provided for @goalMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento'**
  String get goalMaintenance;

  /// No description provided for @expBeginner.
  ///
  /// In es, this message translates to:
  /// **'principiante'**
  String get expBeginner;

  /// No description provided for @expIntermediate.
  ///
  /// In es, this message translates to:
  /// **'intermedio'**
  String get expIntermediate;

  /// No description provided for @expAdvanced.
  ///
  /// In es, this message translates to:
  /// **'avanzado'**
  String get expAdvanced;

  /// No description provided for @progressTitle.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get progressTitle;

  /// No description provided for @progressMyTrainerLabel.
  ///
  /// In es, this message translates to:
  /// **'Tu entrenador personal'**
  String get progressMyTrainerLabel;

  /// No description provided for @progressTotalXp.
  ///
  /// In es, this message translates to:
  /// **'{total} XP totales'**
  String progressTotalXp(int total);

  /// No description provided for @progressXpToNext.
  ///
  /// In es, this message translates to:
  /// **'Faltan {remaining} XP para nivel {level}'**
  String progressXpToNext(int remaining, int level);

  /// No description provided for @progressStatsNewPrs.
  ///
  /// In es, this message translates to:
  /// **'PRs nuevos'**
  String get progressStatsNewPrs;

  /// No description provided for @progressStatsMonthlyWorkouts.
  ///
  /// In es, this message translates to:
  /// **'Entrenos del mes'**
  String get progressStatsMonthlyWorkouts;

  /// No description provided for @progressStatsMonthlyVolume.
  ///
  /// In es, this message translates to:
  /// **'Volumen del mes'**
  String get progressStatsMonthlyVolume;

  /// No description provided for @progressStatsMonthlyPrs.
  ///
  /// In es, this message translates to:
  /// **'PRs del mes'**
  String get progressStatsMonthlyPrs;

  /// No description provided for @progressStreakWeeks.
  ///
  /// In es, this message translates to:
  /// **'{count} sem'**
  String progressStreakWeeks(int count);

  /// No description provided for @progressRecentPrs.
  ///
  /// In es, this message translates to:
  /// **'PRs recientes'**
  String get progressRecentPrs;

  /// No description provided for @progressAllRecords.
  ///
  /// In es, this message translates to:
  /// **'Todos los récords'**
  String get progressAllRecords;

  /// No description provided for @progressNewPrBadge.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get progressNewPrBadge;

  /// No description provided for @progressVolumeTrend.
  ///
  /// In es, this message translates to:
  /// **'Tendencia de volumen'**
  String get progressVolumeTrend;

  /// No description provided for @progressBodyTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuerpo'**
  String get progressBodyTitle;

  /// No description provided for @progressMilestoneNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente: {target}'**
  String progressMilestoneNext(String target);

  /// No description provided for @playerLevelTitle.
  ///
  /// In es, this message translates to:
  /// **'Nivel {level}'**
  String playerLevelTitle(int level);

  /// No description provided for @playerXpProgress.
  ///
  /// In es, this message translates to:
  /// **'{current} / {total} XP'**
  String playerXpProgress(int current, int total);

  /// No description provided for @playerLevelMax.
  ///
  /// In es, this message translates to:
  /// **'Nivel máximo alcanzado'**
  String get playerLevelMax;

  /// No description provided for @playerLevelTierMythic.
  ///
  /// In es, this message translates to:
  /// **'Mítico'**
  String get playerLevelTierMythic;

  /// No description provided for @playerLevelTierImmortal.
  ///
  /// In es, this message translates to:
  /// **'Inmortal'**
  String get playerLevelTierImmortal;

  /// No description provided for @xpEarned.
  ///
  /// In es, this message translates to:
  /// **'+{xp} XP'**
  String xpEarned(int xp);

  /// No description provided for @levelUp.
  ///
  /// In es, this message translates to:
  /// **'¡Subiste de nivel!'**
  String get levelUp;

  /// No description provided for @rankUp.
  ///
  /// In es, this message translates to:
  /// **'¡Nuevo rango!'**
  String get rankUp;

  /// No description provided for @shareRankUp.
  ///
  /// In es, this message translates to:
  /// **'⭐ ¡Ascendiste a {rank}! (Nivel {level})'**
  String shareRankUp(String rank, int level);

  /// No description provided for @streakXpBonus.
  ///
  /// In es, this message translates to:
  /// **'Bonus racha ×{multiplier}'**
  String streakXpBonus(String multiplier);

  /// No description provided for @workouts30d.
  ///
  /// In es, this message translates to:
  /// **'Entrenos (30 d)'**
  String get workouts30d;

  /// No description provided for @volume30d.
  ///
  /// In es, this message translates to:
  /// **'Volumen (30 d)'**
  String get volume30d;

  /// No description provided for @progressLast7Days.
  ///
  /// In es, this message translates to:
  /// **'Últimos 7 días'**
  String get progressLast7Days;

  /// No description provided for @progressAllTime.
  ///
  /// In es, this message translates to:
  /// **'Histórico'**
  String get progressAllTime;

  /// No description provided for @progressWorkoutsLabel.
  ///
  /// In es, this message translates to:
  /// **'Entrenos'**
  String get progressWorkoutsLabel;

  /// No description provided for @progressVolumeLabel.
  ///
  /// In es, this message translates to:
  /// **'Volumen'**
  String get progressVolumeLabel;

  /// No description provided for @progressCaloriesLabel.
  ///
  /// In es, this message translates to:
  /// **'Calorías'**
  String get progressCaloriesLabel;

  /// No description provided for @volumePerWorkout.
  ///
  /// In es, this message translates to:
  /// **'Volumen por día'**
  String get volumePerWorkout;

  /// No description provided for @last10Days.
  ///
  /// In es, this message translates to:
  /// **'Últimos 10 días'**
  String get last10Days;

  /// No description provided for @completeWorkoutsForVolume.
  ///
  /// In es, this message translates to:
  /// **'Completa entrenamientos para ver tu volumen'**
  String get completeWorkoutsForVolume;

  /// No description provided for @milestonesTitle.
  ///
  /// In es, this message translates to:
  /// **'Medallas'**
  String get milestonesTitle;

  /// No description provided for @milestonesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Desbloquea medallas al alcanzar metas acumuladas'**
  String get milestonesSubtitle;

  /// No description provided for @milestoneCategoryReps.
  ///
  /// In es, this message translates to:
  /// **'Reps'**
  String get milestoneCategoryReps;

  /// No description provided for @milestoneCategoryVolume.
  ///
  /// In es, this message translates to:
  /// **'Volumen'**
  String get milestoneCategoryVolume;

  /// No description provided for @milestoneCategoryDistance.
  ///
  /// In es, this message translates to:
  /// **'Distancia'**
  String get milestoneCategoryDistance;

  /// No description provided for @milestoneCategoryCalories.
  ///
  /// In es, this message translates to:
  /// **'Calorías'**
  String get milestoneCategoryCalories;

  /// No description provided for @milestoneCategoryWorkouts.
  ///
  /// In es, this message translates to:
  /// **'Entrenos'**
  String get milestoneCategoryWorkouts;

  /// No description provided for @milestoneTotal.
  ///
  /// In es, this message translates to:
  /// **'Total: {value}'**
  String milestoneTotal(String value);

  /// No description provided for @milestoneUnlockedCount.
  ///
  /// In es, this message translates to:
  /// **'{unlocked}/{total}'**
  String milestoneUnlockedCount(int unlocked, int total);

  /// No description provided for @milestoneNextTarget.
  ///
  /// In es, this message translates to:
  /// **'Siguiente meta: {target}'**
  String milestoneNextTarget(String target);

  /// No description provided for @milestoneDetailRemaining.
  ///
  /// In es, this message translates to:
  /// **'Faltan {remaining} para {target}'**
  String milestoneDetailRemaining(String remaining, String target);

  /// No description provided for @milestoneAllUnlocked.
  ///
  /// In es, this message translates to:
  /// **'¡Todas las medallas desbloqueadas!'**
  String get milestoneAllUnlocked;

  /// No description provided for @milestoneTierBronze.
  ///
  /// In es, this message translates to:
  /// **'Bronce'**
  String get milestoneTierBronze;

  /// No description provided for @milestoneTierSilver.
  ///
  /// In es, this message translates to:
  /// **'Plata'**
  String get milestoneTierSilver;

  /// No description provided for @milestoneTierGold.
  ///
  /// In es, this message translates to:
  /// **'Oro'**
  String get milestoneTierGold;

  /// No description provided for @milestoneTierPlatinum.
  ///
  /// In es, this message translates to:
  /// **'Platino'**
  String get milestoneTierPlatinum;

  /// No description provided for @milestoneTierDiamond.
  ///
  /// In es, this message translates to:
  /// **'Diamante'**
  String get milestoneTierDiamond;

  /// No description provided for @milestoneTierMaster.
  ///
  /// In es, this message translates to:
  /// **'Maestro'**
  String get milestoneTierMaster;

  /// No description provided for @milestoneTierGrandmaster.
  ///
  /// In es, this message translates to:
  /// **'Gran maestro'**
  String get milestoneTierGrandmaster;

  /// No description provided for @milestoneTierLegend.
  ///
  /// In es, this message translates to:
  /// **'Leyenda'**
  String get milestoneTierLegend;

  /// No description provided for @personalRecords.
  ///
  /// In es, this message translates to:
  /// **'Records personales'**
  String get personalRecords;

  /// No description provided for @all.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get all;

  /// No description provided for @noRecordsYet.
  ///
  /// In es, this message translates to:
  /// **'Completa entrenamientos para registrar PRs'**
  String get noRecordsYet;

  /// No description provided for @noRecordsForMuscle.
  ///
  /// In es, this message translates to:
  /// **'Sin records para {muscle}'**
  String noRecordsForMuscle(String muscle);

  /// No description provided for @oneRm.
  ///
  /// In es, this message translates to:
  /// **'1RM'**
  String get oneRm;

  /// No description provided for @exercisesTitle.
  ///
  /// In es, this message translates to:
  /// **'Ejercicios'**
  String get exercisesTitle;

  /// No description provided for @searchExercises.
  ///
  /// In es, this message translates to:
  /// **'Buscar ejercicios…'**
  String get searchExercises;

  /// No description provided for @exerciseCount.
  ///
  /// In es, this message translates to:
  /// **'{count} ejercicios'**
  String exerciseCount(int count);

  /// No description provided for @allCategories.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get allCategories;

  /// No description provided for @exerciseNotFound.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio no encontrado'**
  String get exerciseNotFound;

  /// No description provided for @exerciseDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio'**
  String get exerciseDetailTitle;

  /// No description provided for @instructions.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones'**
  String get instructions;

  /// No description provided for @watchDemoVideo.
  ///
  /// In es, this message translates to:
  /// **'Ver video demostrativo'**
  String get watchDemoVideo;

  /// No description provided for @fitforgeCatalog.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio del catálogo FitForge'**
  String get fitforgeCatalog;

  /// No description provided for @customExerciseTag.
  ///
  /// In es, this message translates to:
  /// **'Personalizado'**
  String get customExerciseTag;

  /// No description provided for @customExerciseAttribution.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio creado por ti en este dispositivo'**
  String get customExerciseAttribution;

  /// No description provided for @createCustomExercise.
  ///
  /// In es, this message translates to:
  /// **'Crear ejercicio personalizado'**
  String get createCustomExercise;

  /// No description provided for @myCustomExercises.
  ///
  /// In es, this message translates to:
  /// **'Mis ejercicios'**
  String get myCustomExercises;

  /// No description provided for @customExerciseName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del ejercicio'**
  String get customExerciseName;

  /// No description provided for @customExerciseMuscles.
  ///
  /// In es, this message translates to:
  /// **'Músculos trabajados'**
  String get customExerciseMuscles;

  /// No description provided for @customExercisePhoto.
  ///
  /// In es, this message translates to:
  /// **'Foto de la máquina (opcional)'**
  String get customExercisePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get chooseFromGallery;

  /// No description provided for @customExerciseSaved.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio personalizado guardado'**
  String get customExerciseSaved;

  /// No description provided for @customExerciseDeleted.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio personalizado eliminado'**
  String get customExerciseDeleted;

  /// No description provided for @deleteCustomExercise.
  ///
  /// In es, this message translates to:
  /// **'Eliminar ejercicio'**
  String get deleteCustomExercise;

  /// No description provided for @deleteCustomExerciseConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este ejercicio personalizado? Las rutinas guardadas conservarán el nombre.'**
  String get deleteCustomExerciseConfirm;

  /// No description provided for @customExerciseNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre para el ejercicio'**
  String get customExerciseNameRequired;

  /// No description provided for @customExerciseMusclesRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos un músculo'**
  String get customExerciseMusclesRequired;

  /// No description provided for @customExerciseLimitReached.
  ///
  /// In es, this message translates to:
  /// **'Límite de ejercicios personalizados alcanzado (100)'**
  String get customExerciseLimitReached;

  /// No description provided for @customExercisePerArmWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso por brazo'**
  String get customExercisePerArmWeight;

  /// No description provided for @customExercisePerArmWeightHint.
  ///
  /// In es, this message translates to:
  /// **'Registra el peso de cada mancuerna o lado. El volumen suma ambos brazos (×2).'**
  String get customExercisePerArmWeightHint;

  /// No description provided for @weightPerArm.
  ///
  /// In es, this message translates to:
  /// **'{unit} (por brazo)'**
  String weightPerArm(String unit);

  /// No description provided for @wgerAttribution.
  ///
  /// In es, this message translates to:
  /// **'Imágenes y videos de wger.de (CC-BY-SA)'**
  String get wgerAttribution;

  /// No description provided for @loadingImage.
  ///
  /// In es, this message translates to:
  /// **'Cargando imagen…'**
  String get loadingImage;

  /// No description provided for @metricWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso'**
  String get metricWeight;

  /// No description provided for @metricBmi.
  ///
  /// In es, this message translates to:
  /// **'Índice de masa corporal'**
  String get metricBmi;

  /// No description provided for @metricBodyFat.
  ///
  /// In es, this message translates to:
  /// **'Grasa corporal'**
  String get metricBodyFat;

  /// No description provided for @metricSkeletalMuscle.
  ///
  /// In es, this message translates to:
  /// **'Músculo esquelético'**
  String get metricSkeletalMuscle;

  /// No description provided for @metricFatFreeMass.
  ///
  /// In es, this message translates to:
  /// **'Peso corporal sin grasa'**
  String get metricFatFreeMass;

  /// No description provided for @metricSubcutaneousFat.
  ///
  /// In es, this message translates to:
  /// **'Grasa subcutánea'**
  String get metricSubcutaneousFat;

  /// No description provided for @metricVisceralFat.
  ///
  /// In es, this message translates to:
  /// **'Grasa visceral'**
  String get metricVisceralFat;

  /// No description provided for @metricBodyWater.
  ///
  /// In es, this message translates to:
  /// **'Agua corporal'**
  String get metricBodyWater;

  /// No description provided for @metricMuscleMass.
  ///
  /// In es, this message translates to:
  /// **'Masa muscular'**
  String get metricMuscleMass;

  /// No description provided for @metricBoneMass.
  ///
  /// In es, this message translates to:
  /// **'Masa ósea'**
  String get metricBoneMass;

  /// No description provided for @metricProtein.
  ///
  /// In es, this message translates to:
  /// **'Proteína'**
  String get metricProtein;

  /// No description provided for @metricBmr.
  ///
  /// In es, this message translates to:
  /// **'Tasa metabólica basal'**
  String get metricBmr;

  /// No description provided for @metricCalculatedAutomatically.
  ///
  /// In es, this message translates to:
  /// **'Calculado automáticamente'**
  String get metricCalculatedAutomatically;

  /// No description provided for @bodyMetricColorLegendTitle.
  ///
  /// In es, this message translates to:
  /// **'Leyenda de colores'**
  String get bodyMetricColorLegendTitle;

  /// No description provided for @bodyMetricColorLegendNote.
  ///
  /// In es, this message translates to:
  /// **'Aplica a peso, IMC, grasa corporal y grasa subcutánea.'**
  String get bodyMetricColorLegendNote;

  /// No description provided for @bodyMetricHealthVeryLow.
  ///
  /// In es, this message translates to:
  /// **'Muy bajo'**
  String get bodyMetricHealthVeryLow;

  /// No description provided for @bodyMetricHealthLow.
  ///
  /// In es, this message translates to:
  /// **'Bajo'**
  String get bodyMetricHealthLow;

  /// No description provided for @bodyMetricHealthAppropriate.
  ///
  /// In es, this message translates to:
  /// **'Adecuado'**
  String get bodyMetricHealthAppropriate;

  /// No description provided for @bodyMetricHealthIdeal.
  ///
  /// In es, this message translates to:
  /// **'Ideal'**
  String get bodyMetricHealthIdeal;

  /// No description provided for @bodyMetricHealthHigh.
  ///
  /// In es, this message translates to:
  /// **'Alto'**
  String get bodyMetricHealthHigh;

  /// No description provided for @bodyMetricHealthVeryBad.
  ///
  /// In es, this message translates to:
  /// **'Muy alto'**
  String get bodyMetricHealthVeryBad;

  /// No description provided for @metricMetabolicAge.
  ///
  /// In es, this message translates to:
  /// **'Edad metabólica'**
  String get metricMetabolicAge;

  /// No description provided for @muscleChest.
  ///
  /// In es, this message translates to:
  /// **'Pecho'**
  String get muscleChest;

  /// No description provided for @muscleBack.
  ///
  /// In es, this message translates to:
  /// **'Espalda'**
  String get muscleBack;

  /// No description provided for @muscleShoulders.
  ///
  /// In es, this message translates to:
  /// **'Hombros'**
  String get muscleShoulders;

  /// No description provided for @muscleBiceps.
  ///
  /// In es, this message translates to:
  /// **'Bíceps'**
  String get muscleBiceps;

  /// No description provided for @muscleTriceps.
  ///
  /// In es, this message translates to:
  /// **'Tríceps'**
  String get muscleTriceps;

  /// No description provided for @muscleLegs.
  ///
  /// In es, this message translates to:
  /// **'Piernas'**
  String get muscleLegs;

  /// No description provided for @muscleGlutes.
  ///
  /// In es, this message translates to:
  /// **'Glúteos'**
  String get muscleGlutes;

  /// No description provided for @muscleAbs.
  ///
  /// In es, this message translates to:
  /// **'Abdominales'**
  String get muscleAbs;

  /// No description provided for @muscleForearms.
  ///
  /// In es, this message translates to:
  /// **'Antebrazos'**
  String get muscleForearms;

  /// No description provided for @muscleCardio.
  ///
  /// In es, this message translates to:
  /// **'Cardio'**
  String get muscleCardio;

  /// No description provided for @muscleCalves.
  ///
  /// In es, this message translates to:
  /// **'Pantorrillas'**
  String get muscleCalves;

  /// No description provided for @workoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Entreno'**
  String get workoutTitle;

  /// No description provided for @routinesTitle.
  ///
  /// In es, this message translates to:
  /// **'Rutinas'**
  String get routinesTitle;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginTitle;

  /// No description provided for @socialTitle.
  ///
  /// In es, this message translates to:
  /// **'Social'**
  String get socialTitle;

  /// No description provided for @socialHeroTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu círculo'**
  String get socialHeroTitle;

  /// No description provided for @socialHeroSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Entrenad juntos, subid de nivel'**
  String get socialHeroSubtitle;

  /// No description provided for @socialHeroFriends.
  ///
  /// In es, this message translates to:
  /// **'{count} amigos'**
  String socialHeroFriends(int count);

  /// No description provided for @socialHeroPending.
  ///
  /// In es, this message translates to:
  /// **'{count} pendientes'**
  String socialHeroPending(int count);

  /// No description provided for @socialHeroRank.
  ///
  /// In es, this message translates to:
  /// **'#{rank} entre amigos'**
  String socialHeroRank(int rank);

  /// No description provided for @socialHeroRankGlobal.
  ///
  /// In es, this message translates to:
  /// **'#{rank} global'**
  String socialHeroRankGlobal(int rank);

  /// No description provided for @socialHeroNoRank.
  ///
  /// In es, this message translates to:
  /// **'Compite con tus amigos'**
  String get socialHeroNoRank;

  /// No description provided for @socialTabFriends.
  ///
  /// In es, this message translates to:
  /// **'Amigos'**
  String get socialTabFriends;

  /// No description provided for @socialTabFeed.
  ///
  /// In es, this message translates to:
  /// **'Feed'**
  String get socialTabFeed;

  /// No description provided for @socialTabLeaderboards.
  ///
  /// In es, this message translates to:
  /// **'Clasificaciones'**
  String get socialTabLeaderboards;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu feed está vacío'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuando tú o tus amigos entrenen, suban de nivel o desbloqueen medallas, lo verás aquí. Las publicaciones duran 24 horas.'**
  String get feedEmptySubtitle;

  /// No description provided for @feedExpiryHint.
  ///
  /// In es, this message translates to:
  /// **'Solo se muestran publicaciones de las últimas 24 horas.'**
  String get feedExpiryHint;

  /// No description provided for @feedLongPressToReact.
  ///
  /// In es, this message translates to:
  /// **'Mantén pulsado una publicación para reaccionar.'**
  String get feedLongPressToReact;

  /// No description provided for @feedMilestoneUnlock.
  ///
  /// In es, this message translates to:
  /// **'{name} desbloqueó medalla {category} — {tier}'**
  String feedMilestoneUnlock(String name, String category, String tier);

  /// No description provided for @feedLevelUp.
  ///
  /// In es, this message translates to:
  /// **'{name} subió al nivel {level}'**
  String feedLevelUp(String name, int level);

  /// No description provided for @feedPrUnlock.
  ///
  /// In es, this message translates to:
  /// **'{name} batió un récord en {exercise}: {value}'**
  String feedPrUnlock(String name, String exercise, String value);

  /// No description provided for @feedPrUnlockSelf.
  ///
  /// In es, this message translates to:
  /// **'Batiste un récord en {exercise}: {value}'**
  String feedPrUnlockSelf(String exercise, String value);

  /// No description provided for @feedMilestoneUnlockSelf.
  ///
  /// In es, this message translates to:
  /// **'Desbloqueaste la medalla {category} — {tier}'**
  String feedMilestoneUnlockSelf(String category, String tier);

  /// No description provided for @feedLevelUpSelf.
  ///
  /// In es, this message translates to:
  /// **'Subiste al nivel {level}'**
  String feedLevelUpSelf(int level);

  /// No description provided for @feedWorkoutCompletedSelf.
  ///
  /// In es, this message translates to:
  /// **'Completaste \"{workout}\"'**
  String feedWorkoutCompletedSelf(String workout);

  /// No description provided for @feedSharePrTitle.
  ///
  /// In es, this message translates to:
  /// **'Compartir en el feed'**
  String get feedSharePrTitle;

  /// No description provided for @feedSharePrSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige qué récords quieren ver tus amigos. Se publican al cerrar.'**
  String get feedSharePrSubtitle;

  /// No description provided for @feedPrShared.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 récord compartido en el feed de tus amigos} other{{count} récords compartidos en el feed de tus amigos}}'**
  String feedPrShared(int count);

  /// No description provided for @feedPrShareFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo compartir en el feed. Inténtalo de nuevo.'**
  String get feedPrShareFailed;

  /// No description provided for @leaderboardLoadMore.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get leaderboardLoadMore;

  /// No description provided for @leaderboardsTitle.
  ///
  /// In es, this message translates to:
  /// **'Clasificaciones'**
  String get leaderboardsTitle;

  /// No description provided for @leaderboardScopeFriends.
  ///
  /// In es, this message translates to:
  /// **'Amigos'**
  String get leaderboardScopeFriends;

  /// No description provided for @leaderboardScopeGlobal.
  ///
  /// In es, this message translates to:
  /// **'Global'**
  String get leaderboardScopeGlobal;

  /// No description provided for @leaderboardMetricLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel'**
  String get leaderboardMetricLevel;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay datos en este ranking.'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardYourPosition.
  ///
  /// In es, this message translates to:
  /// **'Tu posición'**
  String get leaderboardYourPosition;

  /// No description provided for @leaderboardPeriodWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get leaderboardPeriodWeek;

  /// No description provided for @leaderboardPeriodMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get leaderboardPeriodMonth;

  /// No description provided for @leaderboardPeriodAll.
  ///
  /// In es, this message translates to:
  /// **'Histórico'**
  String get leaderboardPeriodAll;

  /// No description provided for @leaderboardPeriodXp.
  ///
  /// In es, this message translates to:
  /// **'{xp} XP'**
  String leaderboardPeriodXp(int xp);

  /// No description provided for @rankYou.
  ///
  /// In es, this message translates to:
  /// **'{name} (tú)'**
  String rankYou(String name);

  /// No description provided for @loginTagline.
  ///
  /// In es, this message translates to:
  /// **'Forja tu mejor versión'**
  String get loginTagline;

  /// No description provided for @createAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get signIn;

  /// No description provided for @name.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get name;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get passwordsDoNotMatch;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige una contraseña segura para tu cuenta de FitForge.'**
  String get resetPasswordSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get newPassword;

  /// No description provided for @resetPasswordAction.
  ///
  /// In es, this message translates to:
  /// **'Actualizar contraseña'**
  String get resetPasswordAction;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada correctamente'**
  String get resetPasswordSuccess;

  /// No description provided for @resetPasswordFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar la contraseña. Pide un enlace nuevo e inténtalo otra vez.'**
  String get resetPasswordFailed;

  /// No description provided for @resetPasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get resetPasswordTooShort;

  /// No description provided for @enter.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get enter;

  /// No description provided for @continueWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get continueWithGoogle;

  /// No description provided for @orContinueWith.
  ///
  /// In es, this message translates to:
  /// **'o continúa con'**
  String get orContinueWith;

  /// No description provided for @googleSignInCancelled.
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión con Google cancelado'**
  String get googleSignInCancelled;

  /// No description provided for @googleSignInFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión con Google. Inténtalo de nuevo.'**
  String get googleSignInFailed;

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// No description provided for @completeSecurityVerification.
  ///
  /// In es, this message translates to:
  /// **'Completa la verificación de seguridad'**
  String get completeSecurityVerification;

  /// No description provided for @authError.
  ///
  /// In es, this message translates to:
  /// **'Error de autenticación. Revisa tus datos e inténtalo de nuevo.'**
  String get authError;

  /// No description provided for @enterEmailFirst.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu email primero'**
  String get enterEmailFirst;

  /// No description provided for @passwordResetSent.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un enlace para restablecer la contraseña'**
  String get passwordResetSent;

  /// No description provided for @passwordResetFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el email de recuperación'**
  String get passwordResetFailed;

  /// No description provided for @haveAccountSignIn.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get haveAccountSignIn;

  /// No description provided for @noAccountSignUp.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get noAccountSignUp;

  /// No description provided for @history.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get history;

  /// No description provided for @noWorkoutsYet.
  ///
  /// In es, this message translates to:
  /// **'Sin entrenamientos aún. ¡Empieza hoy!'**
  String get noWorkoutsYet;

  /// No description provided for @startToday.
  ///
  /// In es, this message translates to:
  /// **'Sin entrenamientos aún. ¡Empieza hoy!'**
  String get startToday;

  /// No description provided for @viewFullHistory.
  ///
  /// In es, this message translates to:
  /// **'Ver historial completo'**
  String get viewFullHistory;

  /// No description provided for @activeWorkout.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento en curso'**
  String get activeWorkout;

  /// No description provided for @streakLabel.
  ///
  /// In es, this message translates to:
  /// **'Racha'**
  String get streakLabel;

  /// No description provided for @streakWeekly.
  ///
  /// In es, this message translates to:
  /// **'Racha (≥4/sem)'**
  String get streakWeekly;

  /// No description provided for @streakWeeksSubtitle.
  ///
  /// In es, this message translates to:
  /// **'semanas de racha (≥4/sem)'**
  String get streakWeeksSubtitle;

  /// No description provided for @thisWeek.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get thisWeek;

  /// No description provided for @weeklyWorkoutsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'de {goal} entrenamientos esta semana'**
  String weeklyWorkoutsSubtitle(int goal);

  /// No description provided for @trainHeroReadyTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Listo para entrenar?'**
  String get trainHeroReadyTitle;

  /// No description provided for @trainHeroGoalMetTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Meta semanal cumplida!'**
  String get trainHeroGoalMetTitle;

  /// No description provided for @trainHeroStreakWeeks.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{¡Racha de 1 semana!} other{¡Racha de {count} semanas!}}'**
  String trainHeroStreakWeeks(int count);

  /// No description provided for @trainWorkoutsRemaining.
  ///
  /// In es, this message translates to:
  /// **'{remaining, plural, =1{Te falta 1 entreno esta semana} other{Te faltan {remaining} entrenos esta semana}}'**
  String trainWorkoutsRemaining(int remaining);

  /// No description provided for @trainWeeklyProgress.
  ///
  /// In es, this message translates to:
  /// **'{current} de {goal} esta semana'**
  String trainWeeklyProgress(int current, int goal);

  /// No description provided for @trainSuggestedTitle.
  ///
  /// In es, this message translates to:
  /// **'Siguiente entreno sugerido'**
  String get trainSuggestedTitle;

  /// No description provided for @trainSuggestedLastRoutine.
  ///
  /// In es, this message translates to:
  /// **'Retoma tu última rutina'**
  String get trainSuggestedLastRoutine;

  /// No description provided for @trainSuggestedRecovery.
  ///
  /// In es, this message translates to:
  /// **'Músculos listos para esta sesión'**
  String get trainSuggestedRecovery;

  /// No description provided for @trainSuggestedDefault.
  ///
  /// In es, this message translates to:
  /// **'Un buen punto de partida'**
  String get trainSuggestedDefault;

  /// No description provided for @trainStartSuggested.
  ///
  /// In es, this message translates to:
  /// **'Empezar entreno'**
  String get trainStartSuggested;

  /// No description provided for @recoveryViewDetail.
  ///
  /// In es, this message translates to:
  /// **'Ver detalle'**
  String get recoveryViewDetail;

  /// No description provided for @recoveryTopFatigued.
  ///
  /// In es, this message translates to:
  /// **'Más fatigados'**
  String get recoveryTopFatigued;

  /// No description provided for @recoveryDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperación muscular'**
  String get recoveryDetailTitle;

  /// No description provided for @trainRecentWorkouts.
  ///
  /// In es, this message translates to:
  /// **'Recientes'**
  String get trainRecentWorkouts;

  /// No description provided for @trainSwipeRepeat.
  ///
  /// In es, this message translates to:
  /// **'Repetir'**
  String get trainSwipeRepeat;

  /// No description provided for @trainVolumePr.
  ///
  /// In es, this message translates to:
  /// **'Mejor volumen'**
  String get trainVolumePr;

  /// No description provided for @startWorkout.
  ///
  /// In es, this message translates to:
  /// **'Iniciar entrenamiento'**
  String get startWorkout;

  /// No description provided for @startingWorkout.
  ///
  /// In es, this message translates to:
  /// **'Iniciando entrenamiento…'**
  String get startingWorkout;

  /// No description provided for @startWorkoutError.
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar entrenamiento: {message}'**
  String startWorkoutError(String message);

  /// No description provided for @freeWorkout.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento libre'**
  String get freeWorkout;

  /// No description provided for @loadingRoutines.
  ///
  /// In es, this message translates to:
  /// **'Cargando rutinas...'**
  String get loadingRoutines;

  /// No description provided for @exercisesInRoutine.
  ///
  /// In es, this message translates to:
  /// **'{count} ejercicios'**
  String exercisesInRoutine(int count);

  /// No description provided for @noWorkoutsRegistered.
  ///
  /// In es, this message translates to:
  /// **'Sin entrenamientos registrados'**
  String get noWorkoutsRegistered;

  /// No description provided for @summaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get summaryTitle;

  /// No description provided for @summaryWorkoutComplete.
  ///
  /// In es, this message translates to:
  /// **'¡Entreno completado!'**
  String get summaryWorkoutComplete;

  /// No description provided for @summaryVolumeUp.
  ///
  /// In es, this message translates to:
  /// **'+{percent}% volumen vs última vez'**
  String summaryVolumeUp(String percent);

  /// No description provided for @summaryMusclesTrained.
  ///
  /// In es, this message translates to:
  /// **'Músculos trabajados'**
  String get summaryMusclesTrained;

  /// No description provided for @summaryPersonalRecords.
  ///
  /// In es, this message translates to:
  /// **'Récords personales nuevos'**
  String get summaryPersonalRecords;

  /// No description provided for @summaryPersonalRecordBadge.
  ///
  /// In es, this message translates to:
  /// **'PR'**
  String get summaryPersonalRecordBadge;

  /// No description provided for @summaryExerciseImproved.
  ///
  /// In es, this message translates to:
  /// **'Mejor que la última vez'**
  String get summaryExerciseImproved;

  /// No description provided for @vsLastTime.
  ///
  /// In es, this message translates to:
  /// **'vs última vez ({name})'**
  String vsLastTime(String name);

  /// No description provided for @exercisesCompleted.
  ///
  /// In es, this message translates to:
  /// **'Ejercicios realizados'**
  String get exercisesCompleted;

  /// No description provided for @setsReps.
  ///
  /// In es, this message translates to:
  /// **'{sets} series · {reps} reps'**
  String setsReps(int sets, int reps);

  /// No description provided for @best.
  ///
  /// In es, this message translates to:
  /// **'mejor: {value}'**
  String best(String value);

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @before.
  ///
  /// In es, this message translates to:
  /// **'Antes'**
  String get before;

  /// No description provided for @recordLabel.
  ///
  /// In es, this message translates to:
  /// **'Récord: {name}'**
  String recordLabel(String name);

  /// No description provided for @durationMinutesExercises.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min · {count} ejercicios'**
  String durationMinutesExercises(int minutes, int count);

  /// No description provided for @caloriesBurned.
  ///
  /// In es, this message translates to:
  /// **'Calorías'**
  String get caloriesBurned;

  /// No description provided for @caloriesKcal.
  ///
  /// In es, this message translates to:
  /// **'{value} kcal'**
  String caloriesKcal(int value);

  /// No description provided for @caloriesEstimateNote.
  ///
  /// In es, this message translates to:
  /// **'Calorías activas estimadas (extra del entreno; el reposo basal ya está en tu meta diaria).'**
  String get caloriesEstimateNote;

  /// No description provided for @caloriesEstimateDefaultWeight.
  ///
  /// In es, this message translates to:
  /// **'Estimación con peso de referencia (70 kg). Añade tu peso en el perfil para mayor precisión.'**
  String get caloriesEstimateDefaultWeight;

  /// No description provided for @training.
  ///
  /// In es, this message translates to:
  /// **'Entrenando'**
  String get training;

  /// No description provided for @finish.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get finish;

  /// No description provided for @cancelWorkout.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelWorkout;

  /// No description provided for @cancelWorkoutTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar entrenamiento?'**
  String get cancelWorkoutTitle;

  /// No description provided for @cancelWorkoutMessage.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará este entrenamiento y no aparecerá en tu historial. No se puede deshacer.'**
  String get cancelWorkoutMessage;

  /// No description provided for @cancelWorkoutConfirm.
  ///
  /// In es, this message translates to:
  /// **'Cancelar entrenamiento'**
  String get cancelWorkoutConfirm;

  /// No description provided for @cancelWorkoutBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get cancelWorkoutBack;

  /// No description provided for @workoutCancelled.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento cancelado'**
  String get workoutCancelled;

  /// No description provided for @cancelWorkoutFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cancelar el entrenamiento: {message}'**
  String cancelWorkoutFailed(String message);

  /// No description provided for @leaveActiveWorkoutTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Salir del entrenamiento?'**
  String get leaveActiveWorkoutTitle;

  /// No description provided for @leaveActiveWorkoutMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu progreso se guarda. Puedes volver a entrar desde Entrenar.'**
  String get leaveActiveWorkoutMessage;

  /// No description provided for @leaveActiveWorkoutConfirm.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get leaveActiveWorkoutConfirm;

  /// No description provided for @viewList.
  ///
  /// In es, this message translates to:
  /// **'Ver lista'**
  String get viewList;

  /// No description provided for @exerciseList.
  ///
  /// In es, this message translates to:
  /// **'Lista de ejercicios'**
  String get exerciseList;

  /// No description provided for @noActiveWorkout.
  ///
  /// In es, this message translates to:
  /// **'No hay entrenamiento activo'**
  String get noActiveWorkout;

  /// No description provided for @addSet.
  ///
  /// In es, this message translates to:
  /// **'Añadir serie'**
  String get addSet;

  /// No description provided for @previous.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @exerciseProgress.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio {current} de {total}'**
  String exerciseProgress(int current, int total);

  /// No description provided for @exerciseAdded.
  ///
  /// In es, this message translates to:
  /// **'{name} añadido'**
  String exerciseAdded(String name);

  /// No description provided for @addingExercise.
  ///
  /// In es, this message translates to:
  /// **'Añadiendo ejercicio…'**
  String get addingExercise;

  /// No description provided for @exerciseRemoved.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio eliminado'**
  String get exerciseRemoved;

  /// No description provided for @exerciseDeleteFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar: {message}'**
  String exerciseDeleteFailed(String message);

  /// No description provided for @changedTo.
  ///
  /// In es, this message translates to:
  /// **'Cambiado a {name}'**
  String changedTo(String name);

  /// No description provided for @finishFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo finalizar: {message}'**
  String finishFailed(String message);

  /// No description provided for @weightRequired.
  ///
  /// In es, this message translates to:
  /// **'Indica el peso antes de marcar la serie como hecha'**
  String get weightRequired;

  /// No description provided for @weightAdditionalSuffix.
  ///
  /// In es, this message translates to:
  /// **'(+ adicional)'**
  String get weightAdditionalSuffix;

  /// No description provided for @weightPerArmSuffix.
  ///
  /// In es, this message translates to:
  /// **'(por brazo)'**
  String get weightPerArmSuffix;

  /// No description provided for @loadModePerArm.
  ///
  /// In es, this message translates to:
  /// **'Por brazo'**
  String get loadModePerArm;

  /// No description provided for @loadModeCombined.
  ///
  /// In es, this message translates to:
  /// **'Conjunto'**
  String get loadModeCombined;

  /// No description provided for @loadModeToggleHint.
  ///
  /// In es, this message translates to:
  /// **'Alterna si trabajas ambos lados a la vez o por separado'**
  String get loadModeToggleHint;

  /// No description provided for @bodyweightLoadHint.
  ///
  /// In es, this message translates to:
  /// **'Tu peso corporal ({weight}) cuenta por defecto. El campo es carga adicional.'**
  String bodyweightLoadHint(String weight);

  /// No description provided for @effectiveWeightLabel.
  ///
  /// In es, this message translates to:
  /// **'Peso total: {weight}'**
  String effectiveWeightLabel(String weight);

  /// No description provided for @reportExerciseProblem.
  ///
  /// In es, this message translates to:
  /// **'Reportar problema con este ejercicio'**
  String get reportExerciseProblem;

  /// No description provided for @exerciseReportTitle.
  ///
  /// In es, this message translates to:
  /// **'Reportar problema'**
  String get exerciseReportTitle;

  /// No description provided for @exerciseReportSubmit.
  ///
  /// In es, this message translates to:
  /// **'Enviar reporte'**
  String get exerciseReportSubmit;

  /// No description provided for @exerciseReportThanks.
  ///
  /// In es, this message translates to:
  /// **'Gracias, revisaremos tu reporte'**
  String get exerciseReportThanks;

  /// No description provided for @exerciseReportWrongMetrics.
  ///
  /// In es, this message translates to:
  /// **'Métricas incorrectas (peso/reps)'**
  String get exerciseReportWrongMetrics;

  /// No description provided for @exerciseReportWrongGif.
  ///
  /// In es, this message translates to:
  /// **'Imagen o GIF incorrecto'**
  String get exerciseReportWrongGif;

  /// No description provided for @exerciseReportWrongName.
  ///
  /// In es, this message translates to:
  /// **'Nombre o traducción incorrecta'**
  String get exerciseReportWrongName;

  /// No description provided for @exerciseReportWrongMuscles.
  ///
  /// In es, this message translates to:
  /// **'Músculos o categoría incorrecta'**
  String get exerciseReportWrongMuscles;

  /// No description provided for @exerciseReportOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get exerciseReportOther;

  /// No description provided for @exerciseReportNotes.
  ///
  /// In es, this message translates to:
  /// **'Detalles (opcional)'**
  String get exerciseReportNotes;

  /// No description provided for @repsRequired.
  ///
  /// In es, this message translates to:
  /// **'Indica las repeticiones'**
  String get repsRequired;

  /// No description provided for @setDeleteFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar la serie: {message}'**
  String setDeleteFailed(String message);

  /// No description provided for @exerciseHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial del ejercicio'**
  String get exerciseHistory;

  /// No description provided for @reps.
  ///
  /// In es, this message translates to:
  /// **'Reps'**
  String get reps;

  /// No description provided for @done.
  ///
  /// In es, this message translates to:
  /// **'Hecho'**
  String get done;

  /// No description provided for @rirPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuántas repeticiones más pudiste haber hecho?'**
  String get rirPickerTitle;

  /// No description provided for @rirPickerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Reps en reserva (RIR) del último set. La IA usará esto para ajustar tu próximo entreno.'**
  String get rirPickerSubtitle;

  /// No description provided for @rirPickerRepsLeft.
  ///
  /// In es, this message translates to:
  /// **'reps más'**
  String get rirPickerRepsLeft;

  /// No description provided for @rirPickerSkip.
  ///
  /// In es, this message translates to:
  /// **'Omitir'**
  String get rirPickerSkip;

  /// No description provided for @newRoutine.
  ///
  /// In es, this message translates to:
  /// **'Nueva rutina'**
  String get newRoutine;

  /// No description provided for @generateWithAi.
  ///
  /// In es, this message translates to:
  /// **'Generar con IA'**
  String get generateWithAi;

  /// No description provided for @noRoutines.
  ///
  /// In es, this message translates to:
  /// **'Sin rutinas creadas'**
  String get noRoutines;

  /// No description provided for @createRoutine.
  ///
  /// In es, this message translates to:
  /// **'Crear rutina'**
  String get createRoutine;

  /// No description provided for @generateAiRoutineTitle.
  ///
  /// In es, this message translates to:
  /// **'Generar rutina con IA'**
  String get generateAiRoutineTitle;

  /// No description provided for @targetMuscles.
  ///
  /// In es, this message translates to:
  /// **'Músculos (ej: Pecho, Tríceps)'**
  String get targetMuscles;

  /// No description provided for @durationMin.
  ///
  /// In es, this message translates to:
  /// **'Duración (min)'**
  String get durationMin;

  /// No description provided for @routineGenerated.
  ///
  /// In es, this message translates to:
  /// **'Rutina generada y guardada'**
  String get routineGenerated;

  /// No description provided for @alreadyInRoutine.
  ///
  /// In es, this message translates to:
  /// **'\"{name}\" ya está en la rutina'**
  String alreadyInRoutine(String name);

  /// No description provided for @editRoutine.
  ///
  /// In es, this message translates to:
  /// **'Editar rutina'**
  String get editRoutine;

  /// No description provided for @routineName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la rutina'**
  String get routineName;

  /// No description provided for @description.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get description;

  /// No description provided for @discard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get discard;

  /// No description provided for @routineDiscarded.
  ///
  /// In es, this message translates to:
  /// **'Rutina descartada'**
  String get routineDiscarded;

  /// No description provided for @routineSaved.
  ///
  /// In es, this message translates to:
  /// **'Rutina guardada en Mis rutinas'**
  String get routineSaved;

  /// No description provided for @routineSavedNamed.
  ///
  /// In es, this message translates to:
  /// **'\"{name}\" guardada en Rutinas'**
  String routineSavedNamed(String name);

  /// No description provided for @routineFavorite.
  ///
  /// In es, this message translates to:
  /// **'Marcar como favorita'**
  String get routineFavorite;

  /// No description provided for @routineUnfavorite.
  ///
  /// In es, this message translates to:
  /// **'Quitar de favoritas'**
  String get routineUnfavorite;

  /// No description provided for @routineFavoritesMax.
  ///
  /// In es, this message translates to:
  /// **'Solo puedes tener {max} rutinas favoritas en tu perfil'**
  String routineFavoritesMax(int max);

  /// No description provided for @friendFavoriteRoutines.
  ///
  /// In es, this message translates to:
  /// **'Rutinas favoritas'**
  String get friendFavoriteRoutines;

  /// No description provided for @noFavoriteRoutinesFriend.
  ///
  /// In es, this message translates to:
  /// **'Este usuario no tiene rutinas favoritas públicas'**
  String get noFavoriteRoutinesFriend;

  /// No description provided for @previewRoutine.
  ///
  /// In es, this message translates to:
  /// **'Previsualizar rutina'**
  String get previewRoutine;

  /// No description provided for @saveRoutine.
  ///
  /// In es, this message translates to:
  /// **'Guardar rutina'**
  String get saveRoutine;

  /// No description provided for @shareRoutine.
  ///
  /// In es, this message translates to:
  /// **'Compartir rutina'**
  String get shareRoutine;

  /// No description provided for @shareRoutineTitle.
  ///
  /// In es, this message translates to:
  /// **'Enviar rutina a un amigo'**
  String get shareRoutineTitle;

  /// No description provided for @shareRoutineSelectFriend.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un amigo para enviarle esta rutina'**
  String get shareRoutineSelectFriend;

  /// No description provided for @shareRoutineSent.
  ///
  /// In es, this message translates to:
  /// **'Rutina enviada a {name}'**
  String shareRoutineSent(String name);

  /// No description provided for @shareRoutineFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo compartir: {message}'**
  String shareRoutineFailed(String message);

  /// No description provided for @shareRoutineNoFriends.
  ///
  /// In es, this message translates to:
  /// **'Agrega amigos para compartir rutinas'**
  String get shareRoutineNoFriends;

  /// No description provided for @routineShareAccepted.
  ///
  /// In es, this message translates to:
  /// **'Rutina guardada en tu biblioteca'**
  String get routineShareAccepted;

  /// No description provided for @routineShareDeclined.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de rutina rechazada'**
  String get routineShareDeclined;

  /// No description provided for @routineShareUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Esta solicitud ya no está disponible'**
  String get routineShareUnavailable;

  /// No description provided for @accept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get decline;

  /// No description provided for @saveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar: {message}'**
  String saveFailed(String message);

  /// No description provided for @moreExercises.
  ///
  /// In es, this message translates to:
  /// **'+ {count} ejercicios más'**
  String moreExercises(int count);

  /// No description provided for @exercisesSection.
  ///
  /// In es, this message translates to:
  /// **'Ejercicios ({count})'**
  String exercisesSection(int count);

  /// No description provided for @add.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get add;

  /// No description provided for @coachTitle.
  ///
  /// In es, this message translates to:
  /// **'Coach IA'**
  String get coachTitle;

  /// No description provided for @coachWelcome.
  ///
  /// In es, this message translates to:
  /// **'Tu entrenador personal con IA'**
  String get coachWelcome;

  /// No description provided for @coachWelcomeHint.
  ///
  /// In es, this message translates to:
  /// **'Pídele una rutina y la guardarás cuando estés listo.\nConfigura tu API key en Perfil.'**
  String get coachWelcomeHint;

  /// No description provided for @coachDailyLimitReached.
  ///
  /// In es, this message translates to:
  /// **'Has alcanzado el límite diario de {limit} mensajes del Coach IA. Mejora tu plan para más.'**
  String coachDailyLimitReached(int limit);

  /// No description provided for @coachDailyLimitRemaining.
  ///
  /// In es, this message translates to:
  /// **'{remaining} de {limit} mensajes hoy'**
  String coachDailyLimitRemaining(int remaining, int limit);

  /// No description provided for @routineLimitReached.
  ///
  /// In es, this message translates to:
  /// **'Has alcanzado el límite de {limit} rutinas de tu plan. Mejora tu plan para guardar más.'**
  String routineLimitReached(int limit);

  /// No description provided for @routineLimitUsage.
  ///
  /// In es, this message translates to:
  /// **'{used} de {limit} rutinas guardadas'**
  String routineLimitUsage(int used, int limit);

  /// No description provided for @coachAskHint.
  ///
  /// In es, this message translates to:
  /// **'Pregunta o pide una rutina…'**
  String get coachAskHint;

  /// No description provided for @coachRoutineReady.
  ///
  /// In es, this message translates to:
  /// **'Aquí tienes tu rutina. Revísala y pulsa Guardar cuando estés listo.'**
  String get coachRoutineReady;

  /// No description provided for @coachRoutinesReady.
  ///
  /// In es, this message translates to:
  /// **'Aquí tienes {count} rutinas para la semana. Revísalas y guarda las que quieras.'**
  String coachRoutinesReady(int count);

  /// No description provided for @coachRoutineTooFewExercises.
  ///
  /// In es, this message translates to:
  /// **'No pude armar una rutina variada con ejercicios del catálogo. Prueba pidiéndola de nuevo o elige músculos concretos.'**
  String get coachRoutineTooFewExercises;

  /// No description provided for @coachRoutineFailed.
  ///
  /// In es, this message translates to:
  /// **'No pude generar la rutina. Intenta ser más específico (músculos y duración).'**
  String get coachRoutineFailed;

  /// No description provided for @aiConnectionError.
  ///
  /// In es, this message translates to:
  /// **'Error en la conexión. Intenta de nuevo, por favor.'**
  String get aiConnectionError;

  /// No description provided for @coachNoRoutineToSave.
  ///
  /// In es, this message translates to:
  /// **'No hay ninguna rutina pendiente por guardar. Primero pídeme que cree una.'**
  String get coachNoRoutineToSave;

  /// No description provided for @coachSuggestion1.
  ///
  /// In es, this message translates to:
  /// **'Crea una rutina de piernas de 45 minutos'**
  String get coachSuggestion1;

  /// No description provided for @coachSuggestion2.
  ///
  /// In es, this message translates to:
  /// **'¿Qué ejercicios me recomiendas para pecho hoy?'**
  String get coachSuggestion2;

  /// No description provided for @coachSuggestion3.
  ///
  /// In es, this message translates to:
  /// **'Hazme una rutina de espalda y bíceps para guardar'**
  String get coachSuggestion3;

  /// No description provided for @coachSuggestion4.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo debería descansar cada grupo muscular?'**
  String get coachSuggestion4;

  /// No description provided for @requestSent.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada'**
  String get requestSent;

  /// No description provided for @requestFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar: {message}'**
  String requestFailed(String message);

  /// No description provided for @searchFailed.
  ///
  /// In es, this message translates to:
  /// **'Búsqueda falló: {message}'**
  String searchFailed(String message);

  /// No description provided for @markRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar leídas'**
  String get markRead;

  /// No description provided for @notifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notifications;

  /// No description provided for @pendingRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes pendientes'**
  String get pendingRequests;

  /// No description provided for @wantsToBeFriend.
  ///
  /// In es, this message translates to:
  /// **'Quiere ser tu amigo'**
  String get wantsToBeFriend;

  /// No description provided for @requestSentLabel.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada'**
  String get requestSentLabel;

  /// No description provided for @friendsCount.
  ///
  /// In es, this message translates to:
  /// **'Amigos ({count})'**
  String friendsCount(int count);

  /// No description provided for @searchFriendsHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por correo o nombre…'**
  String get searchFriendsHint;

  /// No description provided for @removeFriendTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar amigo'**
  String get removeFriendTitle;

  /// No description provided for @removeFriendBody.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar a {name} de tu lista?'**
  String removeFriendBody(String name);

  /// No description provided for @muteFriend.
  ///
  /// In es, this message translates to:
  /// **'Silenciar'**
  String get muteFriend;

  /// No description provided for @unmuteFriend.
  ///
  /// In es, this message translates to:
  /// **'Dejar de silenciar'**
  String get unmuteFriend;

  /// No description provided for @friendMutedLabel.
  ///
  /// In es, this message translates to:
  /// **'Silenciado'**
  String get friendMutedLabel;

  /// No description provided for @friendMuted.
  ///
  /// In es, this message translates to:
  /// **'{name} silenciado'**
  String friendMuted(String name);

  /// No description provided for @friendUnmuted.
  ///
  /// In es, this message translates to:
  /// **'{name} ya no está silenciado'**
  String friendUnmuted(String name);

  /// No description provided for @friendWorkoutNotify.
  ///
  /// In es, this message translates to:
  /// **'Cuando un amigo complete un entreno, te avisaremos aquí.'**
  String get friendWorkoutNotify;

  /// No description provided for @noProfileAccess.
  ///
  /// In es, this message translates to:
  /// **'No tienes acceso a este perfil o no sois amigos.'**
  String get noProfileAccess;

  /// No description provided for @levelLabel.
  ///
  /// In es, this message translates to:
  /// **'Nivel: {level}'**
  String levelLabel(String level);

  /// No description provided for @noRecordsFriend.
  ///
  /// In es, this message translates to:
  /// **'Aún no tiene records registrados.'**
  String get noRecordsFriend;

  /// No description provided for @muscleRecovery.
  ///
  /// In es, this message translates to:
  /// **'Recuperación muscular'**
  String get muscleRecovery;

  /// No description provided for @recoveryHint.
  ///
  /// In es, this message translates to:
  /// **'Basado en tus entrenamientos recientes · recuperación en 48 h'**
  String get recoveryHint;

  /// No description provided for @rest.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get rest;

  /// No description provided for @restRemaining.
  ///
  /// In es, this message translates to:
  /// **'{seconds}s restantes'**
  String restRemaining(int seconds);

  /// No description provided for @skip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get skip;

  /// No description provided for @minus15s.
  ///
  /// In es, this message translates to:
  /// **'-15s'**
  String get minus15s;

  /// No description provided for @plus15s.
  ///
  /// In es, this message translates to:
  /// **'+15s'**
  String get plus15s;

  /// No description provided for @customRest.
  ///
  /// In es, this message translates to:
  /// **'Descanso personalizado'**
  String get customRest;

  /// No description provided for @cardioDuration.
  ///
  /// In es, this message translates to:
  /// **'Tiempo'**
  String get cardioDuration;

  /// No description provided for @cardioSecondsShort.
  ///
  /// In es, this message translates to:
  /// **'seg'**
  String get cardioSecondsShort;

  /// No description provided for @cardioDistance.
  ///
  /// In es, this message translates to:
  /// **'Distancia'**
  String get cardioDistance;

  /// No description provided for @cardioIncline.
  ///
  /// In es, this message translates to:
  /// **'Inclinación %'**
  String get cardioIncline;

  /// No description provided for @cardioDifficulty.
  ///
  /// In es, this message translates to:
  /// **'Grado de dificultad'**
  String get cardioDifficulty;

  /// No description provided for @cardioSteps.
  ///
  /// In es, this message translates to:
  /// **'Pasos'**
  String get cardioSteps;

  /// No description provided for @cardioMetricRequired.
  ///
  /// In es, this message translates to:
  /// **'Indica al menos una métrica de cardio'**
  String get cardioMetricRequired;

  /// No description provided for @cardioSetLabel.
  ///
  /// In es, this message translates to:
  /// **'Intervalo {number}'**
  String cardioSetLabel(int number);

  /// No description provided for @cardioPrDistance.
  ///
  /// In es, this message translates to:
  /// **'Distancia máx.'**
  String get cardioPrDistance;

  /// No description provided for @cardioPrDuration.
  ///
  /// In es, this message translates to:
  /// **'Tiempo máx.'**
  String get cardioPrDuration;

  /// No description provided for @cardioPrSteps.
  ///
  /// In es, this message translates to:
  /// **'Pasos máx.'**
  String get cardioPrSteps;

  /// No description provided for @cardioPrIncline.
  ///
  /// In es, this message translates to:
  /// **'Inclinación máx.'**
  String get cardioPrIncline;

  /// No description provided for @cardioPrDifficulty.
  ///
  /// In es, this message translates to:
  /// **'Dificultad máx.'**
  String get cardioPrDifficulty;

  /// No description provided for @exerciseTypeStrength.
  ///
  /// In es, this message translates to:
  /// **'Fuerza'**
  String get exerciseTypeStrength;

  /// No description provided for @exerciseTypeCardio.
  ///
  /// In es, this message translates to:
  /// **'Cardio'**
  String get exerciseTypeCardio;

  /// No description provided for @cardioPresetTreadmill.
  ///
  /// In es, this message translates to:
  /// **'Cinta'**
  String get cardioPresetTreadmill;

  /// No description provided for @cardioPresetElliptical.
  ///
  /// In es, this message translates to:
  /// **'Elíptica'**
  String get cardioPresetElliptical;

  /// No description provided for @cardioPresetBike.
  ///
  /// In es, this message translates to:
  /// **'Bici / spinning'**
  String get cardioPresetBike;

  /// No description provided for @cardioPresetStair.
  ///
  /// In es, this message translates to:
  /// **'Escaladora'**
  String get cardioPresetStair;

  /// No description provided for @cardioPresetRowing.
  ///
  /// In es, this message translates to:
  /// **'Remo'**
  String get cardioPresetRowing;

  /// No description provided for @cardioPresetCustom.
  ///
  /// In es, this message translates to:
  /// **'Personalizado'**
  String get cardioPresetCustom;

  /// No description provided for @cardioMetricsLabel.
  ///
  /// In es, this message translates to:
  /// **'Métricas a registrar'**
  String get cardioMetricsLabel;

  /// No description provided for @secondsLabel.
  ///
  /// In es, this message translates to:
  /// **'Segundos'**
  String get secondsLabel;

  /// No description provided for @customRestChip.
  ///
  /// In es, this message translates to:
  /// **'Personalizado'**
  String get customRestChip;

  /// No description provided for @restSeconds.
  ///
  /// In es, this message translates to:
  /// **'{seconds}s'**
  String restSeconds(int seconds);

  /// No description provided for @addExercise.
  ///
  /// In es, this message translates to:
  /// **'Añadir ejercicio'**
  String get addExercise;

  /// No description provided for @reorderExercise.
  ///
  /// In es, this message translates to:
  /// **'Arrastrar para reordenar'**
  String get reorderExercise;

  /// No description provided for @searchByMuscle.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre, músculo o categoría…'**
  String get searchByMuscle;

  /// No description provided for @searchExercise.
  ///
  /// In es, this message translates to:
  /// **'Buscar ejercicio…'**
  String get searchExercise;

  /// No description provided for @inRoutine.
  ///
  /// In es, this message translates to:
  /// **'En rutina ({count})'**
  String inRoutine(int count);

  /// No description provided for @allGroups.
  ///
  /// In es, this message translates to:
  /// **'Todos los grupos'**
  String get allGroups;

  /// No description provided for @noSearchInRoutine.
  ///
  /// In es, this message translates to:
  /// **'Ningún ejercicio coincide con la búsqueda en tu rutina.'**
  String get noSearchInRoutine;

  /// No description provided for @noExercisesFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron ejercicios.'**
  String get noExercisesFound;

  /// No description provided for @noResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get noResults;

  /// No description provided for @swapSimilar.
  ///
  /// In es, this message translates to:
  /// **'Intercambiar por similar'**
  String get swapSimilar;

  /// No description provided for @noSimilarFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos ejercicios similares.\nPrueba añadir uno manualmente.'**
  String get noSimilarFound;

  /// No description provided for @remove.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get remove;

  /// No description provided for @noSets.
  ///
  /// In es, this message translates to:
  /// **'Sin series'**
  String get noSets;

  /// No description provided for @historyTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get historyTitle;

  /// No description provided for @noExerciseHistory.
  ///
  /// In es, this message translates to:
  /// **'Sin historial previo para este ejercicio.'**
  String get noExerciseHistory;

  /// No description provided for @loadingHistory.
  ///
  /// In es, this message translates to:
  /// **'Cargando historial…'**
  String get loadingHistory;

  /// No description provided for @setLine.
  ///
  /// In es, this message translates to:
  /// **'Serie {n}: {detail}'**
  String setLine(int n, String detail);

  /// No description provided for @repsOnly.
  ///
  /// In es, this message translates to:
  /// **'{reps} reps'**
  String repsOnly(int reps);

  /// No description provided for @apiKeySaved.
  ///
  /// In es, this message translates to:
  /// **'API key guardada de forma segura en el dispositivo'**
  String get apiKeySaved;

  /// No description provided for @apiKeyDeleted.
  ///
  /// In es, this message translates to:
  /// **'API key eliminada'**
  String get apiKeyDeleted;

  /// No description provided for @apiKeysTitle.
  ///
  /// In es, this message translates to:
  /// **'API Keys'**
  String get apiKeysTitle;

  /// No description provided for @apiKeyPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Tu API key se guarda solo en este dispositivo (almacenamiento seguro). Nunca se envía a nuestros servidores. Las llamadas a IA van directamente a OpenAI o Google.'**
  String get apiKeyPrivacy;

  /// No description provided for @saveApiKey.
  ///
  /// In es, this message translates to:
  /// **'Guardar API Key'**
  String get saveApiKey;

  /// No description provided for @deleteApiKey.
  ///
  /// In es, this message translates to:
  /// **'Eliminar API Key'**
  String get deleteApiKey;

  /// No description provided for @openAiHint.
  ///
  /// In es, this message translates to:
  /// **'Obtén tu key en platform.openai.com'**
  String get openAiHint;

  /// No description provided for @geminiHint.
  ///
  /// In es, this message translates to:
  /// **'Obtén tu key en aistudio.google.com'**
  String get geminiHint;

  /// No description provided for @openAiKey.
  ///
  /// In es, this message translates to:
  /// **'OpenAI API Key'**
  String get openAiKey;

  /// No description provided for @geminiKey.
  ///
  /// In es, this message translates to:
  /// **'Gemini API Key'**
  String get geminiKey;

  /// No description provided for @claudeKey.
  ///
  /// In es, this message translates to:
  /// **'Claude API Key'**
  String get claudeKey;

  /// No description provided for @claudeHint.
  ///
  /// In es, this message translates to:
  /// **'Obtén tu key en console.anthropic.com (API, no Claude Pro).'**
  String get claudeHint;

  /// No description provided for @claudeApiNote.
  ///
  /// In es, this message translates to:
  /// **'La suscripción Claude Pro no incluye API key. Necesitas crear una en Anthropic Console y pagar por uso.'**
  String get claudeApiNote;

  /// No description provided for @apiGuidesTitle.
  ///
  /// In es, this message translates to:
  /// **'Guías paso a paso'**
  String get apiGuidesTitle;

  /// No description provided for @apiGuidesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Si es tu primera vez, sigue estos instructivos. También puedes abrir el PDF completo.'**
  String get apiGuidesSubtitle;

  /// No description provided for @apiGuideOpenPortal.
  ///
  /// In es, this message translates to:
  /// **'Abrir sitio oficial'**
  String get apiGuideOpenPortal;

  /// No description provided for @apiGuideOpenPdf.
  ///
  /// In es, this message translates to:
  /// **'Ver instructivo PDF'**
  String get apiGuideOpenPdf;

  /// No description provided for @openAiGuideTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo obtener tu API Key de OpenAI'**
  String get openAiGuideTitle;

  /// No description provided for @openAiGuidePortal.
  ///
  /// In es, this message translates to:
  /// **'platform.openai.com/api-keys'**
  String get openAiGuidePortal;

  /// No description provided for @openAiGuideStep1.
  ///
  /// In es, this message translates to:
  /// **'Abre platform.openai.com en tu navegador y crea una cuenta o inicia sesión con tu correo.'**
  String get openAiGuideStep1;

  /// No description provided for @openAiGuideStep2.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu correo si es la primera vez. OpenAI puede pedir un número de teléfono para seguridad.'**
  String get openAiGuideStep2;

  /// No description provided for @openAiGuideStep3.
  ///
  /// In es, this message translates to:
  /// **'Entra a la sección API keys: platform.openai.com/api-keys (menú lateral → API keys).'**
  String get openAiGuideStep3;

  /// No description provided for @openAiGuideStep4.
  ///
  /// In es, this message translates to:
  /// **'Pulsa «Create new secret key». Ponle un nombre que reconozcas, por ejemplo «FitForge».'**
  String get openAiGuideStep4;

  /// No description provided for @openAiGuideStep5.
  ///
  /// In es, this message translates to:
  /// **'Copia la clave en cuanto aparezca. Solo se muestra una vez; si la pierdes, tendrás que crear otra.'**
  String get openAiGuideStep5;

  /// No description provided for @openAiGuideStep6.
  ///
  /// In es, this message translates to:
  /// **'OpenAI puede pedir agregar un método de pago en Billing antes de usar la API (suele ser pago por uso).'**
  String get openAiGuideStep6;

  /// No description provided for @openAiGuideStep7.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a FitForge, pega la clave en el campo de arriba, elige OpenAI y pulsa «Guardar API Key».'**
  String get openAiGuideStep7;

  /// No description provided for @geminiGuideTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo obtener tu API Key de Gemini (Google)'**
  String get geminiGuideTitle;

  /// No description provided for @geminiGuidePortal.
  ///
  /// In es, this message translates to:
  /// **'aistudio.google.com/apikey'**
  String get geminiGuidePortal;

  /// No description provided for @geminiGuideStep1.
  ///
  /// In es, this message translates to:
  /// **'Abre aistudio.google.com en tu navegador e inicia sesión con tu cuenta de Google.'**
  String get geminiGuideStep1;

  /// No description provided for @geminiGuideStep2.
  ///
  /// In es, this message translates to:
  /// **'Si es la primera vez, acepta los términos de Google AI Studio cuando te lo pida.'**
  String get geminiGuideStep2;

  /// No description provided for @geminiGuideStep3.
  ///
  /// In es, this message translates to:
  /// **'Ve a la sección de API keys: aistudio.google.com/apikey (menú «Get API key»).'**
  String get geminiGuideStep3;

  /// No description provided for @geminiGuideStep4.
  ///
  /// In es, this message translates to:
  /// **'Pulsa «Create API key». Puedes crear un proyecto nuevo de Google Cloud o usar uno existente.'**
  String get geminiGuideStep4;

  /// No description provided for @geminiGuideStep5.
  ///
  /// In es, this message translates to:
  /// **'Copia la API key generada. Guárdala en un lugar seguro; no la compartas con nadie.'**
  String get geminiGuideStep5;

  /// No description provided for @geminiGuideStep6.
  ///
  /// In es, this message translates to:
  /// **'Google ofrece un nivel gratuito con límites de uso. Revisa los límites en la consola si lo necesitas.'**
  String get geminiGuideStep6;

  /// No description provided for @geminiGuideStep7.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a FitForge, pega la clave en el campo de arriba, elige Gemini y pulsa «Guardar API Key».'**
  String get geminiGuideStep7;

  /// No description provided for @claudeGuideTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo obtener tu API Key de Claude (Anthropic)'**
  String get claudeGuideTitle;

  /// No description provided for @claudeGuidePortal.
  ///
  /// In es, this message translates to:
  /// **'console.anthropic.com/settings/keys'**
  String get claudeGuidePortal;

  /// No description provided for @claudeGuideStep1.
  ///
  /// In es, this message translates to:
  /// **'Abre console.anthropic.com e inicia sesión (cuenta distinta a claude.ai si solo usas el chat).'**
  String get claudeGuideStep1;

  /// No description provided for @claudeGuideStep2.
  ///
  /// In es, this message translates to:
  /// **'Ve a Settings → API Keys (console.anthropic.com/settings/keys).'**
  String get claudeGuideStep2;

  /// No description provided for @claudeGuideStep3.
  ///
  /// In es, this message translates to:
  /// **'Pulsa «Create Key», ponle un nombre (ej. FitForge) y confirma.'**
  String get claudeGuideStep3;

  /// No description provided for @claudeGuideStep4.
  ///
  /// In es, this message translates to:
  /// **'Copia la key generada. Solo se muestra una vez; guárdala en un lugar seguro.'**
  String get claudeGuideStep4;

  /// No description provided for @claudeGuideStep5.
  ///
  /// In es, this message translates to:
  /// **'Anthropic cobra por uso en la API (no usa tu suscripción Claude Pro del chat).'**
  String get claudeGuideStep5;

  /// No description provided for @claudeGuideStep6.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a FitForge, pega la clave, elige Claude y pulsa «Guardar API Key».'**
  String get claudeGuideStep6;

  /// No description provided for @setsRepsBest.
  ///
  /// In es, this message translates to:
  /// **'{sets} series · {reps} reps · mejor: {weight}'**
  String setsRepsBest(int sets, int reps, String weight);

  /// No description provided for @recordVolume.
  ///
  /// In es, this message translates to:
  /// **'Volumen'**
  String get recordVolume;

  /// No description provided for @recordReps.
  ///
  /// In es, this message translates to:
  /// **'Repeticiones'**
  String get recordReps;

  /// No description provided for @recordMaxWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso máximo'**
  String get recordMaxWeight;

  /// No description provided for @exercisesAndMuscles.
  ///
  /// In es, this message translates to:
  /// **'{exercises} ejercicios · {muscles} músculos'**
  String exercisesAndMuscles(int exercises, int muscles);

  /// No description provided for @seriesCompleted.
  ///
  /// In es, this message translates to:
  /// **'{total} series · Completado'**
  String seriesCompleted(int total);

  /// No description provided for @seriesProgress.
  ///
  /// In es, this message translates to:
  /// **'{total} series · {done}/{total} hechas'**
  String seriesProgress(int total, int done);

  /// No description provided for @seriesWithWeight.
  ///
  /// In es, this message translates to:
  /// **'{total} series · {weight} × {reps}'**
  String seriesWithWeight(int total, String weight, int reps);

  /// No description provided for @restPeriod.
  ///
  /// In es, this message translates to:
  /// **'{seconds}s descanso'**
  String restPeriod(int seconds);

  /// No description provided for @timeNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora'**
  String get timeNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {n} min'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {n} h'**
  String timeHoursAgo(int n);

  /// No description provided for @timeDaysAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {n} d'**
  String timeDaysAgo(int n);

  /// No description provided for @shareWorkoutTitle.
  ///
  /// In es, this message translates to:
  /// **'{name} — FitForge'**
  String shareWorkoutTitle(String name);

  /// No description provided for @shareDuration.
  ///
  /// In es, this message translates to:
  /// **'⏱ {minutes} min'**
  String shareDuration(int minutes);

  /// No description provided for @shareExerciseCount.
  ///
  /// In es, this message translates to:
  /// **'🏋️ {count} ejercicios'**
  String shareExerciseCount(int count);

  /// No description provided for @shareTotalReps.
  ///
  /// In es, this message translates to:
  /// **'🔁 {reps} reps totales'**
  String shareTotalReps(int reps);

  /// No description provided for @shareMaxWeight.
  ///
  /// In es, this message translates to:
  /// **'📈 Peso máx: {value}'**
  String shareMaxWeight(String value);

  /// No description provided for @shareVolume.
  ///
  /// In es, this message translates to:
  /// **'📊 Volumen: {value}'**
  String shareVolume(String value);

  /// No description provided for @shareCalories.
  ///
  /// In es, this message translates to:
  /// **'🔥 Calorías (est.): {value}'**
  String shareCalories(String value);

  /// No description provided for @shareNewRecords.
  ///
  /// In es, this message translates to:
  /// **'🏆 ¡Nuevos récords vs última vez!'**
  String get shareNewRecords;

  /// No description provided for @shareMusclesTrained.
  ///
  /// In es, this message translates to:
  /// **'💪 Músculos: {muscles}'**
  String shareMusclesTrained(String muscles);

  /// No description provided for @sharePersonalRecords.
  ///
  /// In es, this message translates to:
  /// **'🏆 Récords personales:'**
  String get sharePersonalRecords;

  /// No description provided for @shareVolumeUp.
  ///
  /// In es, this message translates to:
  /// **'📈 +{percent}% volumen vs última vez'**
  String shareVolumeUp(String percent);

  /// No description provided for @shareAchievementsHeader.
  ///
  /// In es, this message translates to:
  /// **'🎉 ¡Logros desbloqueados!'**
  String get shareAchievementsHeader;

  /// No description provided for @shareLevelUp.
  ///
  /// In es, this message translates to:
  /// **'⭐ ¡Subiste a nivel {level}!'**
  String shareLevelUp(int level);

  /// No description provided for @shareMilestoneUnlocked.
  ///
  /// In es, this message translates to:
  /// **'🏅 Medalla {category} — {tierName}'**
  String shareMilestoneUnlocked(String category, String tierName);

  /// No description provided for @shareXpEarned.
  ///
  /// In es, this message translates to:
  /// **'⚡ +{xp} XP'**
  String shareXpEarned(int xp);

  /// No description provided for @summaryAchievementsTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Logros desbloqueados!'**
  String get summaryAchievementsTitle;

  /// No description provided for @summaryMilestoneUnlocked.
  ///
  /// In es, this message translates to:
  /// **'Nueva medalla'**
  String get summaryMilestoneUnlocked;

  /// No description provided for @summaryMilestoneDetail.
  ///
  /// In es, this message translates to:
  /// **'{category} · {tierName}'**
  String summaryMilestoneDetail(String category, String tierName);

  /// No description provided for @shareExercisesHeader.
  ///
  /// In es, this message translates to:
  /// **'Ejercicios:'**
  String get shareExercisesHeader;

  /// No description provided for @shareExerciseLine.
  ///
  /// In es, this message translates to:
  /// **'• {name}: {sets}× · {reps} reps{weight}'**
  String shareExerciseLine(String name, int sets, int reps, String weight);

  /// No description provided for @shareHashtags.
  ///
  /// In es, this message translates to:
  /// **'#FitForge #Entrenamiento'**
  String get shareHashtags;

  /// No description provided for @maxWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso máx'**
  String get maxWeight;

  /// No description provided for @volume.
  ///
  /// In es, this message translates to:
  /// **'Volumen'**
  String get volume;

  /// No description provided for @searchFriendsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Busca por correo o nombre para agregar amigos.'**
  String get searchFriendsEmpty;

  /// No description provided for @generatingRoutine.
  ///
  /// In es, this message translates to:
  /// **'Generando rutina…'**
  String get generatingRoutine;

  /// No description provided for @streakWeeks0.
  ///
  /// In es, this message translates to:
  /// **'0 semanas'**
  String get streakWeeks0;

  /// No description provided for @streakWeeks1.
  ///
  /// In es, this message translates to:
  /// **'1 semana'**
  String get streakWeeks1;

  /// No description provided for @streakWeeksMany.
  ///
  /// In es, this message translates to:
  /// **'{count} semanas'**
  String streakWeeksMany(int count);

  /// No description provided for @volumeShort.
  ///
  /// In es, this message translates to:
  /// **'vol.'**
  String get volumeShort;

  /// No description provided for @defaultWorkoutName.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento'**
  String get defaultWorkoutName;

  /// No description provided for @rotateBody.
  ///
  /// In es, this message translates to:
  /// **'Girar maniquí'**
  String get rotateBody;

  /// No description provided for @bodyFront.
  ///
  /// In es, this message translates to:
  /// **'Frente'**
  String get bodyFront;

  /// No description provided for @bodyBack.
  ///
  /// In es, this message translates to:
  /// **'Espalda'**
  String get bodyBack;

  /// No description provided for @chooseAvatar.
  ///
  /// In es, this message translates to:
  /// **'Elige tu avatar'**
  String get chooseAvatar;

  /// No description provided for @chooseAvatarHint.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un avatar del catálogo FitForge'**
  String get chooseAvatarHint;

  /// No description provided for @changeAvatar.
  ///
  /// In es, this message translates to:
  /// **'Cambiar avatar'**
  String get changeAvatar;

  /// No description provided for @foodTitle.
  ///
  /// In es, this message translates to:
  /// **'Nutrición'**
  String get foodTitle;

  /// No description provided for @foodEaten.
  ///
  /// In es, this message translates to:
  /// **'Consumidas'**
  String get foodEaten;

  /// No description provided for @foodBurned.
  ///
  /// In es, this message translates to:
  /// **'Quemadas'**
  String get foodBurned;

  /// No description provided for @foodCaloriesLeft.
  ///
  /// In es, this message translates to:
  /// **'{count} kcal restantes'**
  String foodCaloriesLeft(int count);

  /// No description provided for @foodDailyBudget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto del día'**
  String get foodDailyBudget;

  /// No description provided for @foodCaloriesAvailable.
  ///
  /// In es, this message translates to:
  /// **'kcal disponibles'**
  String get foodCaloriesAvailable;

  /// No description provided for @foodCaloriesSurplus.
  ///
  /// In es, this message translates to:
  /// **'kcal en exceso'**
  String get foodCaloriesSurplus;

  /// No description provided for @foodBudgetUsed.
  ///
  /// In es, this message translates to:
  /// **'{percent}% usado'**
  String foodBudgetUsed(int percent);

  /// No description provided for @foodBudgetGoal.
  ///
  /// In es, this message translates to:
  /// **'objetivo {goal} kcal'**
  String foodBudgetGoal(int goal);

  /// No description provided for @foodStatGoal.
  ///
  /// In es, this message translates to:
  /// **'Objetivo'**
  String get foodStatGoal;

  /// No description provided for @foodBudgetSummary.
  ///
  /// In es, this message translates to:
  /// **'{eaten} consumidas · {burned} quemadas · objetivo {goal} kcal'**
  String foodBudgetSummary(int eaten, int burned, int goal);

  /// No description provided for @foodTimelineEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin registros'**
  String get foodTimelineEmpty;

  /// No description provided for @foodEnergyOutputTitle.
  ///
  /// In es, this message translates to:
  /// **'Energía gastada'**
  String get foodEnergyOutputTitle;

  /// No description provided for @foodEnergyOutputEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin actividad registrada hoy. Añade entrenos en FitForge o actividades manuales.'**
  String get foodEnergyOutputEmpty;

  /// No description provided for @foodAddActivity.
  ///
  /// In es, this message translates to:
  /// **'Registrar actividad'**
  String get foodAddActivity;

  /// No description provided for @foodFromFitForgeWorkout.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento FitForge'**
  String get foodFromFitForgeWorkout;

  /// No description provided for @foodManualActivityLabel.
  ///
  /// In es, this message translates to:
  /// **'Actividad manual'**
  String get foodManualActivityLabel;

  /// No description provided for @foodWorkoutBonus.
  ///
  /// In es, this message translates to:
  /// **'+{count} kcal activas por entrenamiento hoy'**
  String foodWorkoutBonus(int count);

  /// No description provided for @foodMealsTitle.
  ///
  /// In es, this message translates to:
  /// **'Comidas del día'**
  String get foodMealsTitle;

  /// No description provided for @foodActivitiesTitle.
  ///
  /// In es, this message translates to:
  /// **'Actividades del día'**
  String get foodActivitiesTitle;

  /// No description provided for @foodActivityManual.
  ///
  /// In es, this message translates to:
  /// **'Actividades manuales'**
  String get foodActivityManual;

  /// No description provided for @foodActivityAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar actividad'**
  String get foodActivityAdd;

  /// No description provided for @foodActivityAddHint.
  ///
  /// In es, this message translates to:
  /// **'Registra entrenos u otras actividades que no hayas documentado en FitForge.'**
  String get foodActivityAddHint;

  /// No description provided for @foodActivityName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la actividad'**
  String get foodActivityName;

  /// No description provided for @foodActivityNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Caminata, yoga, fútbol…'**
  String get foodActivityNameHint;

  /// No description provided for @foodActivityNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre para la actividad.'**
  String get foodActivityNameRequired;

  /// No description provided for @foodActivityCalories.
  ///
  /// In es, this message translates to:
  /// **'Calorías quemadas'**
  String get foodActivityCalories;

  /// No description provided for @foodActivityCaloriesHint.
  ///
  /// In es, this message translates to:
  /// **'150'**
  String get foodActivityCaloriesHint;

  /// No description provided for @foodActivityCaloriesInvalid.
  ///
  /// In es, this message translates to:
  /// **'Indica calorías entre 1 y 9999.'**
  String get foodActivityCaloriesInvalid;

  /// No description provided for @foodActivitySave.
  ///
  /// In es, this message translates to:
  /// **'Guardar actividad'**
  String get foodActivitySave;

  /// No description provided for @foodManualActivityBonus.
  ///
  /// In es, this message translates to:
  /// **'+{count} kcal por actividades manuales'**
  String foodManualActivityBonus(int count);

  /// No description provided for @mealBreakfast.
  ///
  /// In es, this message translates to:
  /// **'Desayuno'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In es, this message translates to:
  /// **'Almuerzo'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In es, this message translates to:
  /// **'Cena'**
  String get mealDinner;

  /// No description provided for @mealSnack.
  ///
  /// In es, this message translates to:
  /// **'Otros'**
  String get mealSnack;

  /// No description provided for @foodBmrMissingHint.
  ///
  /// In es, this message translates to:
  /// **'Completa tu peso y datos en Perfil para calcular tu objetivo calórico personalizado.'**
  String get foodBmrMissingHint;

  /// No description provided for @foodSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Filtrar alimentos registrados'**
  String get foodSearchHint;

  /// No description provided for @foodModeBarcode.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get foodModeBarcode;

  /// No description provided for @foodModeSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get foodModeSearch;

  /// No description provided for @foodModePhoto.
  ///
  /// In es, this message translates to:
  /// **'Foto'**
  String get foodModePhoto;

  /// No description provided for @foodModeQuick.
  ///
  /// In es, this message translates to:
  /// **'Rápido'**
  String get foodModeQuick;

  /// No description provided for @foodModeManual.
  ///
  /// In es, this message translates to:
  /// **'Manual'**
  String get foodModeManual;

  /// No description provided for @foodRecentSearches.
  ///
  /// In es, this message translates to:
  /// **'Alimentos recientes'**
  String get foodRecentSearches;

  /// No description provided for @foodNoRecent.
  ///
  /// In es, this message translates to:
  /// **'Aún no has registrado alimentos.'**
  String get foodNoRecent;

  /// No description provided for @foodAiFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo estimar el alimento. Revisa tu API key o intenta de nuevo.'**
  String get foodAiFailed;

  /// No description provided for @foodBarcodeNotFound.
  ///
  /// In es, this message translates to:
  /// **'Producto no encontrado en la base de datos.'**
  String get foodBarcodeNotFound;

  /// No description provided for @foodBarcodeHint.
  ///
  /// In es, this message translates to:
  /// **'Apunta la cámara al código de barras del empaque.'**
  String get foodBarcodeHint;

  /// No description provided for @foodBarcodeCameraDenied.
  ///
  /// In es, this message translates to:
  /// **'Se necesita permiso de cámara para escanear códigos.'**
  String get foodBarcodeCameraDenied;

  /// No description provided for @foodBarcodeUnsupported.
  ///
  /// In es, this message translates to:
  /// **'Este dispositivo no tiene cámara compatible con el escáner.'**
  String get foodBarcodeUnsupported;

  /// No description provided for @foodBarcodeGenericError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la cámara. Revisa permisos o prueba en un dispositivo físico.'**
  String get foodBarcodeGenericError;

  /// No description provided for @foodBarcodeRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get foodBarcodeRetry;

  /// No description provided for @foodBarcodeOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes de la app'**
  String get foodBarcodeOpenSettings;

  /// No description provided for @foodBarcodePhotoAction.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get foodBarcodePhotoAction;

  /// No description provided for @foodBarcodeGalleryAction.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get foodBarcodeGalleryAction;

  /// No description provided for @foodBarcodePhotoFallback.
  ///
  /// In es, this message translates to:
  /// **'Si el visor en vivo no arranca, escanea desde una foto o la galería.'**
  String get foodBarcodePhotoFallback;

  /// No description provided for @foodBarcodeNotDetectedInPhoto.
  ///
  /// In es, this message translates to:
  /// **'No se detectó código de barras en la imagen. Acerca más el empaque e intenta de nuevo.'**
  String get foodBarcodeNotDetectedInPhoto;

  /// No description provided for @foodBarcodeLookupFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al consultar el código. Revisa tu conexión.'**
  String get foodBarcodeLookupFailed;

  /// No description provided for @foodPer100gNote.
  ///
  /// In es, this message translates to:
  /// **'Los valores nutricionales se calculan por cada 100 g/ml.'**
  String get foodPer100gNote;

  /// No description provided for @foodQuickAddHint.
  ///
  /// In es, this message translates to:
  /// **'Describe lo que estás comiendo y la IA calculará calorías y macros.'**
  String get foodQuickAddHint;

  /// No description provided for @foodQuickAddPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Ej.: 2 huevos revueltos con queso y pan integral'**
  String get foodQuickAddPlaceholder;

  /// No description provided for @foodQuickAddAction.
  ///
  /// In es, this message translates to:
  /// **'Estimar con IA'**
  String get foodQuickAddAction;

  /// No description provided for @foodManualAddHint.
  ///
  /// In es, this message translates to:
  /// **'Introduce los datos de una porción. Se guardará en tu dispositivo para reutilizarlo.'**
  String get foodManualAddHint;

  /// No description provided for @foodManualAddAction.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get foodManualAddAction;

  /// No description provided for @foodManualSavedFoods.
  ///
  /// In es, this message translates to:
  /// **'Guardados en este dispositivo'**
  String get foodManualSavedFoods;

  /// No description provided for @foodManualNoSaved.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes alimentos manuales guardados.'**
  String get foodManualNoSaved;

  /// No description provided for @foodManualNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre del alimento.'**
  String get foodManualNameRequired;

  /// No description provided for @foodManualCaloriesRequired.
  ///
  /// In es, this message translates to:
  /// **'Introduce calorías mayores que cero.'**
  String get foodManualCaloriesRequired;

  /// No description provided for @foodManualGramsLabel.
  ///
  /// In es, this message translates to:
  /// **'gramos totales (g)'**
  String get foodManualGramsLabel;

  /// No description provided for @foodPortionUnit.
  ///
  /// In es, this message translates to:
  /// **'porción'**
  String get foodPortionUnit;

  /// No description provided for @foodManualQuantityHint.
  ///
  /// In es, this message translates to:
  /// **'Ajusta las porciones; calorías y macros se recalculan solos.'**
  String get foodManualQuantityHint;

  /// No description provided for @foodPhotoHint.
  ///
  /// In es, this message translates to:
  /// **'Toma una foto de tu plato. La IA identificará los alimentos y sugerirá los macros.'**
  String get foodPhotoHint;

  /// No description provided for @foodPhotoAction.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get foodPhotoAction;

  /// No description provided for @foodPhotoGalleryAction.
  ///
  /// In es, this message translates to:
  /// **'Elegir de galería'**
  String get foodPhotoGalleryAction;

  /// No description provided for @foodPhotoReferenceCaption.
  ///
  /// In es, this message translates to:
  /// **'Esta foto se usa al recalcular con IA'**
  String get foodPhotoReferenceCaption;

  /// No description provided for @foodPhotoTapToExpand.
  ///
  /// In es, this message translates to:
  /// **'Toca para ampliar'**
  String get foodPhotoTapToExpand;

  /// No description provided for @foodQuantityLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad ({unit})'**
  String foodQuantityLabel(String unit);

  /// No description provided for @foodNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get foodNameLabel;

  /// No description provided for @foodNameHint.
  ///
  /// In es, this message translates to:
  /// **'ej. Pechuga a la plancha con arroz y brócoli'**
  String get foodNameHint;

  /// No description provided for @foodMacrosAutoHint.
  ///
  /// In es, this message translates to:
  /// **'Ajusta los gramos; calorías y macros se recalculan solos.'**
  String get foodMacrosAutoHint;

  /// No description provided for @foodAiCorrectionHint.
  ///
  /// In es, this message translates to:
  /// **'¿La IA se equivocó?'**
  String get foodAiCorrectionHint;

  /// No description provided for @foodAiCorrectionPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Ej.: eran 3 tortillas, no 2, y cada una tiene 56 kcal'**
  String get foodAiCorrectionPlaceholder;

  /// No description provided for @foodAiCorrectionAction.
  ///
  /// In es, this message translates to:
  /// **'Recalcular con IA'**
  String get foodAiCorrectionAction;

  /// No description provided for @foodAnalyzing.
  ///
  /// In es, this message translates to:
  /// **'Analizando…'**
  String get foodAnalyzing;

  /// No description provided for @foodDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle nutricional'**
  String get foodDetailTitle;

  /// No description provided for @foodAddThis.
  ///
  /// In es, this message translates to:
  /// **'Añadir alimento'**
  String get foodAddThis;

  /// No description provided for @foodServingLabel.
  ///
  /// In es, this message translates to:
  /// **'Porción'**
  String get foodServingLabel;

  /// No description provided for @foodCaloriesLabel.
  ///
  /// In es, this message translates to:
  /// **'Calorías (kcal)'**
  String get foodCaloriesLabel;

  /// No description provided for @foodIngredients.
  ///
  /// In es, this message translates to:
  /// **'Ingredientes'**
  String get foodIngredients;

  /// No description provided for @foodIngredientBreakdownHint.
  ///
  /// In es, this message translates to:
  /// **'Peso estimado por componente — corrige abajo si algo no cuadra'**
  String get foodIngredientBreakdownHint;

  /// No description provided for @foodIngredientGrams.
  ///
  /// In es, this message translates to:
  /// **'~{grams} g'**
  String foodIngredientGrams(String grams);

  /// No description provided for @foodIngredientTotalGrams.
  ///
  /// In es, this message translates to:
  /// **'Total estimado · ~{grams} g'**
  String foodIngredientTotalGrams(String grams);

  /// No description provided for @macroProtein.
  ///
  /// In es, this message translates to:
  /// **'Proteína'**
  String get macroProtein;

  /// No description provided for @macroFat.
  ///
  /// In es, this message translates to:
  /// **'Grasa'**
  String get macroFat;

  /// No description provided for @macroCarbs.
  ///
  /// In es, this message translates to:
  /// **'Carbohidratos'**
  String get macroCarbs;

  /// No description provided for @macroFiber.
  ///
  /// In es, this message translates to:
  /// **'Fibra'**
  String get macroFiber;

  /// No description provided for @foodMealGoalPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'{eaten} / {goal} kcal'**
  String foodMealGoalPlaceholder(int eaten, int goal);

  /// No description provided for @routineExerciseSets.
  ///
  /// In es, this message translates to:
  /// **'Series'**
  String get routineExerciseSets;

  /// No description provided for @routineExerciseWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso ({unit})'**
  String routineExerciseWeight(String unit);

  /// No description provided for @routineAddSet.
  ///
  /// In es, this message translates to:
  /// **'Añadir serie'**
  String get routineAddSet;

  /// No description provided for @routineSetNumber.
  ///
  /// In es, this message translates to:
  /// **'Ser. {number}'**
  String routineSetNumber(int number);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
