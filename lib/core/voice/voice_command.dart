import '../utils/exercise_text_search.dart';

sealed class VoiceIntent {
  const VoiceIntent();
}

class VoiceAskDay extends VoiceIntent {
  const VoiceAskDay();
}

class VoiceAskWorkout extends VoiceIntent {
  const VoiceAskWorkout();
}

class VoiceAskRecord extends VoiceIntent {
  const VoiceAskRecord(this.query);
  final String query;
}

class VoiceAddExercise extends VoiceIntent {
  const VoiceAddExercise(this.query);
  final String query;
}

class VoiceAddSets extends VoiceIntent {
  const VoiceAddSets({this.count = 1});
  final int count;
}

class VoiceSetRest extends VoiceIntent {
  const VoiceSetRest(this.seconds);
  final int seconds;
}

class VoiceLogSet extends VoiceIntent {
  const VoiceLogSet({
    required this.weight,
    required this.reps,
    this.unit,
  });

  final double weight;
  final int reps;

  /// `kg` o `lb` si lo dijo. `null` usa la unidad del perfil.
  final String? unit;
}

class VoiceRemoveLastSet extends VoiceIntent {
  const VoiceRemoveLastSet({this.count = 1});
  final int count;
}

class VoiceConfirmYes extends VoiceIntent {
  const VoiceConfirmYes();
}

class VoiceConfirmNo extends VoiceIntent {
  const VoiceConfirmNo();
}

class VoiceUnknown extends VoiceIntent {
  const VoiceUnknown();
}

/// Durante un entrenamiento, la frase pide sumar un ejercicio y no armar una rutina.
bool voiceWantsExerciseAdded(String raw) {
  final text = ExerciseTextSearch.normalize(raw);
  if (text.contains('rutina') || text.contains('routine')) return false;
  final intent = parseVoiceCommand(raw, confirming: false);
  if (intent is VoiceLogSet ||
      intent is VoiceAddSets ||
      intent is VoiceRemoveLastSet ||
      intent is VoiceConfirmYes ||
      intent is VoiceConfirmNo) {
    return false;
  }
  if (intent is VoiceAddExercise) return true;
  final add = RegExp(
    r'\b(agrega|agregar|anade|anadir|add|include|pon|poner|mete|meter|suma|sumar)\b',
  ).hasMatch(text);
  return add || text.contains('ejercicio') || text.contains('exercise');
}

/// Pide armar una rutina nueva. «Al entrenamiento» no cuenta: es el entreno abierto.
bool voiceAsksForNewRoutine(String raw) {
  final text = ExerciseTextSearch.normalize(raw);
  if (RegExp(r'\b(rutina|rutinas|routine|routines)\b').hasMatch(text)) {
    return true;
  }
  if (voiceWantsExerciseAdded(raw)) return false;
  if (RegExp(r'\b(dia de|toca|recomiend|recomend|sugier)\b').hasMatch(text)) {
    return true;
  }
  final creates = RegExp(
    r'\b(crea|crear|haz|hazme|genera|generar|arma|armar|disena|create|make|build|design)\b',
  ).hasMatch(text);
  final plan = RegExp(r'\b(entrenamiento|workout|programa|plan)\b').hasMatch(text);
  return creates && plan;
}

/// Lo que queda de la frase para buscar el ejercicio.
String voiceExerciseQuery(String raw) {
  final intent = parseVoiceCommand(raw, confirming: false);
  var text = intent is VoiceAddExercise
      ? intent.query
      : ExerciseTextSearch.normalize(raw);
  text = text.replaceAll(
    RegExp(
      r'\b(agrega|agregar|anade|anadir|add|include|pon|poner|mete|meter|suma|sumar|un|una|el|la|los|las|ejercicio|exercise|para|for|de|del|con|with|al|en|este|esta|durante|entrenamiento|workout|activo)\b',
    ),
    ' ',
  );
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Una acción se ejecuta en la app. El resto es una consulta para el Coach.
bool voiceCommandIsAction(VoiceIntent intent) {
  return intent is VoiceAddExercise ||
      intent is VoiceAddSets ||
      intent is VoiceLogSet ||
      intent is VoiceSetRest ||
      intent is VoiceRemoveLastSet;
}

/// Interpreta lo que el usuario dice después de «Hey Forgen».
VoiceIntent parseVoiceCommand(String raw, {required bool confirming}) {
  final text = ExerciseTextSearch.normalize(raw);
  if (text.isEmpty) return const VoiceUnknown();

  if (confirming) {
    if (_isYes(text)) return const VoiceConfirmYes();
    if (_isNo(text)) return const VoiceConfirmNo();
    return const VoiceUnknown();
  }

  if (_isNo(text) && text.split(' ').length == 1) return const VoiceConfirmNo();

  final sets = _parseSetAdjustment(text);
  if (sets != null) return sets;

  final rest = _parseRest(text);
  if (rest != null) return rest;

  final added = _parseAdd(text);
  if (added != null) return added;

  if (_isRemove(text)) return const VoiceRemoveLastSet();

  final logged = _parseLog(text);
  if (logged != null) return logged;

  if (_containsAny(text, ['record', 'mi mejor', 'my pr', 'personal record'])) {
    return VoiceAskRecord(_recordQuery(text));
  }

  if (_containsAny(text, [
    'macros',
    'proteina',
    'protein',
    'caloria',
    'calorie',
    'como voy',
    'how am i',
    'mi dia',
    'my day',
    'comida',
  ])) {
    return const VoiceAskDay();
  }

  if (_containsAny(text, [
    'entrenamiento',
    'entreno',
    'workout',
    'ejercicio actual',
    'current exercise',
    'como va',
  ])) {
    return const VoiceAskWorkout();
  }

  return const VoiceUnknown();
}

bool _isYes(String text) {
  const words = {
    'si',
    'yes',
    'yeah',
    'yep',
    'dale',
    'ok',
    'okay',
    'confirmo',
    'confirm',
    'listo',
    'agrega',
    'anotalo',
    'hazlo',
  };
  final tokens = text.split(' ');
  return tokens.isNotEmpty && words.contains(tokens.first);
}

bool _isNo(String text) {
  const words = {'no', 'nope', 'cancela', 'cancel', 'cancelar'};
  final tokens = text.split(' ');
  return tokens.isNotEmpty && words.contains(tokens.first);
}

VoiceIntent? _parseSetAdjustment(String text) {
  if (!_isOnlySetWords(text)) return null;
  final count = _setCount(text);
  final remove = RegExp(
    r'\b(quita|quitar|borra|borrar|elimina|eliminar|remove|delete)\b',
  ).hasMatch(text);
  final add = RegExp(
    r'\b(agrega|agregar|anade|anadir|suma|sumar|pon|poner|mete|meter|add|include)\b',
  ).hasMatch(text);
  if (remove && !add) return VoiceRemoveLastSet(count: count);
  if (add || RegExp(r'\b(otra|another|mas|more)\b').hasMatch(text)) {
    return VoiceAddSets(count: count);
  }
  return null;
}

bool _isOnlySetWords(String text) {
  final rest = text
      .replaceAll(
        RegExp(
          r'\b(agrega|agregar|anade|anadir|suma|sumar|pon|poner|mete|meter|add|include|quita|quitar|borra|borrar|elimina|eliminar|remove|delete|una|un|dos|tres|cuatro|cinco|seis|siete|ocho|one|two|three|four|five|six|seven|eight|la|el|the|a|ultima|last|mas|more|otra|another|\d+)\b',
        ),
        ' ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return rest == 'serie' || rest == 'series' || rest == 'set' || rest == 'sets';
}

int _setCount(String text) {
  final digit = RegExp(r'\b(\d+)\b').firstMatch(text);
  if (digit != null) {
    final parsed = int.tryParse(digit.group(1)!);
    if (parsed != null && parsed >= 1 && parsed <= 8) return parsed;
  }
  const named = {
    'dos': 2,
    'two': 2,
    'tres': 3,
    'three': 3,
    'cuatro': 4,
    'four': 4,
    'cinco': 5,
    'five': 5,
    'seis': 6,
    'six': 6,
    'siete': 7,
    'seven': 7,
    'ocho': 8,
    'eight': 8,
  };
  for (final entry in named.entries) {
    if (RegExp('\\b${entry.key}\\b').hasMatch(text)) return entry.value;
  }
  return 1;
}

VoiceAddExercise? _parseAdd(String text) {
  final match = RegExp(
    r'^(agrega|agregar|anade|anadir|mete|meter|pon|poner|suma|sumar|incluye|incluir|add|include)\b\s*(.*)$',
  ).firstMatch(text);
  if (match == null) return null;
  var query = match.group(2) ?? '';
  final filler = RegExp(
    r'^(un|una|el|la|ejercicio|exercise|para|for|de|del)\b\s*',
  );
  while (filler.hasMatch(query)) {
    query = query.replaceFirst(filler, '');
  }
  query = query.trim();
  if (query.isEmpty) return null;
  return VoiceAddExercise(query);
}

bool _isRemove(String text) {
  final verb = RegExp(r'\b(quita|quitar|borra|borrar|elimina|eliminar|remove|delete)\b')
      .hasMatch(text);
  final target = RegExp(r'\b(serie|set|ultima|last)\b').hasMatch(text);
  return verb && target;
}

VoiceSetRest? _parseRest(String text) {
  if (!RegExp(r'\b(descanso|rest|reposo)\b').hasMatch(text)) return null;
  final minutes = RegExp(
    r'(\d+)\s*(minutos|minuto|min|minutes|minute)\b',
  ).firstMatch(text);
  if (minutes != null) {
    final count = int.tryParse(minutes.group(1)!);
    if (count != null && count >= 1 && count <= 10) {
      return VoiceSetRest(count * 60);
    }
  }
  final seconds = RegExp(r'(\d+)').firstMatch(text);
  if (seconds == null) return null;
  final count = int.tryParse(seconds.group(1)!);
  if (count == null || count < 10 || count > 600) return null;
  return VoiceSetRest(count);
}

VoiceLogSet? _parseLog(String text) {
  final weightFirst = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(kilos|kilo|kg|libras|libra|lb|lbs)?\s*(?:por|x|de|for|y|and|con|with)?\s*(\d+)\s*(?:reps|rep|repeticiones|repeticion)?',
  ).firstMatch(text);
  if (weightFirst != null) {
    final parsed = _logFrom(weightFirst.group(1), weightFirst.group(3), weightFirst.group(2), text);
    if (parsed != null) return parsed;
  }

  final repsFirst = RegExp(
    r'(\d+)\s*(?:reps|rep|repeticiones|repeticion)\s*(?:con|with|a|de|y|and|por|x)?\s*(\d+(?:[.,]\d+)?)\s*(kilos|kilo|kg|libras|libra|lb|lbs)?',
  ).firstMatch(text);
  if (repsFirst == null) return null;
  return _logFrom(repsFirst.group(2), repsFirst.group(1), repsFirst.group(3), text);
}

VoiceLogSet? _logFrom(String? weightText, String? repsText, String? unitWord, String text) {
  final hasBridge = RegExp(
    r'\b(por|x|y|and|con|with|reps|rep|repeticiones|repeticion|kilo|kg|libra|lb)\b',
  ).hasMatch(text);
  final onlyNumbers = RegExp(r'^\d+(?:[.,]\d+)? \d+$').hasMatch(text.trim());
  if (!hasBridge && !onlyNumbers && unitWord == null) return null;

  final weight = double.tryParse((weightText ?? '').replaceAll(',', '.'));
  final reps = int.tryParse(repsText ?? '');
  if (weight == null || reps == null || weight <= 0 || reps <= 0 || reps > 100) {
    return null;
  }

  String? unit;
  if (unitWord == 'kilos' || unitWord == 'kilo' || unitWord == 'kg') {
    unit = 'kg';
  } else if (unitWord == 'libras' ||
      unitWord == 'libra' ||
      unitWord == 'lb' ||
      unitWord == 'lbs') {
    unit = 'lb';
  }
  return VoiceLogSet(weight: weight, reps: reps, unit: unit);
}

String _recordQuery(String text) {
  var query = text;
  for (final word in [
    'cual es',
    'cuanto es',
    'what is',
    'whats',
    'mi record',
    'my record',
    'personal record',
    'mi mejor',
    'record',
    'de',
    'en',
    'the',
    'my',
    'pr',
  ]) {
    query = query.replaceAll(RegExp('\\b$word\\b'), ' ');
  }
  return query.replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _containsAny(String text, List<String> needles) {
  for (final needle in needles) {
    if (text.contains(needle)) return true;
  }
  return false;
}
