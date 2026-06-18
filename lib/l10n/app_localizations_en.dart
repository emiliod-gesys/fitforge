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
  String get navRoutines => 'Routines';

  @override
  String get navExercises => 'Exercises';

  @override
  String get navProgress => 'Progress';

  @override
  String get navSocial => 'Social';

  @override
  String get navProfile => 'Profile';

  @override
  String get coachAi => 'AI Coach';

  @override
  String get profileTitle => 'Profile';

  @override
  String get personalData => 'Personal details';

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
  String get kilograms => 'Kilograms';

  @override
  String get pounds => 'Pounds';

  @override
  String get bodyMetrics => 'Body metrics';

  @override
  String get trainingConfig => 'Training settings';

  @override
  String get goal => 'Goal';

  @override
  String get experienceLevel => 'Experience level';

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
  String get aiCoachSubtitle => 'Personalized recommendations';

  @override
  String get fitnessGoalTitle => 'Fitness goal';

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
  String xpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String get levelUp => 'Level up!';

  @override
  String streakXpBonus(String multiplier) {
    return 'Streak bonus ×$multiplier';
  }

  @override
  String get workouts30d => 'Workouts (30 d)';

  @override
  String get volume30d => 'Volume (30 d)';

  @override
  String get volumePerWorkout => 'Volume per workout';

  @override
  String get last30Days => 'Last 30 days';

  @override
  String get completeWorkoutsForVolume =>
      'Complete workouts to see your volume';

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
  String get friendsRanking => 'Friends ranking';

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
  String get enter => 'Sign in';

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
  String get thisWeek => 'This week';

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
  String get training => 'Training';

  @override
  String get finish => 'Finish';

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
  String get repsRequired => 'Enter the reps';

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
  String get coachAskHint => 'Ask a question or request a routine…';

  @override
  String get coachRoutineReady =>
      'Here is your routine. Review it and tap Save when ready.';

  @override
  String get coachRoutineFailed =>
      'Could not generate the routine. Try being more specific (muscles and duration).';

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
  String get shareNewRecords => '🏆 New records vs last time!';

  @override
  String get shareExercisesHeader => 'Exercises:';

  @override
  String shareExerciseLine(String name, int sets, int reps, String weight) {
    return '• $name: $sets× · $reps reps$weight';
  }

  @override
  String get shareHashtags => '#FitForge #Workout';

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
}
