import 'auth_redirect_config.dart';

/// Google OAuth / Sign-In (dart-define desde `dart_defines.json`).
abstract final class GoogleAuthConfig {
  /// OAuth 2.0 Web client ID (Google Cloud). Obligatorio para login nativo en Android.
  static const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// iOS client ID (`*.apps.googleusercontent.com`). Solo iOS.
  static const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// Deep link de retorno para `signInWithOAuth` (fallback).
  static const redirectUrl = AuthRedirectConfig.loginCallback;

  /// Desactivar temporalmente el botón de Google en login.
  static const enabled = false;

  static bool get isNativeConfigured => enabled && webClientId.isNotEmpty;
}
