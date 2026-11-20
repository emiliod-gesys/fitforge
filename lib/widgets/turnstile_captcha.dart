import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/turnstile_config.dart';
import '../l10n/l10n_extensions.dart';
import 'turnstile_document_view.dart';

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
  bool _failed = false;

  void reset({bool force = false}) {
    final now = DateTime.now();
    if (!force &&
        _lastResetAt != null &&
        now.difference(_lastResetAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastResetAt = now;
    widget.onTokenChanged(null);
    setState(() {
      _failed = false;
      _widgetKey = UniqueKey();
    });
  }

  void _onToken(String? token) {
    if (token != null && token.isNotEmpty && _failed && mounted) {
      setState(() => _failed = false);
    }
    widget.onTokenChanged(token);
  }

  void _onError(TurnstileException error) {
    widget.onTokenChanged(null);
    if (!mounted) return;
    setState(() => _failed = true);
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

        final challengeKey = ValueKey((_widgetKey, resolved));
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: resolved.width,
            height: resolved.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: kIsWeb
                      ? CloudflareTurnstile(
                          key: challengeKey,
                          siteKey: TurnstileConfig.siteKey,
                          baseUrl: TurnstileConfig.baseUrl,
                          options: TurnstileOptions(
                            size: resolved,
                            theme: TurnstileTheme.dark,
                            retryAutomatically: false,
                            refreshExpired: TurnstileRefreshExpired.manual,
                            refreshTimeout: TurnstileRefreshTimeout.manual,
                            animationDuration: Duration.zero,
                          ),
                          onTokenReceived: _onToken,
                          onError: _onError,
                          onTokenExpired: () => widget.onTokenChanged(null),
                        )
                      : TurnstileDocumentView(
                          key: challengeKey,
                          siteKey: TurnstileConfig.siteKey,
                          baseUrl: TurnstileConfig.baseUrl,
                          size: resolved,
                          onTokenChanged: _onToken,
                          onError: _onError,
                        ),
                ),
                if (_failed)
                  Positioned.fill(
                    child: ColoredBox(
                      color: const Color(0xFF1A1B1E),
                      child: Center(
                        child: TextButton(
                          onPressed: () => reset(force: true),
                          child: Text(context.l10n.turnstileRetry),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
