import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/turnstile_config.dart';

/// El widget normal de Turnstile mide 300 px. En la pantalla exterior de un
/// plegable (Z Fold) el formulario queda por debajo de eso: el WebView se
/// recorta y, al abrir o cerrar el teléfono, se redimensiona en bucle.
TurnstileSize turnstileSizeForWidth({
  required double width,
  required TurnstileSize? current,
}) {
  if (!width.isFinite || width <= 0) {
    return current ?? TurnstileSize.normal;
  }
  if (current == null) {
    return width < 320 ? TurnstileSize.compact : TurnstileSize.normal;
  }
  if (current == TurnstileSize.compact && width >= 340) {
    return TurnstileSize.normal;
  }
  if (current == TurnstileSize.normal && width < 280) {
    return TurnstileSize.compact;
  }
  return current;
}

class TurnstileCaptcha extends StatefulWidget {
  final ValueChanged<String?> onTokenChanged;

  const TurnstileCaptcha({super.key, required this.onTokenChanged});

  @override
  State<TurnstileCaptcha> createState() => TurnstileCaptchaState();
}

class TurnstileCaptchaState extends State<TurnstileCaptcha> {
  Key _widgetKey = UniqueKey();
  DateTime? _lastResetAt;
  TurnstileSize? _size;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolved = turnstileSizeForWidth(
          width: constraints.maxWidth,
          current: _size,
        );
        if (_size != null && _size != resolved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _size != resolved) return;
            widget.onTokenChanged(null);
          });
        }
        _size = resolved;

        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: resolved.width,
            height: resolved.height,
            child: CloudflareTurnstile(
              key: ValueKey((_widgetKey, resolved)),
              siteKey: TurnstileConfig.siteKey,
              baseUrl: TurnstileConfig.baseUrl,
              options: TurnstileOptions(
                size: resolved,
                theme: TurnstileTheme.dark,
                // Evita reintentos infinitos del JS de Turnstile en errores retryables
                // (p. ej. 110200 "Domain not allowed" en WebView Android).
                retryAutomatically: false,
                refreshExpired: TurnstileRefreshExpired.manual,
                refreshTimeout: TurnstileRefreshTimeout.manual,
                // En Samsung plegable, animar el tamaño del WebView lo deja parpadeando.
                animationDuration: Duration.zero,
              ),
              onTokenReceived: widget.onTokenChanged,
              onError: _onError,
              onTokenExpired: () => widget.onTokenChanged(null),
            ),
          ),
        );
      },
    );
  }
}
