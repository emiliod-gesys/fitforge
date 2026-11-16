import '../utils/exercise_text_search.dart';

/// Detecta «Hey Forgen» aunque el reconocedor cambie la pronunciación.
abstract final class VoiceWakePhrase {
  static const _hey = {'hey', 'ey', 'ei', 'oye', 'ay'};

  /// Si la frase empieza con la palabra de activación, devuelve lo que viene
  /// después. Cadena vacía significa que solo dijo la palabra. `null` si no
  /// es una activación.
  static String? strip(String raw) {
    final text = ExerciseTextSearch.normalize(raw);
    if (text.isEmpty) return null;
    final tokens = text.split(' ');
    if (tokens.isEmpty) return null;

    var stemAt = -1;
    if (_isForgen(tokens.first)) {
      stemAt = 0;
    } else if (tokens.length >= 2 &&
        _hey.contains(tokens.first) &&
        _isForgen(tokens[1])) {
      stemAt = 1;
    }
    if (stemAt < 0) return null;
    return tokens.sublist(stemAt + 1).join(' ');
  }

  static bool _isForgen(String token) {
    const exact = {
      'forgen',
      'forjen',
      'foryen',
      'forguen',
      'forjan',
      'foryan',
      'forhen',
      'forgin',
      'forgyn',
      'forgenn',
      'fourgen',
      'forjenn',
      'forgue',
      'forghen',
    };
    if (exact.contains(token)) return true;
    if (token.length < 6 || token.length > 8) return false;
    final head = token.startsWith('forg') ||
        token.startsWith('forj') ||
        token.startsWith('fory');
    final tail =
        token.endsWith('en') || token.endsWith('an') || token.endsWith('in');
    return head && tail;
  }
}
