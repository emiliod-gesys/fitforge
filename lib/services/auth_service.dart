import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  final _client = SupabaseService.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail(String email, String password, {String? name}) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'display_name': name} : null,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
