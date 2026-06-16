import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tu-proyecto.supabase.co',
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'tu-anon-key',
  );
}

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      debug: kDebugMode,
    );
  }
}
