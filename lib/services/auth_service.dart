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
