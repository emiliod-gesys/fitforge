import 'dart:async';

import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// URL que el WebView debe usar como documento.
///
/// En Android, `loadDataWithBaseURL` sin `historyUrl` deja `window.location`
/// en `about:blank`. Turnstile responde 110200 y el widget entra en ciclo.
/// Con la misma URL en base y en historial, el origen es el dominio permitido.
String? turnstileDocumentUrl(String baseUrl) {
  var value = baseUrl.trim();
  if (value.isEmpty) return null;
  if (!value.endsWith('/')) value = '$value/';
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  return value;
}

/// Verificador de Turnstile sin el reload automático del paquete.
class TurnstileDocumentView extends StatefulWidget {
  final String siteKey;
  final String baseUrl;
  final TurnstileSize size;
  final ValueChanged<String?> onTokenChanged;
  final ValueChanged<TurnstileException> onError;

  const TurnstileDocumentView({
    super.key,
    required this.siteKey,
    required this.baseUrl,
    required this.size,
    required this.onTokenChanged,
    required this.onError,
  });

  @override
  State<TurnstileDocumentView> createState() => _TurnstileDocumentViewState();
}

class _TurnstileDocumentViewState extends State<TurnstileDocumentView> {
  static const _scriptTimeout = Duration(seconds: 12);

  Timer? _timeout;
  bool _rendered = false;
  bool _reportedError = false;

  late final String _html = _pageHtml(
    siteKey: widget.siteKey,
    sizeName: widget.size.name,
  );

  @override
  void initState() {
    super.initState();
    _armTimeout();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  void _armTimeout() {
    _timeout?.cancel();
    _timeout = Timer(_scriptTimeout, () {
      if (!mounted || _rendered) return;
      _report(const TurnstileException(
        'Turnstile script did not render',
        code: 110500,
        errorType: TurnstileError.UNSUPPORTED_BROWSER,
      ));
    });
  }

  void _report(TurnstileException error) {
    if (_reportedError) return;
    _reportedError = true;
    _timeout?.cancel();
    if (kDebugMode) {
      debugPrint(
        'Turnstile ${error.code}: ${error.message} '
        '(retryable=${error.retryable})',
      );
    }
    widget.onTokenChanged(null);
    widget.onError(error);
  }

  @override
  Widget build(BuildContext context) {
    final documentUrl = turnstileDocumentUrl(widget.baseUrl);
    final origin = documentUrl == null ? null : WebUri(documentUrl);

    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: _html,
        baseUrl: origin,
        historyUrl: origin,
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        thirdPartyCookiesEnabled: true,
        sharedCookiesEnabled: true,
        cacheMode: CacheMode.LOAD_NO_CACHE,
        transparentBackground: false,
        disableHorizontalScroll: true,
        disableVerticalScroll: true,
        verticalScrollBarEnabled: false,
        horizontalScrollBarEnabled: false,
        supportZoom: false,
        useWideViewPort: false,
        disableDefaultErrorPage: true,
        disableContextMenu: true,
        mediaPlaybackRequiresUserGesture: true,
      ),
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(
          handlerName: 'TurnstileToken',
          callback: (args) {
            _rendered = true;
            _timeout?.cancel();
            final token = args.isEmpty ? null : args.first?.toString();
            if (token == null || token.isEmpty) return;
            widget.onTokenChanged(token);
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'TurnstileWidgetId',
          callback: (args) {
            _rendered = true;
            _timeout?.cancel();
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'TurnstileError',
          callback: (args) {
            final raw = args.isEmpty ? null : args.first;
            final code = switch (raw) {
              final int value => value,
              final String value => int.tryParse(value) ?? -1,
              _ => -1,
            };
            _report(TurnstileException.fromCode(code));
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'TokenExpired',
          callback: (_) => widget.onTokenChanged(null),
        );
      },
      onLoadStop: (_, __) {
        if (_rendered || _reportedError) return;
        _armTimeout();
      },
    );
  }
}

String _pageHtml({required String siteKey, required String sizeName}) {
  final safeKey = siteKey.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
  final safeSize = switch (sizeName) {
    'compact' => 'compact',
    'flexible' => 'flexible',
    _ => 'normal',
  };
  return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit"></script>
  <style>
    html, body { margin: 0; padding: 0; background: #1A1B1E; overflow: hidden; width: 100%; height: 100%; }
    #cf-turnstile { width: 100%; }
  </style>
</head>
<body>
  <div id="cf-turnstile"></div>
  <script>
    turnstile.ready(function () {
      var node = document.getElementById('cf-turnstile');
      if (node.hasChildNodes()) return;
      var widgetId = turnstile.render('#cf-turnstile', {
        sitekey: '$safeKey',
        theme: 'dark',
        size: '$safeSize',
        language: 'auto',
        retry: 'never',
        'retry-interval': 8000,
        'refresh-expired': 'manual',
        'refresh-timeout': 'manual',
        'feedback-enabled': false,
        callback: function (token) {
          window.flutter_inappwebview.callHandler('TurnstileToken', token);
        },
        'error-callback': function (code) {
          window.flutter_inappwebview.callHandler('TurnstileError', String(code));
        },
        'expired-callback': function () {
          window.flutter_inappwebview.callHandler('TokenExpired');
        }
      });
      window.flutter_inappwebview.callHandler('TurnstileWidgetId', widgetId);
    });
  </script>
</body>
</html>
''';
}
