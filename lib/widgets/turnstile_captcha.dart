import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/turnstile_config.dart';

class TurnstileCaptcha extends StatefulWidget {
  final ValueChanged<String?> onTokenChanged;

  const TurnstileCaptcha({super.key, required this.onTokenChanged});

  @override
  State<TurnstileCaptcha> createState() => TurnstileCaptchaState();
}

class TurnstileCaptchaState extends State<TurnstileCaptcha> {
  Key _widgetKey = UniqueKey();
  DateTime? _lastResetAt;

  void reset() {
    final now = DateTime.now();
    if (_lastResetAt != null &&
        now.difference(_lastResetAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastResetAt = now;
    widget.onTokenChanged(null);
    setState(() => _widgetKey = UniqueKey());
  }

  void _onError(TurnstileException error) {
    if (kDebugMode) {
      debugPrint(
        'Turnstile ${error.code}: ${error.message} '
        '(retryable=${error.retryable})',
      );
    }
    widget.onTokenChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    if (!TurnstileConfig.isEnabled) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 70,
      child: CloudflareTurnstile(
        key: _widgetKey,
        siteKey: TurnstileConfig.siteKey,
        baseUrl: TurnstileConfig.baseUrl,
        options: TurnstileOptions(
          size: TurnstileSize.normal,
          theme: TurnstileTheme.dark,
          // Evita reintentos infinitos del JS de Turnstile en errores retryables
          // (p. ej. 110200 "Domain not allowed" en WebView Android).
          retryAutomatically: false,
          refreshExpired: TurnstileRefreshExpired.manual,
          refreshTimeout: TurnstileRefreshTimeout.manual,
        ),
        onTokenReceived: widget.onTokenChanged,
        onError: _onError,
        onTokenExpired: () => widget.onTokenChanged(null),
      ),
    );
  }
}
