class TurnstileConfig {
  static const siteKey = String.fromEnvironment(
    'TURNSTILE_SITE_KEY',
    defaultValue: '',
  );

  /// Origen del WebView; debe coincidir con un hostname permitido en Cloudflare.
  ///
  /// En iOS/Android reales, `http://localhost/` provoca error 110200
  /// ("Domain not allowed") y el botón de login queda deshabilitado. Usa un
  /// dominio real y añádelo en Turnstile → Hostnames.
  static const baseUrl = String.fromEnvironment(
    'TURNSTILE_BASE_URL',
    defaultValue: 'https://www.forgen.app/',
  );

  static bool get isEnabled => siteKey.isNotEmpty;
}
