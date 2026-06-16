import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
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

  void reset() {
    widget.onTokenChanged(null);
    setState(() => _widgetKey = UniqueKey());
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
          retryAutomatically: true,
        ),
        onTokenReceived: (token) => widget.onTokenChanged(token),
        onError: (_) => widget.onTokenChanged(null),
        onTokenExpired: () {
          widget.onTokenChanged(null);
          reset();
        },
      ),
    );
  }
}
