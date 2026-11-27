import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/turnstile_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../l10n/l10n_extensions.dart';
import 'turnstile_document_view.dart';

/// Elige tamaño de Turnstile según el ancho del formulario.
///
/// `flexible` (min 300px) llena el ancho de la card. Por debajo de eso, en
/// pantallas exteriores de plegable, usamos `compact` para no recortar el
/// WebView ni entrar en bucles de resize.
TurnstileSize turnstileSizeForWidth({
  required double width,
  required TurnstileSize? current,
}) {
  if (!width.isFinite || width <= 0) {
    return current ?? TurnstileSize.flexible;
  }
  if (current == null) {
    return width < 300 ? TurnstileSize.compact : TurnstileSize.flexible;
  }
  if (current == TurnstileSize.compact && width >= 320) {
    return TurnstileSize.flexible;
  }
  if ((current == TurnstileSize.flexible || current == TurnstileSize.normal) &&
      width < 280) {
    return TurnstileSize.compact;
  }
  if (current == TurnstileSize.normal && width >= 280) {
    return TurnstileSize.flexible;
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

        final boxWidth = resolved == TurnstileSize.flexible
            ? constraints.maxWidth
            : resolved.width;
        final challengeKey = ValueKey((_widgetKey, resolved));
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: boxWidth,
            height: resolved.height,
            child: ClipRRect(
              borderRadius: AppTokens.borderRadiusMd,
              child: ColoredBox(
                color: AppColors.card,
                child: Stack(
                  children: [
                    Positioned.fill(
                      // TurnstileDocumentView solo en Android: evita el reload
                      // infinito por about:blank. En iOS el paquete ya funcionaba;
                      // el WebView custom del update lo rompió.
                      child: !kIsWeb &&
                              defaultTargetPlatform == TargetPlatform.android
                          ? TurnstileDocumentView(
                              key: challengeKey,
                              siteKey: TurnstileConfig.siteKey,
                              baseUrl: TurnstileConfig.baseUrl,
                              size: resolved,
                              onTokenChanged: _onToken,
                              onError: _onError,
                            )
                          : CloudflareTurnstile(
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
                              onTokenExpired: () =>
                                  widget.onTokenChanged(null),
                            ),
                    ),
                    if (_failed)
                      Positioned.fill(
                        child: ColoredBox(
                          color: AppColors.card,
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
            ),
          ),
        );
      },
    );
  }
}
