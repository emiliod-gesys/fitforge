/// Frases que Forgen dice. «Dime» y «Tell me» van grabadas; el resto se lee.
abstract final class VoiceLines {
  static bool english(String languageCode) =>
      languageCode.toLowerCase().startsWith('en');

  static String ack(bool english) => english ? 'Tell me' : 'Dime';

  static String thinking(bool english) => english ? 'One moment' : 'Un momento';

  static String didNotCatch(bool english) => english
      ? "I didn't catch that. You can ask for your day, a record, or to add an exercise."
      : 'No entendí. Puedes pedir tu día, un récord o agregar un ejercicio.';

  static String sayYesOrNo(bool english) =>
      english ? 'Say yes or no.' : 'Di sí o no.';

  static String noWorkout(bool english) => english
      ? 'There is no workout open.'
      : 'No hay un entrenamiento abierto.';

  static String noExerciseMatch(bool english) => english
      ? "I couldn't find that exercise."
      : 'No encontré ese ejercicio.';

  static String confirmAdd(bool english, String name) => english
      ? 'Add $name?'
      : '¿Agrego $name?';

  static String added(bool english, String name) =>
      english ? 'Added $name.' : 'Listo, agregué $name.';

  static String pickExercise(bool english) => english
      ? 'Pick the exercise.'
      : 'Elige el ejercicio.';

  static String routineReady(bool english, String name) => english
      ? 'I drafted $name. Review it and save it when you approve it.'
      : 'Armé $name. Revísala y guárdala cuando la apruebes.';

  static String couldNotAdd(bool english) => english
      ? "I couldn't add it."
      : 'No pude agregarlo.';

  static String confirmLog(
    bool english, {
    required String weight,
    required int reps,
    required String exercise,
  }) =>
      english
          ? 'Log $weight for $reps on $exercise?'
          : '¿Anoto $weight por $reps en $exercise?';

  static String logged(bool english) => english ? 'Logged.' : 'Anotado.';

  static String loggedSet(
    bool english, {
    required String weight,
    required int reps,
    required String exercise,
  }) =>
      english
          ? 'Logged $weight for $reps on $exercise.'
          : 'Registré $weight por $reps en $exercise.';

  static String restUpdated(bool english, int seconds) {
    if (seconds >= 60 && seconds % 60 == 0) {
      final minutes = seconds ~/ 60;
      return english
          ? 'Rest is $minutes minutes.'
          : 'El descanso quedó en $minutes minutos.';
    }
    return english
        ? 'Rest is $seconds seconds.'
        : 'El descanso quedó en $seconds segundos.';
  }

  static String couldNotLog(bool english) =>
      english ? "I couldn't log that set." : 'No pude anotar la serie.';

  static String noSet(bool english) => english
      ? 'There is no exercise to log.'
      : 'No hay un ejercicio para anotar.';

  static String confirmDelete(bool english, String exercise) => english
      ? 'Remove the last set of $exercise?'
      : '¿Quito la última serie de $exercise?';

  static String deleted(bool english) => english ? 'Removed.' : 'La quité.';

  static String needOpenExercise(bool english) => english
      ? 'Open the exercise to log or change sets.'
      : 'Abre el ejercicio para registrar o cambiar las series.';

  static String setsAdded(bool english, int count, String exercise) {
    if (english) {
      return count == 1
          ? 'Added a set on $exercise.'
          : 'Added $count sets on $exercise.';
    }
    return count == 1
        ? 'Agregué una serie en $exercise.'
        : 'Agregué $count series en $exercise.';
  }

  static String setsRemoved(bool english, int count, String exercise) {
    if (english) {
      return count == 1
          ? 'Removed a set from $exercise.'
          : 'Removed $count sets from $exercise.';
    }
    return count == 1
        ? 'Quité una serie de $exercise.'
        : 'Quité $count series de $exercise.';
  }

  static String noSetToRemove(bool english) => english
      ? 'That exercise has no sets.'
      : 'Ese ejercicio no tiene series.';

  static String couldNotDelete(bool english) =>
      english ? "I couldn't remove it." : 'No pude quitarla.';

  static String cancelled(bool english) => english ? 'Okay.' : 'De acuerdo.';

  static String day({
    required bool english,
    required int eaten,
    required int protein,
    required int remaining,
  }) {
    if (english) {
      return "Today you've eaten $eaten calories and $protein grams of protein. $remaining calories left.";
    }
    return 'Hoy llevas $eaten calorías y $protein gramos de proteína. Te quedan $remaining calorías.';
  }

  static String dayUnavailable(bool english) => english
      ? "I can't see today's food yet."
      : 'Todavía no puedo ver la comida de hoy.';

  static String workout({
    required bool english,
    required String exercise,
    required int done,
    required int total,
  }) {
    if (english) {
      return "You're on $exercise. $done of $total sets done.";
    }
    return 'Vas en $exercise. Llevas $done de $total series.';
  }

  static String record({
    required bool english,
    required String exercise,
    required String weight,
    required int reps,
  }) {
    if (english) return 'Your record on $exercise is $weight for $reps.';
    return 'Tu récord en $exercise es $weight por $reps.';
  }

  static String noRecord(bool english) =>
      english ? "I don't have that record." : 'No tengo ese récord.';

  static String micDenied(bool english) => english
      ? 'FORGEN needs the microphone for Hey Forgen.'
      : 'FORGEN necesita el micrófono para Hey Forgen.';

  static String micUnavailable(bool english) => english
      ? "This phone can't hear Hey Forgen."
      : 'Este teléfono no puede escuchar Hey Forgen.';
}
