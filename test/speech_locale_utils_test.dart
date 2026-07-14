import 'package:fitforge/core/utils/speech_locale_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart';

LocaleName _locale(String id) => LocaleName(id, id);

void main() {
  group('SpeechLocaleUtils', () {
    test('prefers es_MX when es_ES is missing', () {
      final id = SpeechLocaleUtils.resolveLocaleId(
        languageCode: 'es',
        available: [_locale('en_US'), _locale('es_MX')],
      );
      expect(id, 'es_MX');
    });

    test('does not fall back to English for Spanish', () {
      final id = SpeechLocaleUtils.resolveLocaleId(
        languageCode: 'es',
        available: [_locale('en_US')],
      );
      expect(id, isNull);
    });

    test('matches es-419 style locale ids', () {
      final id = SpeechLocaleUtils.resolveLocaleId(
        languageCode: 'es',
        available: [_locale('en_US'), _locale('es-419')],
      );
      expect(id, 'es-419');
    });
  });
}
