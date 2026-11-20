import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/apple_auth_config.dart';
import '../core/constants/auth_redirect_config.dart';
import '../core/constants/google_auth_config.dart';
import 'supabase_service.dart';

class AuthService {
  final _client = SupabaseService.client;
  GoogleSignIn? _googleSignIn;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  GoogleSignIn? get _google {
    if (!GoogleAuthConfig.isNativeConfigured) return null;
    return _googleSignIn ??= GoogleSignIn(
      clientId: !kIsWeb &&
              defaultTargetPlatform == TargetPlatform.iOS &&
              GoogleAuthConfig.iosClientId.isNotEmpty
          ? GoogleAuthConfig.iosClientId
          : null,
      serverClientId: GoogleAuthConfig.webClientId,
    );
  }

  Future<AuthResponse> signInWithEmail(
    String email,
    String password, {
    String? captchaToken,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
      captchaToken: captchaToken,
    );
  }

  Future<AuthResponse> signUpWithEmail(
    String email,
    String password, {
    String? name,
    String? captchaToken,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: name != null && name.isNotEmpty ? {'display_name': name} : null,
      captchaToken: captchaToken,
    );
  }

  /// Login con Google. En Android, si Play Services rechaza el token nativo,
  /// sigue con el flujo OAuth del navegador (el que ya completa la sesión).
  Future<void> signInWithGoogle() async {
    if (!GoogleAuthConfig.enabled) {
      throw const AuthException('Google sign-in is disabled');
    }
    final googleSignIn = _google;
    if (googleSignIn == null) {
      await _signInWithGoogleOAuth();
      return;
    }

    try {
      await _signInWithGoogleNative(googleSignIn);
    } on AuthException catch (e) {
      if (_isGoogleCancel(e) || !_canFallBackToGoogleOAuth) rethrow;
      debugPrint('Google native sign-in failed: ${e.message}');
      await _abandonNativeGoogleSession(googleSignIn);
      await _signInWithGoogleOAuth();
    } catch (e, stack) {
      if (_isGoogleCancel(e) || !_canFallBackToGoogleOAuth) {
        debugPrint('Google native sign-in failed: $e\n$stack');
        if (_isGoogleCancel(e)) {
          throw const AuthException('Google sign-in cancelled');
        }
        rethrow;
      }
      debugPrint('Google native sign-in failed, opening browser: $e\n$stack');
      await _abandonNativeGoogleSession(googleSignIn);
      await _signInWithGoogleOAuth();
    }
  }

  bool get _canFallBackToGoogleOAuth =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _signInWithGoogleNative(GoogleSignIn googleSignIn) async {
    final account = await googleSignIn.signIn();
    if (account == null) {
      throw const AuthException('Google sign-in cancelled');
    }
    final googleAuth = await account.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthException('Missing Google ID token');
    }
    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  Future<void> _signInWithGoogleOAuth() async {
    final launched = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AuthRedirectConfig.loginCallback,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw const AuthException('Google sign-in failed');
    }
  }

  Future<void> _abandonNativeGoogleSession(GoogleSignIn googleSignIn) async {
    try {
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google sign-out before browser fallback failed: $e');
    }
  }

  bool _isGoogleCancel(Object error) {
    if (error is AuthException) {
      return error.message.toLowerCase().contains('cancel');
    }
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      final message = (error.message ?? '').toLowerCase();
      return code.contains('cancel') || message.contains('12501');
    }
    final text = error.toString().toLowerCase();
    return text.contains('cancel') || text.contains('12501');
  }

  /// Login con Apple: nativo en iOS/macOS; OAuth en Android/web.
  Future<void> signInWithApple() async {
    if (!AppleAuthConfig.enabled) {
      throw const AuthException('Apple sign-in is disabled');
    }

    final useNative = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    if (!useNative) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: AuthRedirectConfig.loginCallback,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return;
    }

    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException('Missing Apple ID token');
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      final fullName = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
      if (fullName.isNotEmpty) {
        await _client.auth.updateUser(
          UserAttributes(data: {
            'display_name': fullName,
            'full_name': fullName,
          }),
        );
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthException('Apple sign-in cancelled');
      }
      throw AuthException(e.message);
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    await _client.auth.signOut();
  }

  /// Borra la cuenta del usuario autenticado (irreversible).
  /// [confirmation] debe ser `BORRAR` o `DELETE`.
  ///
  /// No reautenticamos con email/password aquí: Supabase Auth exige captcha en
  /// `signInWithPassword` y rompería el flujo. La seguridad queda en sesión JWT
  /// + confirmación tipada + validación en la Edge Function.
  Future<void> deleteAccount({
    required String confirmation,
  }) async {
    final normalized = confirmation.trim().toUpperCase();
    if (normalized != 'BORRAR' && normalized != 'DELETE') {
      throw const AuthException('invalid_confirmation');
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('not_authenticated');
    }

    // Asegura un access token fresco para la función.
    try {
      await _client.auth.refreshSession();
    } catch (_) {
      // Si falla el refresh, intentamos igual con la sesión actual.
    }

    final response = await _client.functions.invoke(
      'delete-account',
      body: {'confirmation': normalized},
    );

    final status = response.status;
    if (status < 200 || status >= 300) {
      final data = response.data;
      final message = data is Map && data['error'] != null
          ? data['error'].toString()
          : 'delete_failed';
      throw AuthException(message);
    }

    try {
      await signOut();
    } catch (_) {
      // La sesión puede quedar inválida tras borrar el usuario.
    }
  }

  Future<void> resetPassword(String email, {String? captchaToken}) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: AuthRedirectConfig.resetPassword,
      captchaToken: captchaToken,
    );
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    return _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
