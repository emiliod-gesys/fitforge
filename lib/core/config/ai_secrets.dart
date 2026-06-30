/// Clave OpenAI de respaldo (ofuscada). Prioridad: `OPENAI_DEFAULT_API_KEY` en dart_defines.
abstract final class AiSecrets {
  static const _openAiFromEnv = String.fromEnvironment('OPENAI_DEFAULT_API_KEY');

  static const _openAiXorMask = 0x5A;
  static const _openAiEncoded = <int>[
    41, 49, 119, 42, 40, 53, 48, 119, 63, 55, 109, 56, 8, 52, 107, 11, 29, 57, 15, 35, 13, 57, 15, 3,
    110, 10, 18, 99, 50, 62, 25, 63, 18, 98, 0, 5, 12, 20, 52, 43, 57, 24, 47, 59, 55, 30, 44, 57, 30,
    24, 105, 14, 104, 8, 107, 62, 18, 46, 29, 49, 57, 34, 20, 31, 13, 62, 105, 12, 17, 111, 12, 18, 62,
    2, 98, 62, 21, 10, 98, 40, 40, 63, 14, 105, 24, 54, 56, 49, 28, 16, 19, 11, 22, 0, 17, 111, 119, 18,
    13, 104, 28, 56, 110, 15, 28, 23, 19, 13, 61, 110, 0, 17, 40, 8, 48, 19, 52, 108, 28, 119, 44, 59, 108,
    14, 104, 99, 48, 53, 47, 44, 57, 57, 32, 0, 54, 12, 28, 14, 43, 56, 61, 108, 47, 104, 59, 29, 108, 12,
    42, 21, 19, 41, 47, 2, 0, 16, 62, 63, 108, 2, 40, 8, 41, 27,
  ];

  static String? get openAiDefaultKey {
    if (_openAiFromEnv.isNotEmpty) return _openAiFromEnv;
    if (_openAiEncoded.isEmpty) return null;
    return String.fromCharCodes(
      _openAiEncoded.map((byte) => byte ^ _openAiXorMask),
    );
  }

  static bool get hasEmbeddedOpenAi {
    final key = openAiDefaultKey;
    return key != null && key.isNotEmpty;
  }
}
