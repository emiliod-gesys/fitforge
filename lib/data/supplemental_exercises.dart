import '../models/exercise.dart';

/// Ejercicios habituales en gimnasio que a veces faltan o tienen nombre poco claro en wger.
abstract final class SupplementalExercises {
  static const _id = -1000;

  static List<Exercise> all({String locale = 'es'}) =>
      locale == 'en' ? _english() : _spanish();

  static List<Exercise> _spanish() => [
        _e('Press de banca con barra', 'Pecho', ['Pecho', 'Tríceps'], id: _id - 1,
            desc: 'Acostado en banco plano, baja la barra al pecho y empuja hacia arriba con control.'),
        _e('Press inclinado con mancuernas', 'Pecho', ['Pecho'], id: _id - 2,
            desc: 'En banco inclinado (~30–45°), empuja las mancuernas desde la altura del pecho superior.'),
        _e('Press declinado con barra', 'Pecho', ['Pecho'], id: _id - 3,
            desc: 'En banco declinado, baja la barra al pecho inferior y extiende los brazos.'),
        _e('Press de banca con mancuernas', 'Pecho', ['Pecho'], id: _id - 4),
        _e('Aperturas con mancuernas (peck deck)', 'Pecho', ['Pecho'], id: _id - 5),
        _e('Press militar con barra', 'Hombros', ['Hombros', 'Tríceps'], id: _id - 6),
        _e('Press Arnold', 'Hombros', ['Hombros'], id: _id - 7),
        _e('Elevaciones laterales con mancuernas', 'Hombros', ['Hombros'], id: _id - 8),
        _e('Remo con barra', 'Espalda', ['Espalda'], id: _id - 9,
            desc: 'Inclinado hacia adelante, tira la barra hacia el abdomen manteniendo la espalda neutra.'),
        _e('Remo en polea baja', 'Espalda', ['Espalda'], id: _id - 10),
        _e('Jalón al pecho (polea)', 'Espalda', ['Espalda'], id: _id - 11),
        _e('Dominadas', 'Espalda', ['Espalda', 'Bíceps'], id: _id - 12),
        _e('Peso muerto convencional', 'Espalda', ['Espalda', 'Piernas', 'Glúteos'], id: _id - 13),
        _e('Peso muerto rumano', 'Piernas', ['Piernas', 'Glúteos'], id: _id - 14),
        _e('Sentadilla con barra (back squat)', 'Piernas', ['Piernas', 'Glúteos'], id: _id - 15),
        _e('Sentadilla frontal', 'Piernas', ['Piernas'], id: _id - 16),
        _e('Prensa de piernas', 'Piernas', ['Piernas'], id: _id - 17),
        _e('Zancadas caminando', 'Piernas', ['Piernas', 'Glúteos'], id: _id - 18),
        _e('Curl femoral sentado', 'Piernas', ['Piernas'], id: _id - 19),
        _e('Extensión de cuádriceps', 'Piernas', ['Piernas'], id: _id - 20),
        _e('Hip thrust con barra', 'Glúteos', ['Glúteos'], id: _id - 21),
        _e('Curl con barra', 'Brazos', ['Bíceps'], id: _id - 22),
        _e('Curl martillo', 'Brazos', ['Bíceps'], id: _id - 23),
        _e('Extensiones de tríceps en polea', 'Brazos', ['Tríceps'], id: _id - 24),
        _e('Fondos en paralelas', 'Brazos', ['Tríceps', 'Pecho'], id: _id - 25),
        _e('Crunch en polea', 'Abdominales', ['Abdominales'], id: _id - 26),
        _e('Plancha abdominal', 'Abdominales', ['Abdominales'], id: _id - 27),
      ];

  static List<Exercise> _english() => [
        _e('Barbell bench press', 'Chest', ['Chest', 'Triceps'], id: _id - 1,
            desc: 'Lie on a flat bench, lower the bar to your chest and press up with control.'),
        _e('Incline dumbbell press', 'Chest', ['Chest'], id: _id - 2,
            desc: 'On an incline bench (~30–45°), press dumbbells from upper chest height.'),
        _e('Decline barbell press', 'Chest', ['Chest'], id: _id - 3,
            desc: 'On a decline bench, lower the bar to the lower chest and extend arms.'),
        _e('Dumbbell bench press', 'Chest', ['Chest'], id: _id - 4),
        _e('Dumbbell flyes (pec deck)', 'Chest', ['Chest'], id: _id - 5),
        _e('Barbell overhead press', 'Shoulders', ['Shoulders', 'Triceps'], id: _id - 6),
        _e('Arnold press', 'Shoulders', ['Shoulders'], id: _id - 7),
        _e('Dumbbell lateral raises', 'Shoulders', ['Shoulders'], id: _id - 8),
        _e('Barbell row', 'Back', ['Back'], id: _id - 9,
            desc: 'Hinge forward, pull the bar to your abdomen keeping a neutral spine.'),
        _e('Seated cable row', 'Back', ['Back'], id: _id - 10),
        _e('Lat pulldown', 'Back', ['Back'], id: _id - 11),
        _e('Pull-ups', 'Back', ['Back', 'Biceps'], id: _id - 12),
        _e('Conventional deadlift', 'Back', ['Back', 'Legs', 'Glutes'], id: _id - 13),
        _e('Romanian deadlift', 'Legs', ['Legs', 'Glutes'], id: _id - 14),
        _e('Barbell back squat', 'Legs', ['Legs', 'Glutes'], id: _id - 15),
        _e('Front squat', 'Legs', ['Legs'], id: _id - 16),
        _e('Leg press', 'Legs', ['Legs'], id: _id - 17),
        _e('Walking lunges', 'Legs', ['Legs', 'Glutes'], id: _id - 18),
        _e('Seated leg curl', 'Legs', ['Legs'], id: _id - 19),
        _e('Leg extension', 'Legs', ['Legs'], id: _id - 20),
        _e('Barbell hip thrust', 'Glutes', ['Glutes'], id: _id - 21),
        _e('Barbell curl', 'Arms', ['Biceps'], id: _id - 22),
        _e('Hammer curl', 'Arms', ['Biceps'], id: _id - 23),
        _e('Triceps pushdown', 'Arms', ['Triceps'], id: _id - 24),
        _e('Parallel bar dips', 'Arms', ['Triceps', 'Chest'], id: _id - 25),
        _e('Cable crunch', 'Abs', ['Abs'], id: _id - 26),
        _e('Plank', 'Abs', ['Abs'], id: _id - 27),
      ];

  static Exercise _e(
    String name,
    String category,
    List<String> muscles, {
    required int id,
    String desc = '',
  }) {
    return Exercise(
      wgerId: id,
      name: name,
      description: desc,
      category: category,
      muscles: muscles,
      isCustom: true,
    );
  }

  static List<Exercise> mergeWith(List<Exercise> fromWger, {String locale = 'es'}) {
    final merged = List<Exercise>.from(fromWger);
    final names = fromWger.map((e) => _normalize(e.name)).toSet();

    for (final extra in all(locale: locale)) {
      final key = _normalize(extra.name);
      final duplicate = names.any((n) => n == key || n.contains(key) || key.contains(n));
      if (!duplicate) {
        merged.add(extra);
        names.add(key);
      }
    }

    merged.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return merged;
  }

  static String _normalize(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll(RegExp(r'ñ'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
