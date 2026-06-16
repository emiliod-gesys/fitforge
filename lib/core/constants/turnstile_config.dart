class TurnstileConfig {
  static const siteKey = String.fromEnvironment(
    'TURNSTILE_SITE_KEY',
    defaultValue: '',
  );

  /// Debe coincidir con un dominio permitido en el widget de Cloudflare Turnstile.
  static const baseUrl = String.fromEnvironment(
    'TURNSTILE_BASE_URL',
    defaultValue: 'http://localhost/',
  );

  static bool get isEnabled => siteKey.isNotEmpty;
}
