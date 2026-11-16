import 'package:fitforge/core/subscription/subscription_features.dart';
import 'dart:typed_data';

import 'package:fitforge/core/voice/voice_command.dart';
import 'package:fitforge/core/voice/voice_ear.dart';
import 'package:fitforge/core/voice/voice_exercise_match.dart';
import 'package:fitforge/core/voice/voice_tts.dart';
import 'package:fitforge/core/voice/voice_wake_phrase.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:fitforge/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reading voice is always male', () {
    final voices = [
      {'name': 'es-mx-x-sfb-local', 'locale': 'es-MX', 'network_required': '0'},
      {'name': 'es-es-x-eef-local', 'locale': 'es-ES', 'gender': 'female'},
      {'name': 'es-us-x-esc-local', 'locale': 'es-US', 'network_required': '0'},
      {'name': 'es-es-x-eed-network', 'locale': 'es-ES', 'network_required': '1'},
      {'name': 'en-us-x-sfg-local', 'locale': 'en-US', 'features': 'female'},
      {'name': 'en-us-x-iom-local', 'locale': 'en-US', 'gender': 'male'},
      {'name': 'en-US-GuyNeural', 'locale': 'en-US', 'network_required': '1'},
    ];

    final spanish = VoiceTts.maleVoices(voices, english: false);
    expect(spanish.map((voice) => voice['name']), [
      'es-us-x-esc-local',
      'es-es-x-eed-network',
    ]);

    final english = VoiceTts.maleVoices(voices, english: true);
    expect(english.first['name'], 'en-US-GuyNeural');
    expect(english.map((voice) => voice['name']), isNot(contains('en-us-x-sfg-local')));

    expect(
      VoiceTts.maleVoices(
        [
          {'name': 'es-mx-x-sfb-local', 'locale': 'es-MX'},
        ],
        english: false,
      ),
      isEmpty,
    );
  });

  test('wake phrase accepts pronunciation variants', () {
    expect(VoiceWakePhrase.strip('Hey Forgen'), '');
    expect(VoiceWakePhrase.strip('hey forjen'), '');
    expect(VoiceWakePhrase.strip('ey foryen'), '');
    expect(VoiceWakePhrase.strip('forguen'), '');
    expect(VoiceWakePhrase.strip('Hey Forgen agrega press'), 'agrega press');
    expect(VoiceWakePhrase.strip('agrega forgen'), isNull);
    expect(VoiceWakePhrase.strip('forget it'), isNull);
  });

  test('add exercise command keeps the muscle and equipment', () {
    final intent = parseVoiceCommand(
      'Agrega un ejercicio para pecho superior con mancuernas',
      confirming: false,
    );
    expect(intent, isA<VoiceAddExercise>());
    expect(
      (intent as VoiceAddExercise).query,
      'pecho superior con mancuernas',
    );
  });

  test('log, day, record and confirmation commands', () {
    final log = parseVoiceCommand('anota 80 kilos por 8', confirming: false);
    expect(log, isA<VoiceLogSet>());
    final logged = log as VoiceLogSet;
    expect(logged.weight, 80);
    expect(logged.reps, 8);
    expect(logged.unit, 'kg');

    expect(
      parseVoiceCommand('cómo voy de proteína', confirming: false),
      isA<VoiceAskDay>(),
    );
    expect(
      parseVoiceCommand('cuál es mi récord de press banca', confirming: false),
      isA<VoiceAskRecord>(),
    );
    expect(
      parseVoiceCommand('quita la última serie', confirming: false),
      isA<VoiceRemoveLastSet>(),
    );
    expect(
      (parseVoiceCommand('quita dos series', confirming: false) as VoiceRemoveLastSet)
          .count,
      2,
    );
    final addedSets = parseVoiceCommand('agrega una serie', confirming: false);
    expect(addedSets, isA<VoiceAddSets>());
    expect((addedSets as VoiceAddSets).count, 1);
    expect(
      (parseVoiceCommand('añade 3 series', confirming: false) as VoiceAddSets)
          .count,
      3,
    );
    expect(parseVoiceCommand('otra serie', confirming: false), isA<VoiceAddSets>());
    expect(parseVoiceCommand('add two sets', confirming: false), isA<VoiceAddSets>());
    expect(
      (parseVoiceCommand('remove a set', confirming: false) as VoiceRemoveLastSet)
          .count,
      1,
    );
    final pounds = parseVoiceCommand(
      'registra una serie, 60lb y 12 reps',
      confirming: false,
    );
    expect(pounds, isA<VoiceLogSet>());
    final spokenSet = pounds as VoiceLogSet;
    expect(spokenSet.weight, 60);
    expect(spokenSet.reps, 12);
    expect(spokenSet.unit, 'lb');
    expect(
      parseVoiceCommand('12 repeticiones con 60 libras', confirming: false),
      isA<VoiceLogSet>(),
    );
    expect(
      (parseVoiceCommand('descanso de 90 segundos', confirming: false) as VoiceSetRest)
          .seconds,
      90,
    );
    expect(
      (parseVoiceCommand('pon el descanso en 2 minutos', confirming: false)
              as VoiceSetRest)
          .seconds,
      120,
    );
    expect(voiceWantsExerciseAdded('agrega una serie'), isFalse);
    expect(voiceWantsExerciseAdded('agrega biceps con mancuernas'), isTrue);
    expect(parseVoiceCommand('sí', confirming: true), isA<VoiceConfirmYes>());
    expect(parseVoiceCommand('no', confirming: true), isA<VoiceConfirmNo>());
  });

  test('upper chest with dumbbells ranks the incline press first', () {
    final incline = _exercise(
      'Dumbbell Incline Bench Press',
      equipment: const ['Dumbbell'],
      muscles: const ['Chest'],
      aliases: const ['press inclinado con mancuernas'],
    );
    final flat = _exercise(
      'Dumbbell Bench Press',
      equipment: const ['Dumbbell'],
      muscles: const ['Chest'],
    );
    final barbell = _exercise(
      'Barbell Bench Press',
      equipment: const ['Barbell'],
      muscles: const ['Chest'],
    );

    final best = VoiceExerciseMatch.best(
      [barbell, flat, incline],
      'pecho superior con mancuernas',
    );
    expect(best?.exercise.name, incline.name);
    expect(best?.spokenName, 'press inclinado con mancuernas');
  });

  test('biceps with dumbbells keeps only that muscle and gear', () {
    final curl = _exercise(
      'Dumbbell Curl',
      equipment: const ['Dumbbell'],
      muscles: const ['Biceps'],
      aliases: const ['curl con mancuernas'],
    );
    final hammer = _exercise(
      'Dumbbell Hammer Curl',
      equipment: const ['Dumbbell'],
      muscles: const ['Biceps'],
      aliases: const ['curl martillo'],
    );
    final barbell = _exercise(
      'Barbell Curl',
      equipment: const ['Barbell'],
      muscles: const ['Biceps'],
    );
    final bench = _exercise(
      'Dumbbell Bench Press',
      equipment: const ['Dumbbell'],
      muscles: const ['Chest'],
    );
    bool biceps(Exercise exercise) {
      return exercise.muscles.any((muscle) => muscle.toLowerCase().contains('bicep'));
    }

    final broad = VoiceExerciseMatch.specificMatches(
      [curl, hammer, barbell, bench],
      'biceps mancuernas',
      inMuscle: biceps,
    );
    expect(broad.map((exercise) => exercise.name), [
      'Dumbbell Curl',
      'Dumbbell Hammer Curl',
    ]);

    final hammerOnly = VoiceExerciseMatch.specificMatches(
      [curl, hammer, barbell, bench],
      'martillo biceps mancuernas',
      inMuscle: biceps,
    );
    expect(hammerOnly.map((exercise) => exercise.name), ['Dumbbell Hammer Curl']);

    final plain = VoiceExerciseMatch.bestMatch(
      [curl, hammer, barbell, bench],
      'biceps mancuernas',
      inMuscle: biceps,
    );
    expect(plain?.exercise.name, 'Dumbbell Curl');

    final hammerPick = VoiceExerciseMatch.bestMatch(
      [curl, hammer, barbell, bench],
      'martillo biceps mancuernas',
      inMuscle: biceps,
    );
    expect(hammerPick?.exercise.name, 'Dumbbell Hammer Curl');
    expect(
      VoiceExerciseMatch.cloudQueries('biceps mancuernas', muscleGroup: 'Bíceps'),
      contains('dumbbell biceps'),
    );
  });

  test('silence does not produce an utterance', () {
    final ear = VoiceEar();
    final quiet = Uint8List(3200);
    expect(ear.add(quiet), isNull);
    final twoSeconds = _pcm(const Duration(seconds: 2), 0);
    expect(ear.add(twoSeconds), isNull);
  });

  test('a take ends even if the sound never drops', () {
    final ear = VoiceEar();
    ear.beginTake();
    expect(ear.add(_pcm(const Duration(milliseconds: 4400), 8000)), isNull);
    expect(ear.add(_pcm(const Duration(milliseconds: 200), 8000)), isNotNull);
  });

  test('a new take ends when the person stops talking', () {
    final ear = VoiceEar();
    ear.beginTake();
    expect(ear.add(_pcm(const Duration(milliseconds: 500), 8000)), isNull);
    final phrase = ear.add(_pcm(const Duration(milliseconds: 800), 0));
    expect(phrase, isNotNull);
    expect(phrase!.length, greaterThan(1000));
  });

  test('speech is sent after a short window', () {
    final ear = VoiceEar();
    final spoken = _pcm(const Duration(seconds: 2), 8000);
    expect(ear.add(spoken), isNotNull);
  });

  test('pcm becomes a wav', () {
    final wav = pcm16ToWav(Uint8List(8));
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(wav.length, 44 + 8);
  });

  test('a biceps dumbbell exercise is an add, a routine is not', () {
    expect(
      voiceWantsExerciseAdded('agrega un ejercicio de biceps con mancuernas'),
      isTrue,
    );
    expect(
      voiceWantsExerciseAdded('add a dumbbell biceps exercise'),
      isTrue,
    );
    expect(voiceWantsExerciseAdded('crea una rutina de biceps'), isFalse);
    expect(
      voiceWantsExerciseAdded('agrega un ejercicio de pecho superior'),
      isTrue,
    );
    expect(
      voiceWantsExerciseAdded(
        'agrega un ejercicio de pecho superior al entrenamiento',
      ),
      isTrue,
    );
    expect(
      voiceAsksForNewRoutine('agrega un ejercicio de pecho superior'),
      isFalse,
    );
    expect(
      voiceAsksForNewRoutine(
        'agrega un ejercicio de pecho superior al entrenamiento',
      ),
      isFalse,
    );
    expect(voiceAsksForNewRoutine('crea una rutina de pecho'), isTrue);
    expect(
      voiceExerciseQuery('agrega un ejercicio de pecho superior al entrenamiento'),
      'pecho superior',
    );
    expect(
      voiceExerciseQuery('agrega un ejercicio de biceps con mancuernas'),
      'biceps mancuernas',
    );
  });

  test('adding and logging are actions, questions are not', () {
    expect(
      voiceCommandIsAction(
        parseVoiceCommand('agrega press inclinado', confirming: false),
      ),
      isTrue,
    );
    expect(
      voiceCommandIsAction(
        parseVoiceCommand('como voy de proteina', confirming: false),
      ),
      isFalse,
    );
  });

  test('voice assistant is Gymrat Pro only', () {
    UserProfile profile(SubscriptionTier tier, {bool hasKey = false}) {
      return UserProfile(
        id: 'u',
        createdAt: DateTime.utc(2026, 1, 1),
        subscriptionTier: tier,
        aiProvider: hasKey ? AiProvider.openai : AiProvider.none,
        hasAiKey: hasKey,
      );
    }

    expect(profile(SubscriptionTier.gymratPro).canUseVoiceAssistant, isTrue);
    expect(profile(SubscriptionTier.gymrat).canUseVoiceAssistant, isFalse);
    expect(
      profile(SubscriptionTier.free, hasKey: true).canUseVoiceAssistant,
      isFalse,
    );
    expect(
      profile(SubscriptionTier.free, hasKey: true).canUseFoodPhotoAi,
      isTrue,
    );
  });
}

Uint8List _pcm(Duration duration, int amplitude) {
  final samples = 16000 * duration.inMilliseconds ~/ 1000;
  final out = Uint8List(samples * 2);
  final data = ByteData.sublistView(out);
  for (var i = 0; i < samples; i++) {
    data.setInt16(i * 2, amplitude, Endian.little);
  }
  return out;
}

Exercise _exercise(
  String name, {
  required List<String> equipment,
  required List<String> muscles,
  List<String> aliases = const [],
}) {
  return Exercise(
    catalogId: name,
    name: name,
    equipment: equipment,
    muscles: muscles,
    aliases: aliases,
  );
}
