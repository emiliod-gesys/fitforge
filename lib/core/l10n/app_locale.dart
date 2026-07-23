import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Idiomas soportados en la app y mapeo a wger.de (language id).
abstract final class AppLocale {
  static const defaultCode = 'es';

  static const supportedCodes = ['es', 'en'];

  static Locale toLocale(String? code) {
    final normalized = code ?? defaultCode;
    return Locale(supportedCodes.contains(normalized) ? normalized : defaultCode);
  }

  /// Cadenas localizadas para el idioma preferido del usuario (es / en).
  static AppLocalizations localizations(String? code) {
    return lookupAppLocalizations(toLocale(code));
  }

  /// wger API: 2 = English, 4 = Spanish
  static int wgerLanguageId(String? code) {
    return code == 'en' ? 2 : 4;
  }

  static int wgerFallbackLanguageId(String? code) {
    return code == 'en' ? 4 : 2;
  }
}
