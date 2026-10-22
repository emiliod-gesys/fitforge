import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:fitforge/widgets/turnstile_captcha.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pantalla angosta de un plegable usa el captcha compacto', () {
    expect(
      turnstileSizeForWidth(width: 260, current: null),
      TurnstileSize.compact,
    );
  });

  test('pantalla ancha usa el captcha normal', () {
    expect(
      turnstileSizeForWidth(width: 400, current: null),
      TurnstileSize.normal,
    );
  });

  test('no cambia de tamaño en cada pixel al plegar', () {
    expect(
      turnstileSizeForWidth(width: 300, current: TurnstileSize.compact),
      TurnstileSize.compact,
    );
    expect(
      turnstileSizeForWidth(width: 300, current: TurnstileSize.normal),
      TurnstileSize.normal,
    );
    expect(
      turnstileSizeForWidth(width: 340, current: TurnstileSize.compact),
      TurnstileSize.normal,
    );
    expect(
      turnstileSizeForWidth(width: 279, current: TurnstileSize.normal),
      TurnstileSize.compact,
    );
  });
}
