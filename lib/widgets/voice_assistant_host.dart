import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/ai_coach_routine_prompt.dart';
import '../core/router/app_router.dart';
import '../core/subscription/subscription_features.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/exercise_picker_merge.dart';
import '../core/utils/exercise_text_search.dart';
import '../core/utils/muscle_inference.dart';
import '../core/voice/voice_command.dart';
import '../core/voice/voice_ear.dart';
import '../core/voice/voice_exercise_match.dart';
import '../core/voice/voice_lines.dart';
import '../core/voice/voice_tts.dart';
import '../core/voice/voice_mic_gate.dart';
import '../core/voice/voice_wake_phrase.dart';
import '../core/subscription/plan_upgrade.dart';
import '../core/subscription/routine_limit_gate.dart';
import '../l10n/l10n_extensions.dart';
import '../models/exercise.dart';
import '../models/profile.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import '../providers/app_providers.dart';
import '../services/ai_coach_service.dart';
import '../services/exercise_service.dart';
import '../services/voice_action_runner.dart';

enum _VoicePhase { idle, wake, command, confirm, busy }

/// Escucha «Hey Forgen» con la app abierta, solo en Gymrat Pro.
class VoiceAssistantHost extends ConsumerStatefulWidget {
  const VoiceAssistantHost({super.key});

  @override
  ConsumerState<VoiceAssistantHost> createState() => _VoiceAssistantHostState();
}

class _VoiceAssistantHostState extends ConsumerState<VoiceAssistantHost>
    with WidgetsBindingObserver {
  final AudioRecorder _recorder = AudioRecorder();
  final VoiceEar _ear = VoiceEar();
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  late final Future<void> _playerReady = _preparePlayer();
  StreamSubscription<Uint8List>? _mic;

  _VoicePhase _phase = _VoicePhase.idle;
  int _turn = 0;
  VoicePending? _pending;
  bool _micDenied = false;
  bool _reportedUnavailable = false;
  bool _resumed = true;
  bool _streamOpen = false;
  bool _recovering = false;
  bool _transcribing = false;
  Map<String, String>? _maleVoice;
  bool? _maleVoiceEnglish;
  Uint8List? _queued;
  String _title = '';
  String _heard = '';
  bool _visible = false;
  bool _yesNo = false;

  bool get _english {
    final code = ref.read(appLocaleProvider).languageCode;
    return VoiceLines.english(code);
  }

  bool get _allowed {
    final profile = ref.read(profileProvider).valueOrNull;
    final voiceOn = ref.read(voiceAssistantEnabledProvider).valueOrNull ?? false;
    return _resumed &&
        VoiceMicGate.holdCount.value == 0 &&
        (profile?.canUseVoiceAssistant ?? false) &&
        voiceOn;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    VoiceMicGate.holdCount.addListener(_onGate);
    unawaited(_tts.awaitSpeakCompletion(true));
    unawaited(_tts.setSpeechRate(0.46));
    unawaited(_tts.setPitch(0.92));
    unawaited(_tts.setVolume(1));
    unawaited(_playerReady);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_arm());
    });
  }

  @override
  void dispose() {
    VoiceMicGate.holdCount.removeListener(_onGate);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_closeMic());
    unawaited(_tts.stop());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (_resumed) {
      unawaited(_arm());
    } else {
      unawaited(_stop(hide: true));
    }
  }

  void _onGate() {
    if (!mounted) return;
    if (VoiceMicGate.holdCount.value > 0) {
      unawaited(_stop(hide: true));
    } else {
      unawaited(_arm());
    }
  }

  Future<void> _stop({required bool hide}) async {
    _phase = _VoicePhase.idle;
    _pending = null;
    _ear.reset();
    await _closeMic();
    if (!mounted) return;
    if (hide && _visible) {
      setState(() {
        _visible = false;
        _yesNo = false;
        _heard = '';
      });
    }
  }

  Future<void> _closeMic() async {
    _streamOpen = false;
    await _mic?.cancel();
    _mic = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  Future<void> _arm() async {
    if (!mounted || !_allowed) return;
    if (_streamOpen) {
      if (_phase == _VoicePhase.idle) _phase = _VoicePhase.wake;
      return;
    }
    if (_micDenied) return;

    final granted = await _recorder.hasPermission();
    if (!mounted || !_allowed) return;
    if (!granted) {
      _micDenied = true;
      _tellOnce(VoiceLines.micDenied(_english));
      return;
    }

    try {
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          echoCancel: true,
          noiseSuppress: true,
          autoGain: true,
          audioInterruption: AudioInterruptionMode.none,
        ),
      );
      _streamOpen = true;
      if (_phase == _VoicePhase.idle) _phase = _VoicePhase.wake;
      _mic = stream.listen(
        _onPcm,
        onError: (_) {
          if (!mounted) return;
          unawaited(_recoverMic());
        },
        onDone: () {
          if (!mounted) return;
          unawaited(_recoverMic());
        },
      );
    } catch (_) {
      _streamOpen = false;
      _phase = _VoicePhase.idle;
      if (!_reportedUnavailable) {
        _reportedUnavailable = true;
        _tellOnce(VoiceLines.micUnavailable(_english));
      }
    }
  }

  void _onPcm(Uint8List chunk) {
    if (!_streamOpen) return;
    final uttered = _ear.add(chunk);
    if (uttered == null) return;
    if (_phase != _VoicePhase.wake &&
        _phase != _VoicePhase.command &&
        _phase != _VoicePhase.confirm) {
      return;
    }
    if (_transcribing) {
      _queued = uttered;
      return;
    }
    unawaited(_onUtterance(uttered));
  }

  Future<void> _onUtterance(Uint8List pcm) async {
    if (_transcribing || !mounted) return;
    final turn = _turn;
    _transcribing = true;
    try {
      final text = await ref.read(aiCoachServiceProvider).transcribeUtterance(
            audioBytes: pcm16ToWav(pcm),
            profile: ref.read(profileProvider).valueOrNull,
          );
      final words = text?.trim() ?? '';
      if (!mounted || turn != _turn || words.isEmpty || !_allowed) return;
      setState(() => _heard = words);
      if (_phase == _VoicePhase.command) {
        await _handleSpoken(words);
        return;
      }
      if (_phase == _VoicePhase.confirm) {
        await _finishCommand(words);
        return;
      }
      if (_phase == _VoicePhase.wake && VoiceWakePhrase.strip(words) != null) {
        await _fireWake(words);
      }
    } catch (_) {
    } finally {
      _transcribing = false;
      final next = _queued;
      _queued = null;
      if (next != null && mounted) unawaited(_onUtterance(next));
    }
  }

  Future<void> _fireWake(String words) async {
    if (!mounted || _phase != _VoicePhase.wake) return;
    final remainder = VoiceWakePhrase.strip(words);
    if (remainder == null) return;

    _phase = _VoicePhase.busy;
    _ear.ignoreFor(const Duration(seconds: 2));
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() {
      _visible = true;
      _title = VoiceLines.ack(_english);
      _heard = '';
      _yesNo = false;
    });
    await _playAck();
    if (!mounted || !_allowed) return;
    if (remainder.isNotEmpty) {
      await _handleSpoken(remainder);
      return;
    }
    _listenForCommand();
  }

  Future<void> _recoverMic() async {
    if (_recovering) return;
    _recovering = true;
    final keepTake = _phase == _VoicePhase.command || _phase == _VoicePhase.confirm;
    try {
      await _closeMic();
      if (!mounted || !_allowed) return;
      await _arm();
      if (keepTake) await _listenForCommand();
    } finally {
      _recovering = false;
    }
  }

  Future<void> _ensureMicLive() async {
    if (!mounted || !_allowed) return;
    final paused = _streamOpen && await _recorder.isPaused();
    if (paused) {
      try {
        await _recorder.resume();
        return;
      } catch (_) {}
    }
    final recording = _streamOpen && await _recorder.isRecording();
    if (recording) return;
    await _closeMic();
    await _arm();
  }

  Future<void> _listenForCommand() async {
    if (!mounted || !_allowed) return;
    await _ensureMicLive();
    if (!mounted || !_allowed) return;
    _phase = _pending != null ? _VoicePhase.confirm : _VoicePhase.command;
    _ear.beginTake();
  }

  bool _onActiveWorkout() {
    final path = ref.read(routerProvider).state.uri.path;
    return path == '/workout/active' || path.startsWith('/workout/active/');
  }

  Future<Workout?> _liveWorkout() async {
    try {
      final loaded = await ref.read(activeWorkoutProvider.future);
      if (loaded != null) return loaded;
    } catch (_) {}
    final cached = ref.read(activeWorkoutProvider).valueOrNull;
    if (cached != null) return cached;
    if (!_onActiveWorkout()) return null;
    try {
      return await ref.read(workoutServiceProvider).getActiveWorkout();
    } catch (_) {
      return null;
    }
  }

  /// «Pecho superior» durante el entreno es un ejercicio, no una rutina.
  bool _namesOneExercise(String text) {
    final normalized = ExerciseTextSearch.normalize(text);
    if (normalized.isEmpty) return false;
    if (RegExp(r'^(como|how|why|por que|porque|que |cual |cuanto |what |which )')
        .hasMatch(normalized)) {
      return false;
    }
    final muscles = AiCoachService.parseTargetMuscles(text)
        .where(AppConstants.muscleGroups.contains)
        .toList();
    return muscles.length == 1 && normalized.split(' ').length <= 8;
  }

  Future<void> _handleSpoken(String words) async {
    final text = words.trim();
    if (text.isEmpty) {
      await _finishTurn(VoiceLines.didNotCatch(_english));
      return;
    }
    final intent = parseVoiceCommand(text, confirming: false);
    if (intent is VoiceAddSets || intent is VoiceRemoveLastSet) {
      final count = intent is VoiceAddSets ? intent.count : (intent as VoiceRemoveLastSet).count;
      final say = await VoiceActionRunner(ref).adjustSets(
        english: _english,
        add: intent is VoiceAddSets,
        count: count,
      );
      await _finishTurn(say);
      return;
    }
    if (intent is VoiceLogSet) {
      final say = await VoiceActionRunner(ref).logFocusedSet(
        english: _english,
        weight: intent.weight,
        reps: intent.reps,
        unit: intent.unit,
      );
      await _finishTurn(say);
      return;
    }
    if (intent is VoiceSetRest) {
      final say = await VoiceActionRunner(ref).setRest(
        english: _english,
        seconds: intent.seconds,
      );
      await _finishTurn(say);
      return;
    }
    final workout = await _liveWorkout();
    final wantsExercise = voiceWantsExerciseAdded(text);
    final asksRoutine = voiceAsksForNewRoutine(text);
    if (wantsExercise && !asksRoutine) {
      if (workout == null) {
        await _finishTurn(VoiceLines.noWorkout(_english));
        return;
      }
      await _addSpokenExercise(text, workout);
      return;
    }
    if (workout != null && !asksRoutine && _namesOneExercise(text)) {
      await _addSpokenExercise(text, workout);
      return;
    }
    final routineRequest = AiCoachService.voiceShouldBuildRoutine(text);
    if (routineRequest && (workout == null || asksRoutine)) {
      await _offerRoutine(text);
      return;
    }
    if (voiceCommandIsAction(intent)) {
      await _apply(intent);
      return;
    }
    await _answerWithCoach(text);
  }

  Future<void> _addSpokenExercise(String text, Workout workout) async {
    final query = voiceExerciseQuery(text);
    final muscles = AiCoachService.parseTargetMuscles(text)
        .where(AppConstants.muscleGroups.contains)
        .toList();
    final muscle = muscles.length == 1 ? muscles.first : null;
    final catalog = await _exercisesForVoice(query, muscle);
    final best = VoiceExerciseMatch.bestMatch(
      catalog,
      query,
      inMuscle: muscle == null
          ? null
          : (exercise) => MuscleInference.matchesMuscleGroup(
                exercise: exercise,
                muscleGroup: muscle,
              ),
    );
    if (best == null) {
      await _finishTurn(VoiceLines.couldNotAdd(_english));
      return;
    }
    final already = workout.exercises.any(
      (item) => item.exerciseId == best.exercise.id,
    );
    if (already) {
      await _finishTurn(
        _english
            ? '${best.spokenName} is already in this workout.'
            : '${best.spokenName} ya está en este entrenamiento.',
      );
      return;
    }
    await _commitExercise(workout, best.exercise, best.spokenName);
  }

  Future<void> _commitExercise(
    Workout workout,
    Exercise exercise,
    String spokenName,
  ) async {
    await ref.read(workoutServiceProvider).addExerciseToWorkout(
          workout.id,
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          imageUrl: exercise.imageUrl,
          loggingType: exercise.loggingType,
        );
    ref.invalidate(activeWorkoutProvider);
    await _finishTurn(VoiceLines.added(_english, spokenName));
  }

  Future<void> _offerRoutine(String text) async {
    final turn = _turn;
    _phase = _VoicePhase.busy;
    _ear.cancelTake();
    if (!mounted) return;
    final thinking = VoiceLines.thinking(_english);
    setState(() {
      _visible = true;
      _title = thinking;
      _heard = '';
      _yesNo = false;
    });
    final thinkingSpeech = _speak(thinking);
    Routine? routine;
    try {
      routine = await _generateRoutine(text);
    } catch (_) {
      routine = null;
    }
    await thinkingSpeech;
    if (!mounted || turn != _turn) return;
    if (routine == null || routine.exercises.length < 2) {
      final equipment = AiCoachRoutinePrompt.parseAvailableEquipment(text);
      final muscles = AiCoachService.parseTargetMuscles(text);
      final say = equipment.isNotEmpty || muscles.isNotEmpty
          ? (_english
              ? "I couldn't find enough exercises for that muscle and equipment."
              : 'No encontré suficientes ejercicios para ese músculo y ese equipo.')
          : context.l10n.coachRoutineFailed;
      await _finishTurn(say);
      return;
    }
    await _showRoutine(routine);
  }

  Future<Routine?> _generateRoutine(String text) async {
    final profile = await ref.read(profileProvider.future);
    final lang = ref.read(preferredLanguageProvider);
    final exerciseService = ref.read(exerciseServiceProvider);
    exerciseService.configure(language: lang);
    final muscles = AiCoachService.resolveTargetMuscles(
      currentMessage: text,
      history: const [],
    );
    final catalog = await _catalogForRoutine(exerciseService, text, muscles);
    final workouts = await ref.read(workoutsProvider.future);
    final routines = await ref.read(routinesProvider.future);
    final bodyMetrics = await ref.read(bodyMetricSnapshotsProvider.future);
    final weeklyStats = await ref.read(workoutWeeklyStatsProvider.future);
    final personalRecords = await ref.read(personalRecordsProvider.future);
    final nutrition = await ref.read(coachNutritionServiceProvider).load(
          profile: profile,
          bodyMetrics: bodyMetrics,
        );
    final routineLimit = await ref.read(routineLimitStatusProvider.future);
    return ref.read(aiCoachServiceProvider).generateRoutineFromMessage(
          userMessage: text,
          catalog: catalog,
          profile: profile,
          recentWorkouts: workouts,
          routines: routines,
          bodyMetrics: bodyMetrics,
          weeklyStats: weeklyStats,
          personalRecords: personalRecords,
          languageCode: ref.read(appLocaleProvider).languageCode,
          nutrition: nutrition,
          routineLimit: routineLimit,
        );
  }

  Future<void> _showRoutine(Routine routine) async {
    if (!mounted) return;
    setState(() => _visible = false);
    _phase = _VoicePhase.wake;
    ref.read(pendingVoiceRoutineProvider.notifier).state = routine;
    ref.read(routerProvider).push('/routines/new?voice=1', extra: routine);
    await _speak(VoiceLines.routineReady(_english, routine.name));
  }

  Future<List<Exercise>> _catalogForRoutine(
    ExerciseService exerciseService,
    String text,
    List<String> muscles,
  ) async {
    List<Exercise> base;
    try {
      base = await exerciseService.fetchAiCoachCatalog(targetMuscles: muscles);
    } catch (_) {
      base = ref.read(exercisesProvider).valueOrNull ?? const <Exercise>[];
    }
    final equipment = AiCoachRoutinePrompt.parseAvailableEquipment(text);
    if (equipment.isEmpty) return base;
    final gear = equipment.map(AiCoachRoutinePrompt.equipmentLabel).join(' ');
    final queries = <String>{
      if (muscles.isEmpty) ...VoiceExerciseMatch.cloudQueries(gear),
      for (final muscle in muscles)
        ...VoiceExerciseMatch.cloudQueries('$gear $muscle', muscleGroup: muscle),
    };
    final pages = await Future.wait(queries.map((item) async {
      try {
        return await exerciseService.searchCloudExercises(item, limit: 40);
      } catch (_) {
        return const <Exercise>[];
      }
    }));
    return mergeBundledAndCloudExercises(
      bundled: base,
      cloud: [for (final page in pages) ...page],
    );
  }

  Future<List<Exercise>> _exercisesForVoice(String query, String? muscle) async {
    final bundled = ref.read(exercisesProvider).valueOrNull ??
        await ref.read(exercisesProvider.future) ??
        const <Exercise>[];
    final service = ref.read(exerciseServiceProvider);
    service.configure(language: ref.read(preferredLanguageProvider));
    final queries = VoiceExerciseMatch.cloudQueries(query, muscleGroup: muscle);
    final pages = await Future.wait(queries.map((item) async {
      try {
        return await service.searchCloudExercises(item, limit: 40);
      } catch (_) {
        return const <Exercise>[];
      }
    }));
    return mergeBundledAndCloudExercises(
      bundled: bundled,
      cloud: [for (final page in pages) ...page],
    );
  }

  Future<void> _answerWithCoach(String words) async {
    final turn = _turn;
    _phase = _VoicePhase.busy;
    _ear.cancelTake();
    if (!mounted) return;
    final thinking = VoiceLines.thinking(_english);
    setState(() {
      _visible = true;
      _title = thinking;
      _heard = '';
      _yesNo = false;
    });
    final thinkingSpeech = _speak(thinking);

    final clipped = words.length > AiCoachService.maxUserMessageLength
        ? words.substring(0, AiCoachService.maxUserMessageLength)
        : words;
    String answer;
    try {
      answer = await _coachAnswer(clipped);
    } catch (_) {
      answer = VoiceLines.didNotCatch(_english);
    }
    await thinkingSpeech;
    if (!mounted || turn != _turn) return;
    final failedLine = context.l10n.coachRoutineFailed;
    final inWorkout = ref.read(activeWorkoutProvider).valueOrNull != null ||
        _onActiveWorkout();
    final writtenRoutine = !inWorkout &&
        (AiCoachService.containsRoutineJson(answer) ||
            AiCoachService.looksLikeWrittenRoutine(answer) ||
            AiCoachService.voiceShouldBuildRoutine(words));
    if (writtenRoutine) {
      Routine? parsed;
      if (AiCoachService.containsRoutineJson(answer)) {
        parsed = await _routineFromCoachText(answer, words);
      }
      if (parsed == null || parsed.exercises.length < 2) {
        parsed = await _generateRoutine(words);
      }
      if (parsed != null && parsed.exercises.length >= 2) {
        await _showRoutine(parsed);
        return;
      }
      final equipment = AiCoachRoutinePrompt.parseAvailableEquipment(words);
      final muscles = AiCoachService.parseTargetMuscles(words);
      final say = equipment.isNotEmpty || muscles.isNotEmpty
          ? (_english
              ? "I couldn't find enough exercises for that muscle and equipment."
              : 'No encontré suficientes ejercicios para ese músculo y ese equipo.')
          : failedLine;
      await _finishTurn(say);
      return;
    }
    final spoken = _plainCoachText(answer);
    setState(() {
      _visible = true;
      _title = spoken;
      _heard = '';
      _yesNo = false;
    });
    await _speak(spoken);
    if (!mounted || turn != _turn) return;
    _phase = _VoicePhase.wake;
  }

  Future<Routine?> _routineFromCoachText(String answer, String request) async {
    final lang = ref.read(preferredLanguageProvider);
    final exerciseService = ref.read(exerciseServiceProvider);
    exerciseService.configure(language: lang);
    final muscles = AiCoachService.resolveTargetMuscles(
      currentMessage: request,
      history: const [],
    );
    final catalog = await exerciseService.fetchAiCoachCatalog(
      targetMuscles: muscles,
    );
    return ref.read(aiCoachServiceProvider).tryParseRoutineFromResponse(
          answer,
          targetMuscles: muscles,
          profile: ref.read(profileProvider).valueOrNull,
          catalog: catalog,
        );
  }

  Future<String> _coachAnswer(String words) async {
    if (!mounted) return VoiceLines.didNotCatch(_english);
    final l10n = context.l10n;
    final profile = await ref.read(profileProvider.future);
    final usage = ref.read(coachUsageServiceProvider);
    final profileService = ref.read(profileServiceProvider);
    if (!await usage.canSendMessage(profile, profileService)) {
      final status = await usage.getStatus(profile, profileService);
      return PlanUpgrade.coachMessage(
        l10n,
        profile?.subscriptionTier ?? SubscriptionTier.free,
        status.limit ?? 0,
      );
    }

    final workouts = await ref.read(workoutsProvider.future);
    final routines = await ref.read(routinesProvider.future);
    final bodyMetrics = await ref.read(bodyMetricSnapshotsProvider.future);
    final weeklyStats = await ref.read(workoutWeeklyStatsProvider.future);
    final personalRecords = await ref.read(personalRecordsProvider.future);
    final nutrition = await ref.read(coachNutritionServiceProvider).load(
          profile: profile,
          bodyMetrics: bodyMetrics,
        );
    final routineLimit = await ref.read(routineLimitStatusProvider.future);
    final answer = await ref.read(aiCoachServiceProvider).getRecommendation(
          userMessage: words,
          recentWorkouts: workouts,
          routines: routines,
          profile: profile,
          bodyMetrics: bodyMetrics,
          weeklyStats: weeklyStats,
          personalRecords: personalRecords,
          languageCode: ref.read(appLocaleProvider).languageCode,
          nutrition: nutrition,
          routineLimit: routineLimit,
        );
    await usage.recordMessage();
    ref.invalidate(coachUsageStatusProvider);
    final trimmed = answer.trim();
    if (trimmed.isEmpty) return VoiceLines.didNotCatch(_english);
    return trimmed;
  }

  String _plainCoachText(String text) {
    return text
        .replaceAll(RegExp(r'[*_`#]'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  void _dismissCard() {
    _turn++;
    _pending = null;
    _queued = null;
    _ear.cancelTake();
    _phase = _VoicePhase.wake;
    unawaited(_tts.stop());
    unawaited(_player.stop());
    unawaited(_ensureMicLive());
    if (!mounted) return;
    setState(() {
      _visible = false;
      _yesNo = false;
      _heard = '';
    });
  }

  Future<void> _finishCommand(String words) async {
    _phase = _VoicePhase.busy;
    final wake = VoiceWakePhrase.strip(words);
    if (wake != null && wake.isEmpty) {
      _phase = _VoicePhase.wake;
      await _fireWake(words);
      return;
    }
    final command = wake ?? words;
    await _apply(parseVoiceCommand(command, confirming: _pending != null));
  }

  Future<void> _apply(VoiceIntent intent) async {
    final english = _english;
    if (_pending != null) {
      if (intent is VoiceConfirmYes) {
        final pending = _pending!;
        _pending = null;
        final say = await VoiceActionRunner(ref).confirm(pending, english: english);
        await _finishTurn(say);
        return;
      }
      if (intent is VoiceConfirmNo) {
        _pending = null;
        await _finishTurn(VoiceLines.cancelled(english));
        return;
      }
      setState(() => _title = VoiceLines.sayYesOrNo(english));
      await _speak(VoiceLines.sayYesOrNo(english));
      _listenForCommand();
      return;
    }

    final proposal = await VoiceActionRunner(ref).propose(intent, english: english);
    _pending = proposal.pending;
    if (!mounted) return;
    setState(() {
      _visible = true;
      _title = proposal.say;
      _yesNo = proposal.pending != null;
    });
    await _speak(proposal.say);
    if (!mounted || !_allowed) return;
    if (proposal.pending != null) {
      _listenForCommand();
      return;
    }
    await _finishTurn(proposal.say, alreadySpoken: true);
  }

  Future<void> _finishTurn(String say, {bool alreadySpoken = false}) async {
    _pending = null;
    if (!mounted) return;
    setState(() {
      _visible = true;
      _title = say;
      _yesNo = false;
      _heard = '';
    });
    if (!alreadySpoken) await _speak(say);
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _visible = false);
    _phase = _VoicePhase.wake;
    if (!_streamOpen) await _arm();
  }

  Future<void> _preparePlayer() async {
    await _player.setVolume(1);
    await _player.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: const AudioContextAndroid(
          contentType: AndroidContentType.speech,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
  }

  Future<void> _playAck() async {
    _ear.ignoreFor(const Duration(seconds: 2));
    try {
      await _playerReady;
      await _player.stop();
      await _player.play(
        AssetSource(_english ? 'sounds/voice_tell_me.mp3' : 'sounds/voice_dime.mp3'),
      );
      await _player.onPlayerComplete.first.timeout(const Duration(seconds: 3));
    } catch (_) {
      await _speak(VoiceLines.ack(_english));
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  Future<void> _speak(String text) async {
    final spoken = text.trim();
    if (spoken.isEmpty) return;
    final seconds = (spoken.length / 12).ceil().clamp(4, 90);
    _ear.ignoreFor(Duration(seconds: seconds));
    try {
      await _preferMaleVoice();
      await _tts.stop();
      await _tts.speak(spoken);
    } catch (_) {}
    _ear.releaseIgnore();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _preferMaleVoice() async {
    final english = _english;
    if (_maleVoice != null && _maleVoiceEnglish == english) {
      final stuck = await _applyMaleVoice(_maleVoice!);
      if (stuck) return;
      _maleVoice = null;
    }

    var voices = await _readVoices();
    var males = VoiceTts.maleVoices(voices, english: english);
    if (males.isEmpty && await _useGoogleEngine()) {
      voices = await _readVoices();
      males = VoiceTts.maleVoices(voices, english: english);
    }
    for (final voice in males) {
      if (await _applyMaleVoice(voice)) {
        _maleVoice = voice;
        _maleVoiceEnglish = english;
        return;
      }
    }
    await _tts.setPitch(0.85);
    await _tts.setSpeechRate(0.46);
    await _tts.setVolume(1);
  }

  Future<List<Map<dynamic, dynamic>>> _readVoices() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return const [];
      return [for (final item in raw) if (item is Map) item];
    } catch (_) {
      return const [];
    }
  }

  Future<bool> _useGoogleEngine() async {
    try {
      const google = 'com.google.android.tts';
      final engines = await _tts.getEngines;
      if (engines is! List || !engines.any((item) => '$item' == google)) return false;
      final current = await _tts.getDefaultEngine;
      if (current == google) return false;
      final result = await _tts.setEngine(google);
      return result == 1 || result == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _applyMaleVoice(Map<String, String> voice) async {
    final locale = voice['locale'] ?? '';
    final name = voice['name'] ?? '';
    if (locale.isEmpty || name.isEmpty) return false;
    try {
      await _tts.setLanguage(locale);
      final applied = await _tts.setVoice({'name': name, 'locale': locale});
      await _tts.setPitch(0.88);
      await _tts.setSpeechRate(0.46);
      await _tts.setVolume(1);
      return applied == 1 || applied == true;
    } catch (_) {
      return false;
    }
  }

  void _tellOnce(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onYes() => unawaited(_apply(const VoiceConfirmYes()));

  void _onNo() => unawaited(_apply(const VoiceConfirmNo()));

  @override
  Widget build(BuildContext context) {
    ref.watch(voiceAssistantEnabledProvider);
    ref.listen(profileProvider, (previous, next) {
      final allowed = next.valueOrNull?.canUseVoiceAssistant ?? false;
      if (!allowed) {
        unawaited(_stop(hide: true));
      } else if (_phase == _VoicePhase.idle) {
        unawaited(_arm());
      }
    });
    ref.listen(voiceAssistantEnabledProvider, (previous, next) {
      if (!next.hasValue) return;
      if (next.requireValue) {
        if (_phase == _VoicePhase.idle) unawaited(_arm());
      } else {
        unawaited(_stop(hide: true));
      }
    });
    ref.listen(appLocaleProvider, (previous, next) {
      if (_phase == _VoicePhase.idle) unawaited(_arm());
    });

    if (!_visible) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _dismissCard,
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 16,
          right: 16,
          child: Material(
            color: AppColors.card,
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cobalt),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  if (_heard.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _heard,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    ),
                  ],
                  if (_yesNo)
                    Row(
                      children: [
                        TextButton(
                          onPressed: _onYes,
                          child: Text(_english ? 'Yes' : 'Sí'),
                        ),
                        TextButton(
                          onPressed: _onNo,
                          child: const Text('No'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
