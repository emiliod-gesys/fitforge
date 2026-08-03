import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/auth_redirect_config.dart';
import '../core/constants/google_auth_config.dart';
import 'supabase_service.dart';

class AuthService {
  final _client = SupabaseService.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  GoogleSignIn? get _googleSignIn {
    if (!GoogleAuthConfig.isNativeConfigured) return null;
    return GoogleSignIn(
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

  /// Login con Google (nativo si hay `GOOGLE_WEB_CLIENT_ID`, si no OAuth en navegador).
  Future<void> signInWithGoogle() async {
    if (!GoogleAuthConfig.enabled) {
      throw const AuthException('Google sign-in is disabled');
    }
    final googleSignIn = _googleSignIn;
    if (googleSignIn != null) {
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
      return;
    }

    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AuthRedirectConfig.loginCallback,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
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
