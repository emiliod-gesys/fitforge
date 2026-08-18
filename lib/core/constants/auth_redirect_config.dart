import 'package:flutter/foundation.dart';

/// Deep links para flujos de autenticación de Supabase (móvil).
abstract final class AuthRedirectConfig {
  static const _androidLoginCallback = 'forgen.app://login-callback';
  static const _androidResetPassword = 'forgen.app://reset-password';
  static const _iosLoginCallback = 'io.fitforge.app://login-callback';
  static const _iosResetPassword = 'io.fitforge.app://reset-password';

  static String get loginCallback =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
          ? _iosLoginCallback
          : _androidLoginCallback;

  static String get resetPassword =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
          ? _iosResetPassword
          : _androidResetPassword;
}
