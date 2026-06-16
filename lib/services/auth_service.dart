import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  final _client = SupabaseService.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

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

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email, {String? captchaToken}) async {
    await _client.auth.resetPasswordForEmail(
      email,
      captchaToken: captchaToken,
    );
  }
}
