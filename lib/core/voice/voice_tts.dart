/// Elige una voz masculina del motor de lectura. Nunca devuelve una femenina.
abstract final class VoiceTts {
  static List<Map<String, String>> maleVoices(
    Iterable<dynamic> voices, {
    required bool english,
  }) {
    final ranked = <({Map<String, String> voice, int score})>[];
    for (final item in voices) {
      if (item is! Map) continue;
      final voice = <String, String>{
        for (final entry in item.entries) '${entry.key}': '${entry.value}',
      };
      final score = scoreVoice(voice, english: english);
      if (score <= 0) continue;
      ranked.add((voice: voice, score: score));
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return [for (final item in ranked) item.voice];
  }

  static int scoreVoice(Map<String, String> voice, {required bool english}) {
    final locale = (voice['locale'] ?? '').toLowerCase().replaceAll('_', '-');
    if (!locale.startsWith(english ? 'en' : 'es')) return 0;
    final name = (voice['name'] ?? '').toLowerCase();
    final gender = (voice['gender'] ?? voice['networkGender'] ?? '').toLowerCase();
    final features = (voice['features'] ?? '').toLowerCase();
    if (_isFemale(name: name, gender: gender, features: features)) return 0;
    if (!_isMale(name: name, gender: gender, features: features)) return 0;

    var score = 50;
    if (name.contains('jorge') || name.contains('guy')) score += 40;
    if (gender == 'male' || gender == 'm' || _hasWord(features, 'male')) score += 10;
    if (!english && locale.startsWith('es-mx')) score += 20;
    if (!english && locale.startsWith('es-us')) score += 12;
    if (!english && locale.startsWith('es-es')) score += 8;
    if (english && locale.startsWith('en-us')) score += 12;
    if (voice['network_required'] == '0') score += 5;
    return score;
  }

  static bool _isFemale({
    required String name,
    required String gender,
    required String features,
  }) {
    if (gender == 'female' || gender == 'f' || gender.contains('female')) return true;
    if (_hasWord(features, 'female')) return true;
    const hints = [
      'eef',
      'esf',
      'sfb',
      'sfg',
      'iol',
      'iog',
      'tpf',
      'eea',
      'sfc',
      'ioc',
      'helena',
      'sabina',
    ];
    return hints.any(name.contains);
  }

  static bool _isMale({
    required String name,
    required String gender,
    required String features,
  }) {
    if (gender == 'male' || gender == 'm') return true;
    if (_hasWord(features, 'male')) return true;
    const hints = [
      'jorge',
      'guy',
      'raul',
      'enrique',
      'alvaro',
      'david',
      'eed',
      'esc',
      'esd',
      'iom',
      'tpd',
      'iob',
      'rjs',
    ];
    return hints.any(name.contains);
  }

  static bool _hasWord(String text, String word) {
    return RegExp('\\b$word\\b').hasMatch(text);
  }
}
