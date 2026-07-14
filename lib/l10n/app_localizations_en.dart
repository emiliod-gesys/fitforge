// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FitForge';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get notDefined => 'Not set';

  @override
  String get user => 'User';

  @override
  String errorGeneric(String message) {
    return 'Error: $message';
  }

  @override
  String get enterValue => 'Enter value';

  @override
  String get years => 'years';

  @override
  String get loading => 'Loading…';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get apply => 'Apply';

  @override
  String get generate => 'Generate';

  @override
  String get close => 'Close';

  @override
  String get share => 'Share';

  @override
  String get view => 'View';

  @override
  String get active => 'Active';

  @override
  String get minutes => 'min';

  @override
  String minSuffix(int n) {
    return '$n min';
  }

  @override
  String get navWorkout => 'Workout';

  @override
  String get navTrain => 'Train';

  @override
  String get navRoutines => 'Routines';

  @override
  String get trainTabToday => 'Training';

  @override
  String get trainTabRoutines => 'Routines';

  @override
  String get navCoach => 'Coach';

  @override
  String get navFood => 'Food';

  @override
  String get navProgress => 'Progress';

  @override
  String get navSocial => 'Social';

  @override
  String get navStudents => 'Students';

  @override
  String get navProfile => 'Profile';

  @override
  String get coachAi => 'AI Coach';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileDedication =>
      'This app would never have existed without the motivation of my brothers Diego and Rodrigo, who inspired me to pursue a healthier lifestyle. LIGHT WEIGHT BABY!';

  @override
  String get personalData => 'Personal details';

  @override
  String get profileOnboardingTitle => 'Complete your profile';

  @override
  String get profileOnboardingSubtitle =>
      'We need this information to personalize training, nutrition, and progress.';

  @override
  String get profileOnboardingNickname => 'Name or nickname';

  @override
  String get profileOnboardingContinue => 'Continue';

  @override
  String get onboardingWelcomeTitle => 'Welcome to FitForge';

  @override
  String get onboardingWelcomeSubtitle =>
      'Train, log meals, and track progress in one place.';

  @override
  String get onboardingWelcomeBulletTrain =>
      'Gym, Hyrox, and GPS running routines';

  @override
  String get onboardingWelcomeBulletFood =>
      'Food diary with a daily calorie budget';

  @override
  String get onboardingWelcomeBulletProgress =>
      'XP, records, and shareable progress';

  @override
  String get onboardingLanguageTitle => 'Choose your language';

  @override
  String get onboardingLanguageSubtitle =>
      'FitForge will use this language. You can change it later in Profile.';

  @override
  String get fitnessGoalCalorieSurplus => 'Requires caloric surplus';

  @override
  String get fitnessGoalCalorieDeficit => 'Requires caloric deficit';

  @override
  String get fitnessGoalCalorieMaintenance =>
      'Caloric maintenance (no surplus or deficit)';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingAboutYouTitle => 'About you';

  @override
  String get onboardingAboutYouSubtitle =>
      'Pick your avatar and tell us the basics so we can personalize calories and progress.';

  @override
  String get onboardingBodyTitle => 'Your body';

  @override
  String get onboardingBodySubtitle =>
      'Height and weight power calorie burn estimates and your daily target.';

  @override
  String get onboardingGoalsTitle => 'Your goal';

  @override
  String get onboardingGoalsSubtitle =>
      'Set how you train and eat based on what you want to achieve.';

  @override
  String get onboardingModesTitle => 'How do you train?';

  @override
  String get onboardingModesSubtitle =>
      'Enable extra modes for running or Hyrox prep. You can change these anytime in Profile.';

  @override
  String get onboardingRoutineTitle => 'Your first routine';

  @override
  String get onboardingRoutineSubtitle =>
      'Open the real routine editor, name it, add exercises, and save.';

  @override
  String get onboardingRoutineOpenAction => 'Open routine editor';

  @override
  String get onboardingRoutineOpenHint =>
      'Same editor as Train → Routines. You need a name and at least one exercise before saving.';

  @override
  String get onboardingRoutineNameHint => 'My first routine';

  @override
  String get onboardingRoutineExercisesTitle => 'Exercises';

  @override
  String get onboardingRoutineExercisesHint =>
      'Search the catalog and pick one or more. You can fine-tune sets and reps later in the editor.';

  @override
  String get onboardingRoutineAddExercise => 'Add exercise';

  @override
  String get onboardingRoutineExerciseRequired =>
      'Add at least one exercise before creating the routine';

  @override
  String get onboardingRoutineCreateAction => 'Create routine';

  @override
  String get onboardingRoutineCreated =>
      'Routine created! Find it under Train → Routines.';

  @override
  String get onboardingRoutineNameRequired => 'Enter a name for the routine';

  @override
  String get onboardingFoodTitle => 'Quick food log';

  @override
  String get onboardingFoodSubtitle =>
      'Log a breakfast with Quick add (AI), then delete it in Food to learn the full flow.';

  @override
  String get onboardingFoodOpenAction => 'Log breakfast';

  @override
  String get onboardingFoodOpenDiary => 'Go to Food';

  @override
  String get onboardingFoodPracticeBanner =>
      'Onboarding step: swipe this entry to delete it and continue.';

  @override
  String get onboardingFoodExampleName =>
      '2 scrambled eggs with cheese and whole wheat toast';

  @override
  String get onboardingFoodRegisterAction => 'Log meal';

  @override
  String get onboardingFoodRegistered => 'Meal logged in today\'s diary.';

  @override
  String get onboardingFoodDeleteHint =>
      'Delete it to finish this step — that\'s the full flow.';

  @override
  String get onboardingFoodDeleted => 'Entry deleted. All set!';

  @override
  String get onboardingDoneTitle => 'You\'re all set!';

  @override
  String get onboardingDoneSubtitle =>
      'Your profile is ready. Start your first workout whenever you want.';

  @override
  String get onboardingDoneAction => 'Enter FitForge';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingSkipModes => 'Skip extra modes';

  @override
  String get onboardingSelectGoal => 'Select a goal';

  @override
  String get onboardingSelectExperience => 'Select your level';

  @override
  String get weightUpdateTitle => 'Update your weight';

  @override
  String get weightUpdateMessage =>
      'It\'s been more than 15 days since your last weigh-in. Update your weight to keep your metrics accurate.';

  @override
  String get weightUpdateSave => 'Save weight';

  @override
  String get weightInvalid => 'Enter a valid weight';

  @override
  String get genderRequired => 'Select your gender';

  @override
  String get heightInvalid => 'Enter a valid height (50–280 cm)';

  @override
  String get ageInvalid => 'Enter a valid age (13–119 years)';

  @override
  String get displayName => 'Name';

  @override
  String get displayNameTitle => 'Your name';

  @override
  String get displayNameRequired => 'Enter a name';

  @override
  String get age => 'Age';

  @override
  String get gender => 'Gender';

  @override
  String get height => 'Height';

  @override
  String get preferredLanguage => 'Preferred language';

  @override
  String get unitSystem => 'Unit system';

  @override
  String get accentColor => 'Accent color';

  @override
  String get accentColorHint => 'Customize the app\'s main color';

  @override
  String get accentGold => 'Gold';

  @override
  String get accentOrange => 'Orange';

  @override
  String get accentCobalt => 'Blue';

  @override
  String get accentViolet => 'Violet';

  @override
  String get accentEmerald => 'Green';

  @override
  String get accentRose => 'Pink';

  @override
  String get accentCrimson => 'Crimson';

  @override
  String get kilograms => 'Kilograms';

  @override
  String get pounds => 'Pounds';

  @override
  String get bodyMetrics => 'Body metrics';

  @override
  String get trainingConfig => 'Training settings';

  @override
  String get personalTrainerMode => 'Personal trainer mode';

  @override
  String get personalTrainerModeSubtitle =>
      'Enables the Students tab to monitor clients';

  @override
  String get personalTrainerModeEnabled =>
      'Trainer mode enabled. Students tab is now available.';

  @override
  String get personalTrainerModeDisabled => 'Trainer mode disabled.';

  @override
  String personalTrainerModeFailed(String message) {
    return 'Could not change mode: $message';
  }

  @override
  String get trainerModeRequired =>
      'Enable personal trainer mode in Profile to use this section.';

  @override
  String get studentsScreenHint =>
      'Send a request to add friends as students. You\'ll only see their data once they accept.';

  @override
  String studentsCount(int count) {
    return 'Students ($count)';
  }

  @override
  String get studentsEmpty =>
      'No students yet. Send a request to your friends from the list below.';

  @override
  String get addStudentFromFriends => 'Add from friends';

  @override
  String get addStudentEmpty =>
      'No friends available. They must be accepted friends first.';

  @override
  String get addStudentAction => 'Add student';

  @override
  String get sendStudentRequestAction => 'Send request';

  @override
  String get studentAdded => 'Student added';

  @override
  String get studentRequestSent => 'Request sent. The student must accept it.';

  @override
  String get studentRequestCanceled => 'Request canceled';

  @override
  String get studentRequestsSentSection => 'Sent requests';

  @override
  String get studentRequestPendingLabel => 'Awaiting approval';

  @override
  String get trainerRequestAccepted =>
      'Request accepted. You now have a trainer.';

  @override
  String get trainerRequestDeclined => 'Request declined';

  @override
  String addStudentFailed(String message) {
    return 'Could not add: $message';
  }

  @override
  String get removeStudentTitle => 'Remove student';

  @override
  String removeStudentMessage(String name) {
    return 'Remove $name from your students?';
  }

  @override
  String get removeStudentAction => 'Remove student';

  @override
  String get studentDetailTitle => 'Student';

  @override
  String get studentNotFound => 'Student not found';

  @override
  String get studentRecoveryTitle => 'Muscle recovery';

  @override
  String get studentNutritionTitle => 'Today\'s nutrition';

  @override
  String studentNutritionTitleDate(String date) {
    return 'Nutrition for $date';
  }

  @override
  String get studentWorkoutsTitle => 'Recent workouts';

  @override
  String get studentWorkoutsEmpty =>
      'This student has not logged any completed workouts yet.';

  @override
  String get studentRoutinesTitle => 'Student routines';

  @override
  String get studentRoutinesEmpty => 'This student has no routines yet.';

  @override
  String get studentRoutineNew => 'New routine for student';

  @override
  String get studentRoutineEdit => 'Edit student routine';

  @override
  String get deleteRoutineTitle => 'Delete routine';

  @override
  String deleteRoutineMessage(String name) {
    return 'Delete routine \"$name\"?';
  }

  @override
  String get goal => 'Goal';

  @override
  String get experienceLevel => 'Experience level';

  @override
  String get activityLevel => 'Non-gym daily activity';

  @override
  String get activityLevelTitle => 'Daily activity besides gym';

  @override
  String get activityLevelHint =>
      'Your everyday routine, excluding strength and cardio workouts';

  @override
  String get activitySedentary => 'Sedentary';

  @override
  String get activityModerate => 'Moderate';

  @override
  String get activityHigh => 'High';

  @override
  String get activitySedentaryDescription => 'Under 4,000 daily steps';

  @override
  String get activityModerateDescription => '4,000–10,000 daily steps';

  @override
  String get activityHighDescription => 'Over 10,000 daily steps';

  @override
  String get activityLevelFootnote =>
      'These are approximate activity levels to help guide your selection.';

  @override
  String get restTimerAlert => 'Rest timer alert';

  @override
  String get restTimerAlertTitle => 'Rest timer finished';

  @override
  String get restTimerAlertSound => 'Sound';

  @override
  String get restTimerAlertVibration => 'Vibration';

  @override
  String get restTimerAlertBoth => 'Sound + vibration';

  @override
  String get aiSection => 'Artificial intelligence';

  @override
  String get apiKeys => 'API Keys (OpenAI / Gemini)';

  @override
  String apiKeysConfigured(String provider) {
    return 'Configured ($provider)';
  }

  @override
  String get apiKeysNotConfigured => 'Not configured';

  @override
  String get advancedSettings => 'Advanced settings';

  @override
  String get advancedSettingsHint => 'Optional settings for experienced users';

  @override
  String get bringYourOwnAi => 'Connect your AI account';

  @override
  String get bringYourOwnAiSubtitle =>
      'Use your own OpenAI, Gemini, or Claude account';

  @override
  String get apiKeysNotAvailableOnPaidPlan =>
      'Your plan already includes AI — you don\'t need your own API key';

  @override
  String get featureGymratPlansOnly => 'Gymrat and Gymrat Pro users only';

  @override
  String get featureGymratProOnly => 'Gymrat Pro users only';

  @override
  String get subscriptionTierGymrat => 'Gymrat';

  @override
  String get subscriptionTierGymratPro => 'Gymrat Pro';

  @override
  String get hyroxMode => 'Hyrox mode';

  @override
  String get hyroxModeSubtitle =>
      'Adds 3 progressive routines (Prep → Build → Race). They don\'t count toward your routine limit.';

  @override
  String get hyroxModeEnabled => 'Hyrox mode on · 3 routines ready in Routines';

  @override
  String get hyroxModeDisabled => 'Hyrox mode off · Hyrox routines removed';

  @override
  String get hyroxRoutinePrepName => 'Hyrox 1 · Prep';

  @override
  String get hyroxRoutineBuildName => 'Hyrox 2 · Build';

  @override
  String get hyroxRoutineRaceName => 'Hyrox 3 · Race Day';

  @override
  String get hyroxRoutinePrepSubtitle =>
      'Hyrox fundamentals (~50% official distances). Focus on technique and pace.';

  @override
  String get hyroxRoutineBuildSubtitle =>
      'Intermediate volume (~75%). Build toward race-day loads and splits.';

  @override
  String get hyroxRoutineRaceSubtitle =>
      'Race Day simulation at full Open standards (100%). Time every phase.';

  @override
  String get runnerMode => 'Runner mode';

  @override
  String get runnerModeSubtitle =>
      'Adds Go for a run (GPS) and Treadmill run. They don\'t count toward your routine limit.';

  @override
  String get runnerModeEnabled =>
      'Runner mode on · 2 routines ready in Routines';

  @override
  String get runnerModeDisabled => 'Runner mode off · runner routines removed';

  @override
  String get runnerSystemBadge => 'Runner';

  @override
  String get runnerSystemLocked =>
      'System runner routine · can\'t edit or delete';

  @override
  String get runnerStart => 'Start';

  @override
  String get runnerStartOutdoor => 'Go for a run';

  @override
  String get runnerStartTreadmill => 'Treadmill run';

  @override
  String get runnerRoutineOutdoorSubtitle =>
      'Outdoor run with GPS, pace, splits, and elevation.';

  @override
  String get runnerRoutineTreadmillSubtitle =>
      'Treadmill run with incline, distance, and pace.';

  @override
  String get runnerSurfaceTitle => 'Where will you run?';

  @override
  String get runnerSurfaceHint =>
      'This helps contextualize your session in history.';

  @override
  String get runnerSurfaceAsphalt => 'Road / street';

  @override
  String get runnerSurfaceAsphaltDesc => 'Pavement, sidewalks, or urban paths.';

  @override
  String get runnerSurfaceTrack => 'Track';

  @override
  String get runnerSurfaceTrackDesc =>
      'Athletics track or uniform synthetic surface.';

  @override
  String get runnerSurfaceTrail => 'Trail';

  @override
  String get runnerSurfaceTrailDesc => 'Dirt, mountain, or uneven terrain.';

  @override
  String get runnerAcquiringGps => 'Acquiring GPS signal…';

  @override
  String get runnerGpsDenied =>
      'Enable location and grant permissions to track your run.';

  @override
  String get runnerNoDistance =>
      'No distance recorded. Wait a few seconds with GPS on or move a bit more.';

  @override
  String get runnerTime => 'Time';

  @override
  String get runnerDistance => 'Distance';

  @override
  String get runnerPace => 'Pace';

  @override
  String get runnerPause => 'Pause';

  @override
  String get runnerResume => 'Resume';

  @override
  String get runnerFinish => 'Finish';

  @override
  String get runnerSplitsTitle => 'Km splits';

  @override
  String runnerSplitKm(int km) {
    return 'Km $km';
  }

  @override
  String get runnerInclineLabel => 'Treadmill incline';

  @override
  String get runnerInclineHelper => '0% if flat';

  @override
  String get runnerInclineRequired => 'Enter incline (0% is OK)';

  @override
  String get runnerTreadmillHint =>
      'Tap start when you\'re on the treadmill. When done, enter incline and distance.';

  @override
  String get runnerSummaryTitle => 'Run summary';

  @override
  String get runnerRouteTitle => 'Route';

  @override
  String get runnerAvgPace => 'Average pace';

  @override
  String get runnerElevationLabel => 'Elevation';

  @override
  String get runnerElevationGain => 'Total gained';

  @override
  String get runnerElevationLoss => 'Total lost';

  @override
  String get runnerElevationNet => 'Net';

  @override
  String get runnerAutoStartHint =>
      'Let\'s run! The stopwatch and metrics will start automatically when movement is detected.';

  @override
  String get hyroxSystemBadge => 'Hyrox';

  @override
  String get hyroxSystemLocked =>
      'Hyrox system routine. Turn off Hyrox mode in Profile to remove it.';

  @override
  String hyroxPhaseTimer(int phase, int total) {
    return 'Phase $phase/$total';
  }

  @override
  String get hyroxPhaseSplit => 'Phase split';

  @override
  String hyroxTargetDistance(int meters) {
    return 'Target: $meters m';
  }

  @override
  String get hyroxStationDone => 'Done';

  @override
  String get hyroxStartRace => 'Start';

  @override
  String get hyroxReadyToStart =>
      'Press Start when you\'re ready. The global timer begins then.';

  @override
  String get hyroxStationCompleted => 'Completed';

  @override
  String get hyroxStationFixedHint =>
      'Fixed weight & distance (Hyrox standard)';

  @override
  String get hyroxSplitsSummaryTitle => 'Station splits';

  @override
  String get hyroxValidationRejected =>
      'This Hyrox does not count for rankings: we detected times or data beyond humanly plausible limits.';

  @override
  String get hyroxValidationSuspicious =>
      'This Hyrox was flagged for review due to unusual metrics.';

  @override
  String get leaderboardMetricHyrox => 'Hyrox Race';

  @override
  String get aiCoachSubtitle => 'Personalized recommendations';

  @override
  String get proactiveAi => 'Proactive AI';

  @override
  String get proactiveAiSubtitleOff => 'AI only responds when you message it';

  @override
  String get proactiveAiSubtitleOn => 'Enabled · may use more tokens';

  @override
  String get proactiveAiEnableTitle => 'Enable proactive AI?';

  @override
  String get proactiveAiEnableMessage =>
      'FitForge may use your API key to send suggestions without you asking. This can increase token usage.';

  @override
  String get proactiveAiEnableConfirm => 'Enable';

  @override
  String get aiCalculatingWorkoutSuggestions => 'Calculating AI suggestions…';

  @override
  String get aiWorkoutSuggestionsApplied =>
      'Sets suggested by AI based on your history and goal';

  @override
  String get fitnessGoalTitle => 'Fitness goal';

  @override
  String get fitnessGoalHint =>
      'Your goal shapes how AI programs workouts and your daily calorie target.';

  @override
  String get fitnessGoalTrainingLabel => 'Training';

  @override
  String get fitnessGoalDietLabel => 'Diet';

  @override
  String get goalHypertrophyTraining =>
      '3-5 working sets, 8-12 reps, progressive weight and volume. Compounds + isolation.';

  @override
  String get goalHypertrophyDiet =>
      'Slight calorie surplus (+8%), ~2 g protein per kg of body weight.';

  @override
  String get goalStrengthTraining =>
      '3-6 sets, 3-6 reps at heavy loads. Warm-up sets on compound lifts.';

  @override
  String get goalStrengthDiet =>
      'Moderate surplus (+8%), high protein (~2 g/kg) for recovery and strength.';

  @override
  String get goalFatLossTraining =>
      '2-4 sets, 12-20 reps, short rest. Prioritize volume and training density.';

  @override
  String get goalFatLossDiet =>
      'Calorie deficit (~15%), high protein (~2.2 g/kg) to preserve muscle.';

  @override
  String get goalEnduranceTraining =>
      '2-3 sets, 15+ reps or cardio by time/distance. Lighter loads, more reps.';

  @override
  String get goalEnduranceDiet =>
      'Maintenance calories, balanced macros (~1.6 g protein/kg).';

  @override
  String get goalMaintenanceTraining =>
      'Follow your recent history without aggressive progression.';

  @override
  String get goalMaintenanceDiet =>
      'Maintenance calories (TDEE), balanced macros (~1.6 g protein/kg).';

  @override
  String get fitnessGoalFootnote =>
      'Proactive AI and your calorie budget use this goal. You can change it anytime.';

  @override
  String get experienceTitle => 'Experience level';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderNonBinary => 'Non-binary';

  @override
  String get genderPreferNotSay => 'Prefer not to say';

  @override
  String get genderTitle => 'Gender';

  @override
  String get ageTitle => 'Age';

  @override
  String get heightTitle => 'Height';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageEs => 'Español';

  @override
  String get languageEn => 'English';

  @override
  String get feet => 'Feet';

  @override
  String get inches => 'Inches';

  @override
  String get goalHypertrophy => 'Hypertrophy';

  @override
  String get goalStrength => 'Strength';

  @override
  String get goalFatLoss => 'Fat loss';

  @override
  String get goalEndurance => 'Endurance';

  @override
  String get goalMaintenance => 'Maintenance';

  @override
  String get expBeginner => 'beginner';

  @override
  String get expIntermediate => 'intermediate';

  @override
  String get expAdvanced => 'advanced';

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressMyTrainerLabel => 'Your personal trainer';

  @override
  String progressTotalXp(int total) {
    return '$total XP total';
  }

  @override
  String progressXpToNext(int remaining, int level) {
    return '$remaining XP to level $level';
  }

  @override
  String get progressStatsNewPrs => 'New PRs';

  @override
  String get progressStatsMonthlyWorkouts => 'Workouts this month';

  @override
  String get progressStatsMonthlyVolume => 'Volume this month';

  @override
  String get progressStatsMonthlyPrs => 'PRs this month';

  @override
  String progressStreakWeeks(int count) {
    return '$count wks';
  }

  @override
  String get progressRecentPrs => 'Recent PRs';

  @override
  String get progressAllRecords => 'All records';

  @override
  String get progressNewPrBadge => 'New';

  @override
  String get progressVolumeTrend => 'Volume trend';

  @override
  String get progressBodyTitle => 'Body';

  @override
  String progressMilestoneNext(String target) {
    return 'Next: $target';
  }

  @override
  String playerLevelTitle(int level) {
    return 'Level $level';
  }

  @override
  String playerXpProgress(int current, int total) {
    return '$current / $total XP';
  }

  @override
  String get playerLevelMax => 'Max level reached';

  @override
  String get playerLevelTierMythic => 'Mythic';

  @override
  String get playerLevelTierImmortal => 'Immortal';

  @override
  String xpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String get levelUp => 'Level up!';

  @override
  String get rankUp => 'New rank!';

  @override
  String shareRankUp(String rank, int level) {
    return '⭐ Promoted to $rank! (Level $level)';
  }

  @override
  String streakXpBonus(String multiplier) {
    return 'Streak bonus ×$multiplier';
  }

  @override
  String get workouts30d => 'Workouts (30 d)';

  @override
  String get volume30d => 'Volume (30 d)';

  @override
  String get progressLast7Days => 'Last 7 days';

  @override
  String get progressAllTime => 'All time';

  @override
  String get progressWorkoutsLabel => 'Workouts';

  @override
  String get progressVolumeLabel => 'Volume';

  @override
  String get progressCaloriesLabel => 'Calories';

  @override
  String get volumePerWorkout => 'Volume per day';

  @override
  String get last10Days => 'Last 10 days';

  @override
  String get completeWorkoutsForVolume =>
      'Complete workouts to see your volume';

  @override
  String get milestonesTitle => 'Milestones';

  @override
  String get milestonesSubtitle => 'Unlock badges as you hit cumulative goals';

  @override
  String get milestoneCategoryReps => 'Reps';

  @override
  String get milestoneCategoryVolume => 'Volume';

  @override
  String get milestoneCategoryDistance => 'Distance';

  @override
  String get milestoneCategoryCalories => 'Calories';

  @override
  String get milestoneCategoryWorkouts => 'Workouts';

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
    return 'Next goal: $target';
  }

  @override
  String milestoneDetailRemaining(String remaining, String target) {
    return '$remaining to reach $target';
  }

  @override
  String get milestoneAllUnlocked => 'All badges unlocked!';

  @override
  String get milestoneTierBronze => 'Bronze';

  @override
  String get milestoneTierSilver => 'Silver';

  @override
  String get milestoneTierGold => 'Gold';

  @override
  String get milestoneTierPlatinum => 'Platinum';

  @override
  String get milestoneTierDiamond => 'Diamond';

  @override
  String get milestoneTierMaster => 'Master';

  @override
  String get milestoneTierGrandmaster => 'Grandmaster';

  @override
  String get milestoneTierLegend => 'Legend';

  @override
  String get personalRecords => 'Personal records';

  @override
  String get all => 'All';

  @override
  String get noRecordsYet => 'Complete workouts to log PRs';

  @override
  String noRecordsForMuscle(String muscle) {
    return 'No records for $muscle';
  }

  @override
  String get oneRm => '1RM';

  @override
  String get exercisesTitle => 'Exercises';

  @override
  String get searchExercises => 'Search exercises…';

  @override
  String exerciseCount(int count) {
    return '$count exercises';
  }

  @override
  String get allCategories => 'All';

  @override
  String get exerciseNotFound => 'Exercise not found';

  @override
  String get exerciseDetailTitle => 'Exercise';

  @override
  String get instructions => 'Instructions';

  @override
  String get watchDemoVideo => 'Watch demo video';

  @override
  String get fitforgeCatalog => 'FitForge catalog exercise';

  @override
  String get customExerciseTag => 'Custom';

  @override
  String get customExerciseAttribution => 'Exercise you created on this device';

  @override
  String get createCustomExercise => 'Create custom exercise';

  @override
  String get myCustomExercises => 'My exercises';

  @override
  String get customExerciseName => 'Exercise name';

  @override
  String get customExerciseMuscles => 'Muscles worked';

  @override
  String get customExercisePhoto => 'Machine photo (optional)';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Gallery';

  @override
  String get customExerciseSaved => 'Custom exercise saved';

  @override
  String get customExerciseDeleted => 'Custom exercise deleted';

  @override
  String get deleteCustomExercise => 'Delete exercise';

  @override
  String get deleteCustomExerciseConfirm =>
      'Delete this custom exercise? Saved routines will keep the name.';

  @override
  String get customExerciseNameRequired => 'Enter a name for the exercise';

  @override
  String get customExerciseMusclesRequired =>
      'Select at least one muscle group';

  @override
  String get customExerciseLimitReached =>
      'Custom exercise limit reached (100)';

  @override
  String get customExercisePerArmWeight => 'Weight per arm';

  @override
  String get customExercisePerArmWeightHint =>
      'Log each dumbbell or side separately. Volume counts both arms (×2).';

  @override
  String weightPerArm(String unit) {
    return '$unit (per arm)';
  }

  @override
  String get wgerAttribution => 'Images and videos from wger.de (CC-BY-SA)';

  @override
  String get loadingImage => 'Loading image…';

  @override
  String get metricWeight => 'Weight';

  @override
  String get metricBmi => 'Body mass index';

  @override
  String get metricBodyFat => 'Body fat';

  @override
  String get metricSkeletalMuscle => 'Skeletal muscle';

  @override
  String get metricFatFreeMass => 'Fat-free body weight';

  @override
  String get metricSubcutaneousFat => 'Subcutaneous fat';

  @override
  String get metricVisceralFat => 'Visceral fat';

  @override
  String get metricBodyWater => 'Body water';

  @override
  String get metricMuscleMass => 'Muscle mass';

  @override
  String get metricBoneMass => 'Bone mass';

  @override
  String get metricProtein => 'Protein';

  @override
  String get metricBmr => 'Basal metabolic rate';

  @override
  String get metricCalculatedAutomatically => 'Calculated automatically';

  @override
  String get bodyMetricColorLegendTitle => 'Color legend';

  @override
  String get bodyMetricColorLegendNote =>
      'Applies to weight, BMI, body fat, and subcutaneous fat.';

  @override
  String get bodyMetricHealthVeryLow => 'Very low';

  @override
  String get bodyMetricHealthLow => 'Low';

  @override
  String get bodyMetricHealthAppropriate => 'Appropriate';

  @override
  String get bodyMetricHealthIdeal => 'Ideal';

  @override
  String get bodyMetricHealthHigh => 'High';

  @override
  String get bodyMetricHealthVeryBad => 'Very high';

  @override
  String get metricMetabolicAge => 'Metabolic age';

  @override
  String get muscleChest => 'Chest';

  @override
  String get muscleBack => 'Back';

  @override
  String get muscleShoulders => 'Shoulders';

  @override
  String get muscleBiceps => 'Biceps';

  @override
  String get muscleTriceps => 'Triceps';

  @override
  String get muscleLegs => 'Legs';

  @override
  String get muscleGlutes => 'Glutes';

  @override
  String get muscleAbs => 'Abs';

  @override
  String get muscleForearms => 'Forearms';

  @override
  String get muscleCardio => 'Cardio';

  @override
  String get muscleCalves => 'Calves';

  @override
  String get workoutTitle => 'Workout';

  @override
  String get routinesTitle => 'Routines';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get socialTitle => 'Social';

  @override
  String get socialHeroTitle => 'Your circle';

  @override
  String get socialHeroSubtitle => 'Train together, climb together';

  @override
  String socialHeroFriends(int count) {
    return '$count friends';
  }

  @override
  String socialHeroPending(int count) {
    return '$count pending';
  }

  @override
  String socialHeroRank(int rank) {
    return '#$rank among friends';
  }

  @override
  String socialHeroRankGlobal(int rank) {
    return '#$rank global';
  }

  @override
  String get socialHeroNoRank => 'Compete with your friends';

  @override
  String get socialTabFriends => 'Friends';

  @override
  String get socialTabFeed => 'Feed';

  @override
  String get socialTabLeaderboards => 'Leaderboards';

  @override
  String get feedEmptyTitle => 'Your feed is empty';

  @override
  String get feedEmptySubtitle =>
      'When you or friends work out, level up, or unlock badges, you\'ll see it here. Posts last 24 hours.';

  @override
  String get feedExpiryHint => 'Only posts from the last 24 hours are shown.';

  @override
  String get feedLongPressToReact => 'Long-press a post to react.';

  @override
  String feedMilestoneUnlock(String name, String category, String tier) {
    return '$name unlocked $category badge — $tier';
  }

  @override
  String feedLevelUp(String name, int level) {
    return '$name reached level $level';
  }

  @override
  String feedPrUnlock(String name, String exercise, String value) {
    return '$name set a new PR on $exercise: $value';
  }

  @override
  String feedPrUnlockSelf(String exercise, String value) {
    return 'You set a new PR on $exercise: $value';
  }

  @override
  String feedMilestoneUnlockSelf(String category, String tier) {
    return 'You unlocked the $category badge — $tier';
  }

  @override
  String feedLevelUpSelf(int level) {
    return 'You reached level $level';
  }

  @override
  String feedWorkoutCompletedSelf(String workout) {
    return 'You completed \"$workout\"';
  }

  @override
  String get feedSharePrTitle => 'Share to feed';

  @override
  String get feedSharePrSubtitle =>
      'Choose which records friends can see. They publish when you close this screen.';

  @override
  String feedPrShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records shared to your friends\' feed',
      one: '1 record shared to your friends\' feed',
    );
    return '$_temp0';
  }

  @override
  String get feedPrShareFailed =>
      'Couldn\'t share to the feed. Please try again.';

  @override
  String get leaderboardLoadMore => 'Show more';

  @override
  String get leaderboardsTitle => 'Leaderboards';

  @override
  String get leaderboardScopeFriends => 'Friends';

  @override
  String get leaderboardScopeGlobal => 'Global';

  @override
  String get leaderboardMetricLevel => 'Level';

  @override
  String get leaderboardEmpty => 'No data in this leaderboard yet.';

  @override
  String get leaderboardYourPosition => 'Your position';

  @override
  String get leaderboardPeriodWeek => 'Week';

  @override
  String get leaderboardPeriodMonth => 'Month';

  @override
  String get leaderboardPeriodAll => 'All time';

  @override
  String leaderboardPeriodXp(int xp) {
    return '$xp XP';
  }

  @override
  String rankYou(String name) {
    return '$name (you)';
  }

  @override
  String get loginTagline => 'Forge your best self';

  @override
  String get createAccount => 'Create account';

  @override
  String get signIn => 'Sign in';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get resetPasswordTitle => 'New password';

  @override
  String get resetPasswordSubtitle =>
      'Choose a secure password for your FitForge account.';

  @override
  String get newPassword => 'New password';

  @override
  String get resetPasswordAction => 'Update password';

  @override
  String get resetPasswordSuccess => 'Password updated successfully';

  @override
  String get resetPasswordFailed =>
      'Could not update your password. Request a new link and try again.';

  @override
  String get resetPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get enter => 'Sign in';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get googleSignInCancelled => 'Google sign-in was cancelled';

  @override
  String get googleSignInFailed => 'Could not sign in with Google. Try again.';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get completeSecurityVerification =>
      'Complete the security verification';

  @override
  String get authError =>
      'Authentication error. Check your details and try again.';

  @override
  String get enterEmailFirst => 'Enter your email first';

  @override
  String get passwordResetSent => 'We sent you a link to reset your password';

  @override
  String get passwordResetFailed => 'Could not send the recovery email';

  @override
  String get haveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get noAccountSignUp => 'Don\'t have an account? Sign up';

  @override
  String get history => 'History';

  @override
  String get noWorkoutsYet => 'No workouts yet. Start today!';

  @override
  String get startToday => 'Start today';

  @override
  String get viewFullHistory => 'View full history';

  @override
  String get activeWorkout => 'Workout in progress';

  @override
  String get streakLabel => 'Streak';

  @override
  String get streakWeekly => 'Streak (≥4/wk)';

  @override
  String get streakWeeksSubtitle => 'weeks on streak (≥4/wk)';

  @override
  String get thisWeek => 'This week';

  @override
  String weeklyWorkoutsSubtitle(int goal) {
    return 'of $goal workouts this week';
  }

  @override
  String get trainHeroReadyTitle => 'Ready to train?';

  @override
  String get trainHeroGoalMetTitle => 'Weekly goal crushed!';

  @override
  String trainHeroStreakWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count week streak!',
      one: '1 week streak!',
    );
    return '$_temp0';
  }

  @override
  String trainWorkoutsRemaining(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining workouts left this week',
      one: '1 workout left this week',
    );
    return '$_temp0';
  }

  @override
  String trainWeeklyProgress(int current, int goal) {
    return '$current of $goal this week';
  }

  @override
  String get trainSuggestedTitle => 'Suggested next workout';

  @override
  String get trainSuggestedLastRoutine => 'Pick up your last routine';

  @override
  String get trainSuggestedRecovery => 'Muscles are ready for this session';

  @override
  String get trainSuggestedDefault => 'A solid place to start';

  @override
  String get trainStartSuggested => 'Start workout';

  @override
  String get recoveryViewDetail => 'View details';

  @override
  String get recoveryTopFatigued => 'Most fatigued';

  @override
  String get recoveryDetailTitle => 'Muscle recovery';

  @override
  String get trainRecentWorkouts => 'Recent';

  @override
  String get trainSwipeRepeat => 'Repeat';

  @override
  String get trainVolumePr => 'Top volume';

  @override
  String get startWorkout => 'Start workout';

  @override
  String get startingWorkout => 'Starting workout…';

  @override
  String startWorkoutError(String message) {
    return 'Could not start workout: $message';
  }

  @override
  String get freeWorkout => 'Free workout';

  @override
  String get loadingRoutines => 'Loading routines...';

  @override
  String exercisesInRoutine(int count) {
    return '$count exercises';
  }

  @override
  String get noWorkoutsRegistered => 'No workouts recorded';

  @override
  String get summaryTitle => 'Summary';

  @override
  String get summaryWorkoutComplete => 'Workout complete!';

  @override
  String summaryVolumeUp(String percent) {
    return '+$percent% volume vs last time';
  }

  @override
  String get summaryMusclesTrained => 'Muscles trained';

  @override
  String get summaryPersonalRecords => 'New personal records';

  @override
  String get summaryPersonalRecordBadge => 'PR';

  @override
  String get summaryExerciseImproved => 'Better than last time';

  @override
  String vsLastTime(String name) {
    return 'vs last time ($name)';
  }

  @override
  String get exercisesCompleted => 'Exercises completed';

  @override
  String setsReps(int sets, int reps) {
    return '$sets sets · $reps reps';
  }

  @override
  String best(String value) {
    return 'best: $value';
  }

  @override
  String get today => 'Today';

  @override
  String get before => 'Before';

  @override
  String recordLabel(String name) {
    return 'Record: $name';
  }

  @override
  String durationMinutesExercises(int minutes, int count) {
    return '$minutes min · $count exercises';
  }

  @override
  String get caloriesBurned => 'Calories';

  @override
  String caloriesKcal(int value) {
    return '$value kcal';
  }

  @override
  String get caloriesEstimateNote =>
      'Estimated active calories (workout extra; basal rest is already in your daily goal).';

  @override
  String get caloriesEstimateDefaultWeight =>
      'Estimate uses a 70 kg reference weight. Add your weight in Profile for better accuracy.';

  @override
  String get training => 'Training';

  @override
  String get finish => 'Finish';

  @override
  String get cancelWorkout => 'Cancel';

  @override
  String get cancelWorkoutTitle => 'Cancel workout?';

  @override
  String get cancelWorkoutMessage =>
      'This workout will be deleted and won\'t appear in your history. This can\'t be undone.';

  @override
  String get cancelWorkoutConfirm => 'Cancel workout';

  @override
  String get cancelWorkoutBack => 'Back';

  @override
  String get workoutCancelled => 'Workout cancelled';

  @override
  String cancelWorkoutFailed(String message) {
    return 'Could not cancel workout: $message';
  }

  @override
  String get leaveActiveWorkoutTitle => 'Leave workout?';

  @override
  String get leaveActiveWorkoutMessage =>
      'Your progress is saved. You can resume from Workouts.';

  @override
  String get leaveActiveWorkoutConfirm => 'Leave';

  @override
  String get viewList => 'View list';

  @override
  String get exerciseList => 'Exercise list';

  @override
  String get noActiveWorkout => 'No active workout';

  @override
  String get addSet => 'Add set';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String exerciseProgress(int current, int total) {
    return 'Exercise $current of $total';
  }

  @override
  String exerciseAdded(String name) {
    return '$name added';
  }

  @override
  String get addingExercise => 'Adding exercise…';

  @override
  String get exerciseRemoved => 'Exercise removed';

  @override
  String exerciseDeleteFailed(String message) {
    return 'Could not remove: $message';
  }

  @override
  String changedTo(String name) {
    return 'Changed to $name';
  }

  @override
  String finishFailed(String message) {
    return 'Could not finish: $message';
  }

  @override
  String get weightRequired => 'Enter weight before marking the set as done';

  @override
  String get weightAdditionalSuffix => '(+ extra)';

  @override
  String get weightPerArmSuffix => '(per arm)';

  @override
  String get loadModePerArm => 'Per arm';

  @override
  String get loadModeCombined => 'Combined';

  @override
  String get loadModeToggleHint =>
      'Toggle if you work both sides together or one at a time';

  @override
  String bodyweightLoadHint(String weight) {
    return 'Your body weight ($weight) counts by default. The field is extra load.';
  }

  @override
  String effectiveWeightLabel(String weight) {
    return 'Total weight: $weight';
  }

  @override
  String get reportExerciseProblem => 'Report a problem with this exercise';

  @override
  String get exerciseReportTitle => 'Report a problem';

  @override
  String get exerciseReportSubmit => 'Submit report';

  @override
  String get exerciseReportThanks => 'Thanks, we\'ll review your report';

  @override
  String get exerciseReportWrongMetrics => 'Wrong metrics (weight/reps)';

  @override
  String get exerciseReportWrongGif => 'Wrong image or GIF';

  @override
  String get exerciseReportWrongName => 'Wrong name or translation';

  @override
  String get exerciseReportWrongMuscles => 'Wrong muscles or category';

  @override
  String get exerciseReportOther => 'Other';

  @override
  String get exerciseReportNotes => 'Details (optional)';

  @override
  String get repsRequired => 'Enter the reps';

  @override
  String get distanceRequired => 'Enter the distance in meters';

  @override
  String get distanceMetersLabel => 'm';

  @override
  String setDeleteFailed(String message) {
    return 'Could not delete set: $message';
  }

  @override
  String get exerciseHistory => 'Exercise history';

  @override
  String get reps => 'Reps';

  @override
  String get done => 'Done';

  @override
  String get rirPickerTitle => 'How many more reps could you have done?';

  @override
  String get rirPickerSubtitle =>
      'Reps in reserve (RIR) for this set. The AI uses this to tune your next workout.';

  @override
  String get rirPickerRepsLeft => 'reps left';

  @override
  String get rirPickerSkip => 'Skip';

  @override
  String get newRoutine => 'New routine';

  @override
  String get generateWithAi => 'Generate with AI';

  @override
  String get noRoutines => 'No routines yet';

  @override
  String get createRoutine => 'Create routine';

  @override
  String get generateAiRoutineTitle => 'Generate routine with AI';

  @override
  String get targetMuscles => 'Muscles (e.g. Chest, Triceps)';

  @override
  String get durationMin => 'Duration (min)';

  @override
  String get routineGenerated => 'Routine generated and saved';

  @override
  String alreadyInRoutine(String name) {
    return '\"$name\" is already in the routine';
  }

  @override
  String get editRoutine => 'Edit routine';

  @override
  String get routineName => 'Routine name';

  @override
  String get description => 'Description';

  @override
  String get discard => 'Discard';

  @override
  String get routineDiscarded => 'Routine discarded';

  @override
  String get routineSaved => 'Routine saved to My routines';

  @override
  String routineSavedNamed(String name) {
    return '\"$name\" saved to Routines';
  }

  @override
  String get routineFavorite => 'Mark as favorite';

  @override
  String get routineUnfavorite => 'Remove from favorites';

  @override
  String routineFavoritesMax(int max) {
    return 'You can only have $max favorite routines on your profile';
  }

  @override
  String get friendFavoriteRoutines => 'Favorite routines';

  @override
  String get noFavoriteRoutinesFriend =>
      'This user has no public favorite routines';

  @override
  String get previewRoutine => 'Preview routine';

  @override
  String get saveRoutine => 'Save routine';

  @override
  String get shareRoutine => 'Share routine';

  @override
  String get shareRoutineTitle => 'Send routine to a friend';

  @override
  String get shareRoutineSelectFriend =>
      'Select a friend to send this routine to';

  @override
  String shareRoutineSent(String name) {
    return 'Routine sent to $name';
  }

  @override
  String shareRoutineFailed(String message) {
    return 'Could not share: $message';
  }

  @override
  String get shareRoutineNoFriends => 'Add friends to share routines';

  @override
  String get routineShareAccepted => 'Routine saved to your library';

  @override
  String get routineShareDeclined => 'Routine share declined';

  @override
  String get routineShareUnavailable =>
      'This share request is no longer available';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String saveFailed(String message) {
    return 'Could not save: $message';
  }

  @override
  String moreExercises(int count) {
    return '+ $count more exercises';
  }

  @override
  String exercisesSection(int count) {
    return 'Exercises ($count)';
  }

  @override
  String get add => 'Add';

  @override
  String get coachTitle => 'AI Coach';

  @override
  String get coachWelcome => 'Your personal AI trainer';

  @override
  String get coachWelcomeHint =>
      'Ask for a routine and save it when you\'re ready.\nSet up your API key in Profile.';

  @override
  String coachDailyLimitReached(int limit) {
    return 'You\'ve reached today\'s limit of $limit AI Coach messages. Upgrade for more.';
  }

  @override
  String coachDailyLimitRemaining(int remaining, int limit) {
    return '$remaining of $limit messages today';
  }

  @override
  String routineLimitReached(int limit) {
    return 'You\'ve reached your plan\'s limit of $limit saved routines. Upgrade to save more.';
  }

  @override
  String routineLimitUsage(int used, int limit) {
    return '$used of $limit routines saved';
  }

  @override
  String get coachAskHint => 'Ask a question or request a routine…';

  @override
  String get coachRoutineReady =>
      'Here is your routine. Review it and tap Save when ready.';

  @override
  String coachRoutinesReady(int count) {
    return 'Here are your $count routines for the week. Review each one and save the ones you want.';
  }

  @override
  String get coachRoutineTooFewExercises =>
      'Could not build a varied routine from the catalog. Try again or specify target muscles.';

  @override
  String get coachRoutineFailed =>
      'Could not generate the routine. Try being more specific (muscles and duration).';

  @override
  String get aiConnectionError => 'Connection error. Please try again.';

  @override
  String get coachNoRoutineToSave =>
      'There is no pending routine to save. Ask me to create one first.';

  @override
  String get coachSuggestion1 => 'Create a 45-minute leg routine';

  @override
  String get coachSuggestion2 =>
      'What exercises do you recommend for chest today?';

  @override
  String get coachSuggestion3 => 'Make me a back and biceps routine to save';

  @override
  String get coachSuggestion4 => 'When should I rest each muscle group?';

  @override
  String get requestSent => 'Request sent';

  @override
  String requestFailed(String message) {
    return 'Could not send: $message';
  }

  @override
  String searchFailed(String message) {
    return 'Search failed: $message';
  }

  @override
  String get markRead => 'Mark read';

  @override
  String get notifications => 'Notifications';

  @override
  String get pendingRequests => 'Pending requests';

  @override
  String get wantsToBeFriend => 'Wants to be your friend';

  @override
  String get requestSentLabel => 'Request sent';

  @override
  String friendsCount(int count) {
    return 'Friends ($count)';
  }

  @override
  String get searchFriendsHint => 'Search by email or name…';

  @override
  String get removeFriendTitle => 'Remove friend';

  @override
  String removeFriendBody(String name) {
    return 'Remove $name from your list?';
  }

  @override
  String get muteFriend => 'Mute';

  @override
  String get unmuteFriend => 'Unmute';

  @override
  String get friendMutedLabel => 'Muted';

  @override
  String friendMuted(String name) {
    return '$name muted';
  }

  @override
  String friendUnmuted(String name) {
    return '$name unmuted';
  }

  @override
  String get friendWorkoutNotify =>
      'When a friend completes a workout, we\'ll notify you here.';

  @override
  String get noProfileAccess =>
      'You don\'t have access to this profile or you\'re not friends.';

  @override
  String levelLabel(String level) {
    return 'Level: $level';
  }

  @override
  String get noRecordsFriend => 'No personal records yet.';

  @override
  String get muscleRecovery => 'Muscle recovery';

  @override
  String get recoveryHint => 'Based on your recent workouts · 48 h recovery';

  @override
  String get rest => 'Rest';

  @override
  String restRemaining(int seconds) {
    return '${seconds}s remaining';
  }

  @override
  String get skip => 'Skip';

  @override
  String get minus15s => '-15s';

  @override
  String get plus15s => '+15s';

  @override
  String get customRest => 'Custom rest';

  @override
  String get cardioDuration => 'Time';

  @override
  String get cardioSecondsShort => 'sec';

  @override
  String get cardioDistance => 'Distance';

  @override
  String get cardioIncline => 'Incline %';

  @override
  String get cardioDifficulty => 'Difficulty level';

  @override
  String get cardioSteps => 'Steps';

  @override
  String get cardioMetricRequired => 'Enter at least one cardio metric';

  @override
  String cardioSetLabel(int number) {
    return 'Interval $number';
  }

  @override
  String get cardioPrDistance => 'Max distance';

  @override
  String get cardioPrDuration => 'Max duration';

  @override
  String get cardioPrSteps => 'Max steps';

  @override
  String get cardioPrIncline => 'Max incline';

  @override
  String get cardioPrDifficulty => 'Max difficulty';

  @override
  String get exerciseTypeStrength => 'Strength';

  @override
  String get exerciseTypeCardio => 'Cardio';

  @override
  String get cardioPresetTreadmill => 'Treadmill';

  @override
  String get cardioPresetElliptical => 'Elliptical';

  @override
  String get cardioPresetBike => 'Bike / spinning';

  @override
  String get cardioPresetStair => 'Stair climber';

  @override
  String get cardioPresetRowing => 'Rowing';

  @override
  String get cardioPresetCustom => 'Custom';

  @override
  String get cardioMetricsLabel => 'Metrics to log';

  @override
  String get secondsLabel => 'Seconds';

  @override
  String get customRestChip => 'Custom';

  @override
  String restSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get addExercise => 'Add exercise';

  @override
  String get reorderExercise => 'Drag to reorder';

  @override
  String get searchByMuscle => 'Search by name, muscle or category…';

  @override
  String get searchExercise => 'Search exercise…';

  @override
  String inRoutine(int count) {
    return 'In routine ($count)';
  }

  @override
  String get allGroups => 'All groups';

  @override
  String get noSearchInRoutine =>
      'No exercises in your routine match the search.';

  @override
  String get noExercisesFound => 'No exercises found.';

  @override
  String get noResults => 'No results';

  @override
  String get swapSimilar => 'Swap for similar';

  @override
  String get noSimilarFound =>
      'No similar exercises found.\nTry adding one manually.';

  @override
  String get remove => 'Remove';

  @override
  String get noSets => 'No sets';

  @override
  String get historyTitle => 'History';

  @override
  String get noExerciseHistory => 'No previous history for this exercise.';

  @override
  String get loadingHistory => 'Loading history…';

  @override
  String setLine(int n, String detail) {
    return 'Set $n: $detail';
  }

  @override
  String repsOnly(int reps) {
    return '$reps reps';
  }

  @override
  String get apiKeySaved => 'API key saved securely on this device';

  @override
  String get apiKeyDeleted => 'API key deleted';

  @override
  String get apiKeysTitle => 'API Keys';

  @override
  String get apiKeyPrivacy =>
      'Your API key is stored only on this device (secure storage). It is never sent to our servers. AI calls go directly to OpenAI or Google.';

  @override
  String get saveApiKey => 'Save API Key';

  @override
  String get deleteApiKey => 'Delete API Key';

  @override
  String get openAiHint => 'Get your key at platform.openai.com';

  @override
  String get geminiHint => 'Get your key at aistudio.google.com';

  @override
  String get openAiKey => 'OpenAI API Key';

  @override
  String get geminiKey => 'Gemini API Key';

  @override
  String get claudeKey => 'Claude API Key';

  @override
  String get claudeHint =>
      'Get your key at console.anthropic.com (API billing, not Claude Pro).';

  @override
  String get claudeApiNote =>
      'Claude Pro chat subscription does not include an API key. Create one in Anthropic Console and pay per use.';

  @override
  String get apiGuidesTitle => 'Step-by-step guides';

  @override
  String get apiGuidesSubtitle =>
      'First time? Follow these guides. You can also open the full PDF.';

  @override
  String get apiGuideOpenPortal => 'Open official site';

  @override
  String get apiGuideOpenPdf => 'View PDF guide';

  @override
  String get openAiGuideTitle => 'How to get your OpenAI API Key';

  @override
  String get openAiGuidePortal => 'platform.openai.com/api-keys';

  @override
  String get openAiGuideStep1 =>
      'Open platform.openai.com in your browser and sign up or log in with your email.';

  @override
  String get openAiGuideStep2 =>
      'Verify your email if it\'s your first time. OpenAI may ask for a phone number for security.';

  @override
  String get openAiGuideStep3 =>
      'Go to API keys: platform.openai.com/api-keys (sidebar → API keys).';

  @override
  String get openAiGuideStep4 =>
      'Click «Create new secret key». Name it something you\'ll recognize, e.g. «FitForge».';

  @override
  String get openAiGuideStep5 =>
      'Copy the key as soon as it appears. It\'s shown only once; if you lose it, create a new one.';

  @override
  String get openAiGuideStep6 =>
      'OpenAI may require adding a payment method in Billing before using the API (pay-as-you-go).';

  @override
  String get openAiGuideStep7 =>
      'Return to FitForge, paste the key above, select OpenAI, and tap «Save API Key».';

  @override
  String get geminiGuideTitle => 'How to get your Gemini API Key (Google)';

  @override
  String get geminiGuidePortal => 'aistudio.google.com/apikey';

  @override
  String get geminiGuideStep1 =>
      'Open aistudio.google.com in your browser and sign in with your Google account.';

  @override
  String get geminiGuideStep2 =>
      'If it\'s your first time, accept the Google AI Studio terms when prompted.';

  @override
  String get geminiGuideStep3 =>
      'Go to API keys: aistudio.google.com/apikey (menu «Get API key»).';

  @override
  String get geminiGuideStep4 =>
      'Click «Create API key». You can create a new Google Cloud project or use an existing one.';

  @override
  String get geminiGuideStep5 =>
      'Copy the generated API key. Store it safely and never share it publicly.';

  @override
  String get geminiGuideStep6 =>
      'Google offers a free tier with usage limits. Check the console if you need details.';

  @override
  String get geminiGuideStep7 =>
      'Return to FitForge, paste the key above, select Gemini, and tap «Save API Key».';

  @override
  String get claudeGuideTitle => 'How to get your Claude API Key (Anthropic)';

  @override
  String get claudeGuidePortal => 'console.anthropic.com/settings/keys';

  @override
  String get claudeGuideStep1 =>
      'Open console.anthropic.com and sign in (separate from claude.ai chat if you only use the chat app).';

  @override
  String get claudeGuideStep2 =>
      'Go to Settings → API Keys (console.anthropic.com/settings/keys).';

  @override
  String get claudeGuideStep3 =>
      'Click «Create Key», name it (e.g. FitForge), and confirm.';

  @override
  String get claudeGuideStep4 =>
      'Copy the generated key. It is shown only once; store it safely.';

  @override
  String get claudeGuideStep5 =>
      'Anthropic bills API usage separately (your Claude Pro chat plan does not cover API calls).';

  @override
  String get claudeGuideStep6 =>
      'Return to FitForge, paste the key, select Claude, and tap «Save API Key».';

  @override
  String setsRepsBest(int sets, int reps, String weight) {
    return '$sets sets · $reps reps · best: $weight';
  }

  @override
  String get recordVolume => 'Volume';

  @override
  String get recordReps => 'Reps';

  @override
  String get recordMaxWeight => 'Max weight';

  @override
  String exercisesAndMuscles(int exercises, int muscles) {
    return '$exercises exercises · $muscles muscles';
  }

  @override
  String seriesCompleted(int total) {
    return '$total sets · Completed';
  }

  @override
  String seriesProgress(int total, int done) {
    return '$total sets · $done/$total done';
  }

  @override
  String seriesWithWeight(int total, String weight, int reps) {
    return '$total sets · $weight × $reps';
  }

  @override
  String restPeriod(int seconds) {
    return '${seconds}s rest';
  }

  @override
  String get timeNow => 'Now';

  @override
  String timeMinutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String timeDaysAgo(int n) {
    return '$n d ago';
  }

  @override
  String shareWorkoutTitle(String name) {
    return '💪 $name — FitForge';
  }

  @override
  String shareDuration(int minutes) {
    return '⏱ $minutes min';
  }

  @override
  String shareExerciseCount(int count) {
    return '🏋️ $count exercises';
  }

  @override
  String shareTotalReps(int reps) {
    return '🔁 $reps total reps';
  }

  @override
  String shareMaxWeight(String value) {
    return '📈 Max weight: $value';
  }

  @override
  String shareVolume(String value) {
    return '📊 Volume: $value';
  }

  @override
  String shareCalories(String value) {
    return '🔥 Calories (est.): $value';
  }

  @override
  String get shareNewRecords => '🏆 New records vs last time!';

  @override
  String shareMusclesTrained(String muscles) {
    return '💪 Muscles: $muscles';
  }

  @override
  String get sharePersonalRecords => '🏆 Personal records:';

  @override
  String shareVolumeUp(String percent) {
    return '📈 +$percent% volume vs last time';
  }

  @override
  String get shareAchievementsHeader => '🎉 Achievements unlocked!';

  @override
  String shareLevelUp(int level) {
    return '⭐ Level up to $level!';
  }

  @override
  String shareMilestoneUnlocked(String category, String tierName) {
    return '🏅 $category badge — $tierName';
  }

  @override
  String shareXpEarned(int xp) {
    return '⚡ +$xp XP';
  }

  @override
  String get summaryAchievementsTitle => 'Achievements unlocked!';

  @override
  String get summaryMilestoneUnlocked => 'New badge';

  @override
  String summaryMilestoneDetail(String category, String tierName) {
    return '$category · $tierName';
  }

  @override
  String get shareExercisesHeader => 'Exercises:';

  @override
  String shareExerciseLine(String name, int sets, int reps, String weight) {
    return '• $name: $sets× · $reps reps$weight';
  }

  @override
  String get shareHashtags => '#FitForge #Workout';

  @override
  String shareHyroxTitle(String name) {
    return 'HYROX · $name — FitForge';
  }

  @override
  String shareHyroxTotalTime(String time) {
    return 'Total time: $time';
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
    return 'Surface: $surface';
  }

  @override
  String shareRunnerSplitLine(int km, String time) {
    return 'Km $km: $time';
  }

  @override
  String get maxWeight => 'Max weight';

  @override
  String get volume => 'Volume';

  @override
  String get searchFriendsEmpty => 'Search by email or name to add friends.';

  @override
  String get generatingRoutine => 'Generating routine…';

  @override
  String get streakWeeks0 => '0 weeks';

  @override
  String get streakWeeks1 => '1 week';

  @override
  String streakWeeksMany(int count) {
    return '$count weeks';
  }

  @override
  String get volumeShort => 'vol.';

  @override
  String get defaultWorkoutName => 'Workout';

  @override
  String get rotateBody => 'Rotate body';

  @override
  String get bodyFront => 'Front';

  @override
  String get bodyBack => 'Back';

  @override
  String get chooseAvatar => 'Choose your avatar';

  @override
  String get chooseAvatarHint => 'Pick an avatar from the FitForge catalog';

  @override
  String get changeAvatar => 'Change avatar';

  @override
  String get foodTitle => 'Nutrition';

  @override
  String get foodEaten => 'Eaten';

  @override
  String get foodBurned => 'Burned';

  @override
  String foodCaloriesLeft(int count) {
    return '$count Cal left';
  }

  @override
  String get foodDailyBudget => 'Daily budget';

  @override
  String get foodCaloriesAvailable => 'Cal available';

  @override
  String get foodCaloriesSurplus => 'Cal over';

  @override
  String foodBudgetUsed(int percent) {
    return '$percent% used';
  }

  @override
  String foodBudgetGoal(int goal) {
    return 'goal $goal Cal';
  }

  @override
  String get foodStatGoal => 'Goal';

  @override
  String foodBudgetSummary(int eaten, int burned, int goal) {
    return '$eaten eaten · $burned burned · goal $goal Cal';
  }

  @override
  String get foodTimelineEmpty => 'Nothing logged';

  @override
  String get foodEnergyOutputTitle => 'Energy spent';

  @override
  String get foodEnergyOutputEmpty =>
      'No activity logged today. Add FitForge workouts or manual activities.';

  @override
  String get foodAddActivity => 'Log activity';

  @override
  String get foodFromFitForgeWorkout => 'FitForge workout';

  @override
  String get foodManualActivityLabel => 'Manual activity';

  @override
  String foodWorkoutBonus(int count) {
    return '+$count active Cal from today\'s workout';
  }

  @override
  String get foodMealsTitle => 'Today\'s meals';

  @override
  String get foodActivitiesTitle => 'Today\'s activities';

  @override
  String get foodActivityManual => 'Manual activities';

  @override
  String get foodActivityAdd => 'Add activity';

  @override
  String get foodActivityAddHint =>
      'Log workouts or other activities you didn\'t record in FitForge.';

  @override
  String get foodActivityName => 'Activity name';

  @override
  String get foodActivityNameHint => 'e.g. Walk, yoga, soccer…';

  @override
  String get foodActivityNameRequired => 'Enter an activity name.';

  @override
  String get foodActivityCalories => 'Calories burned';

  @override
  String get foodActivityCaloriesHint => '150';

  @override
  String get foodActivityCaloriesInvalid =>
      'Enter calories between 1 and 9999.';

  @override
  String get foodActivitySave => 'Save activity';

  @override
  String foodManualActivityBonus(int count) {
    return '+$count Cal from manual activities';
  }

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealSnack => 'Other';

  @override
  String get foodBmrMissingHint =>
      'Complete your weight and profile details to get a personalized calorie goal.';

  @override
  String get foodSearchHint => 'Filter logged foods';

  @override
  String get foodModeBarcode => 'Barcode';

  @override
  String get foodModeSearch => 'Search';

  @override
  String get foodModePhoto => 'Photo';

  @override
  String get foodModeQuick => 'Quick add';

  @override
  String get foodModeManual => 'Manual add';

  @override
  String get foodRecentSearches => 'Recent foods';

  @override
  String get foodNoRecent => 'No foods logged yet.';

  @override
  String get foodAiFailed =>
      'Could not estimate this food. Check your API key or try again.';

  @override
  String get foodBarcodeNotFound => 'Product not found in the database.';

  @override
  String get foodBarcodeHint => 'Point the camera at the product barcode.';

  @override
  String get foodBarcodeCameraDenied =>
      'Camera permission is required to scan barcodes.';

  @override
  String get foodBarcodeUnsupported =>
      'This device does not have a compatible camera for scanning.';

  @override
  String get foodBarcodeGenericError =>
      'Could not open the camera. Check permissions or try a physical device.';

  @override
  String get foodBarcodeRetry => 'Retry';

  @override
  String get foodBarcodeOpenSettings => 'Open app settings';

  @override
  String get foodBarcodePhotoAction => 'Take photo';

  @override
  String get foodBarcodeGalleryAction => 'Gallery';

  @override
  String get foodBarcodePhotoFallback =>
      'If the live view does not start, scan from a photo or your gallery.';

  @override
  String get foodBarcodeNotDetectedInPhoto =>
      'No barcode detected in the image. Move closer to the package and try again.';

  @override
  String get foodBarcodeLookupFailed =>
      'Could not look up the barcode. Check your connection.';

  @override
  String get foodPer100gNote => 'Nutrition values scale per 100 g/ml consumed.';

  @override
  String get foodQuickAddHint =>
      'Describe what you are eating and AI will estimate calories and macros.';

  @override
  String get foodQuickAddPlaceholder =>
      'E.g. 2 scrambled eggs with cheese and whole wheat toast';

  @override
  String get foodQuickAddAction => 'Estimate with AI';

  @override
  String get foodManualAddHint =>
      'Enter nutrition for one serving. It is saved on this device for quick reuse.';

  @override
  String get foodManualAddAction => 'Continue';

  @override
  String get foodManualSavedFoods => 'Saved on this device';

  @override
  String get foodManualNoSaved => 'No manual foods saved yet.';

  @override
  String get foodManualNameRequired => 'Enter a food name.';

  @override
  String get foodManualCaloriesRequired => 'Enter calories greater than zero.';

  @override
  String get foodManualGramsLabel => 'total grams (g)';

  @override
  String get foodPortionUnit => 'serving';

  @override
  String get foodManualQuantityHint =>
      'Adjust servings; calories and macros scale automatically.';

  @override
  String get foodPhotoHint =>
      'Take a photo of your meal. AI will identify foods and suggest macros.';

  @override
  String get foodPhotoAction => 'Take photo';

  @override
  String get foodPhotoGalleryAction => 'Choose from gallery';

  @override
  String get foodPhotoReferenceCaption =>
      'This photo is used when recalculating with AI';

  @override
  String get foodPhotoTapToExpand => 'Tap to enlarge';

  @override
  String foodQuantityLabel(String unit) {
    return 'Amount ($unit)';
  }

  @override
  String get foodNameLabel => 'Name';

  @override
  String get foodNameHint => 'e.g. Grilled chicken with rice and broccoli';

  @override
  String get foodMacrosAutoHint =>
      'Adjust grams; calories and macros update automatically.';

  @override
  String get foodAiCorrectionHint => 'AI got it wrong?';

  @override
  String get foodAiCorrectionPlaceholder =>
      'E.g. it was 3 tortillas, not 2, each 56 kcal';

  @override
  String get foodAiCorrectionAction => 'Recalculate with AI';

  @override
  String get foodAnalyzing => 'Analyzing…';

  @override
  String get foodDetailTitle => 'Nutrition details';

  @override
  String get foodAddThis => 'Add this food';

  @override
  String get foodServingLabel => 'Serving';

  @override
  String get foodCaloriesLabel => 'Calories (kcal)';

  @override
  String get foodIngredients => 'Ingredients';

  @override
  String get foodIngredientBreakdownHint =>
      'Estimated weight per item — correct below if something looks off';

  @override
  String foodIngredientGrams(String grams) {
    return '~$grams g';
  }

  @override
  String foodIngredientTotalGrams(String grams) {
    return 'Estimated total · ~$grams g';
  }

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroFat => 'Fat';

  @override
  String get macroCarbs => 'Carbs';

  @override
  String get macroFiber => 'Fiber';

  @override
  String foodMealGoalPlaceholder(int eaten, int goal) {
    return '$eaten / $goal Cal';
  }

  @override
  String get routineExerciseSets => 'Sets';

  @override
  String routineExerciseWeight(String unit) {
    return 'Weight ($unit)';
  }

  @override
  String get routineAddSet => 'Add set';

  @override
  String routineSetNumber(int number) {
    return 'Set $number';
  }
}
