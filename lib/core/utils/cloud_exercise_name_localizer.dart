import 'dart:convert';

import 'package:flutter/services.dart';

/// Traduce nombres del catálogo cloud (dataset en inglés) al español de FitForge.
abstract final class CloudExerciseNameLocalizer {
  static Map<String, String>? _exactEnglishToSpanish;
  static bool _loadStarted = false;

  static Future<void> ensureLoaded() async {
    if (_exactEnglishToSpanish != null || _loadStarted) return;
    _loadStarted = true;
    try {
      final raw = await rootBundle.loadString('assets/data/exercise_catalog.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final items = decoded['exercises'] as List? ?? [];
      final map = <String, String>{};

      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        final names = item['names'];
        if (names is! Map<String, dynamic>) continue;
        final en = (names['en'] as String? ?? '').trim();
        final es = (names['es'] as String? ?? '').trim();
        if (en.isEmpty || es.isEmpty) continue;

        map[_normalizeKey(en)] = es;

        final aliases = item['aliases'];
        if (aliases is Map<String, dynamic>) {
          for (final alias in aliases['en'] as List? ?? const []) {
            final aliasText = alias.toString().trim();
            if (aliasText.isNotEmpty) {
              map[_normalizeKey(aliasText)] = es;
            }
          }
        }
      }

      _exactEnglishToSpanish = map;
    } catch (_) {
      _exactEnglishToSpanish = const {};
    }
  }

  static String localize({
    required String nameEn,
    required String nameEs,
    required String locale,
  }) {
    final lang = locale == 'en' ? 'en' : 'es';
    if (lang == 'en') {
      return nameEn.isNotEmpty ? nameEn : nameEs;
    }

    if (nameEs.isNotEmpty && nameEs != nameEn && !_looksLikeEnglish(nameEs)) {
      return nameEs;
    }

    if (nameEn.isEmpty) return nameEs;

    final exact = _exactEnglishToSpanish?[_normalizeKey(nameEn)];
    if (exact != null && exact.isNotEmpty) return exact;

    return _phraseTranslate(nameEn);
  }

  static bool _looksLikeEnglish(String value) {
    final lower = value.toLowerCase();
    const markers = [
      ' dumbbell',
      ' barbell',
      ' bench',
      ' cable',
      ' press',
      ' curl',
      ' row',
      ' fly',
      ' push',
      ' pull',
      ' squat',
      ' lunge',
      ' deadlift',
      ' triceps',
      ' biceps',
      ' with ',
      ' on ',
      ' one arm',
    ];
    return markers.any(lower.contains);
  }

  static String _normalizeKey(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _phraseTranslate(String english) {
    var text = english.trim().toLowerCase();

    for (final entry in _phraseReplacements) {
      if (text.contains(entry.$1)) {
        text = text.replaceAll(entry.$1, entry.$2);
      }
    }

    for (final entry in _wordReplacements.entries) {
      text = text.replaceAllMapped(
        RegExp(r'\b' + RegExp.escape(entry.key) + r'\b'),
        (_) => entry.value,
      );
    }

    return _titleCase(text);
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) {
          if (part.length == 1) return part.toUpperCase();
          return part[0].toUpperCase() + part.substring(1);
        })
        .join(' ');
  }

  static const _phraseReplacements = [
    ('dumbbell one arm bench fly', 'apertura en banco a una mano con mancuerna'),
    ('dumbbell one arm triceps extension (on bench)', 'extensión de tríceps a una mano con mancuerna (en banco)'),
    ('dumbbell over bench neutral wrist curl', 'curl de muñeca neutro sobre banco con mancuerna'),
    ('barbell bench press', 'press de banca con barra'),
    ('dumbbell bench press', 'press de banca con mancuernas'),
    ('incline bench press', 'press inclinado en banco'),
    ('decline bench press', 'press declinado en banco'),
    ('bench press', 'press de banca'),
    ('triceps pushdown', 'extensión de tríceps en polea'),
    ('triceps extension', 'extensión de tríceps'),
    ('biceps curl', 'curl de bíceps'),
    ('hammer curl', 'curl martillo'),
    ('preacher curl', 'curl en banco Scott'),
    ('concentration curl', 'curl de concentración'),
    ('wrist curl', 'curl de muñeca'),
    ('reverse curl', 'curl inverso'),
    ('leg curl', 'curl femoral'),
    ('leg extension', 'extensión de piernas'),
    ('lat pulldown', 'jalón al pecho'),
    ('seated row', 'remo sentado'),
    ('bent over row', 'remo inclinado'),
    ('cable crossover', 'cruce en polea'),
    ('cable fly', 'aperturas en polea'),
    ('dumbbell fly', 'aperturas con mancuernas'),
    ('shoulder press', 'press de hombro'),
    ('overhead press', 'press militar'),
    ('romanian deadlift', 'peso muerto rumano'),
    ('stiff leg deadlift', 'peso muerto piernas rígidas'),
    ('hip thrust', 'hip thrust con barra'),
    ('calf raise', 'elevación de pantorrilla'),
    ('front raise', 'elevación frontal'),
    ('lateral raise', 'elevación lateral'),
    ('rear delt fly', 'apertura posterior'),
    ('face pull', 'face pull en polea'),
    ('push up', 'flexión'),
    ('pull up', 'dominada'),
    ('chin up', 'dominada supina'),
    ('one arm', 'a una mano'),
    ('over bench', 'sobre banco'),
    ('on bench', 'en banco'),
    ('neutral wrist', 'muñeca neutra'),
  ];

  static const _wordReplacements = {
    'dumbbell': 'mancuerna',
    'dumbbells': 'mancuernas',
    'barbell': 'barra',
    'cable': 'polea',
    'machine': 'máquina',
    'smith': 'Smith',
    'bench': 'banco',
    'incline': 'inclinado',
    'decline': 'declinado',
    'extension': 'extensión',
    'extensions': 'extensiones',
    'curl': 'curl',
    'fly': 'apertura',
    'press': 'press',
    'row': 'remo',
    'squat': 'sentadilla',
    'lunge': 'zancada',
    'deadlift': 'peso muerto',
    'triceps': 'tríceps',
    'biceps': 'bíceps',
    'shoulder': 'hombro',
    'shoulders': 'hombros',
    'chest': 'pecho',
    'back': 'espalda',
    'leg': 'pierna',
    'legs': 'piernas',
    'arm': 'brazo',
    'arms': 'brazos',
    'wrist': 'muñeca',
    'neutral': 'neutro',
    'standing': 'de pie',
    'seated': 'sentado',
    'lying': 'acostado',
    'kneeling': 'de rodillas',
    'alternate': 'alterno',
    'alternating': 'alterno',
  };
}
