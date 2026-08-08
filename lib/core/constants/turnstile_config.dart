class TurnstileConfig {
  static const siteKey = String.fromEnvironment(
    'TURNSTILE_SITE_KEY',
    defaultValue: '',
  );

  /// Origen del WebView; debe coincidir con un hostname permitido en Cloudflare.
  ///
  /// En APK Android real, `http://localhost/` suele provocar error 110200
  /// ("Domain not allowed") y el widget queda reintentando. Usa un dominio
  /// real (p. ej. `https://fitforge.app/`) y añádelo en Turnstile → Hostnames.
  static const baseUrl = String.fromEnvironment(
    'TURNSTILE_BASE_URL',
    defaultValue: 'http://localhost/',
  );

  static bool get isEnabled => siteKey.isNotEmpty;
}
