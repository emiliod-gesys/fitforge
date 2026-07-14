import 'package:speech_to_text/speech_to_text.dart';

/// Elige el locale de dictado del dispositivo según el idioma de la app.
abstract final class SpeechLocaleUtils {
  static const _englishPreference = ['en_US', 'en_GB', 'en_AU', 'en_CA', 'en'];
  static const _spanishPreference = [
    'es_MX',
    'es_ES',
    'es_US',
    'es_419',
    'es_GT',
    'es',
  ];

  static String? resolveLocaleId({
    required String languageCode,
    required List<LocaleName> available,
  }) {
    if (available.isEmpty) return null;

    final normalized = languageCode.toLowerCase();
    final preferred = normalized == 'en' ? _englishPreference : _spanishPreference;

    for (final id in preferred) {
      if (available.any((locale) => locale.localeId == id)) return id;
    }

    for (final locale in available) {
      final id = locale.localeId.toLowerCase();
      if (id.startsWith('$normalized-') ||
          id.startsWith('${normalized}_') ||
          id == normalized) {
        return locale.localeId;
      }
    }

    return null;
  }
}
