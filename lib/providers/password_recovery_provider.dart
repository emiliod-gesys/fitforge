import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

/// `true` cuando el usuario abrió el enlace de recuperación y debe elegir contraseña nueva.
final passwordRecoveryPendingProvider = StateProvider<bool>((ref) => false);

final authRecoveryListenerProvider = Provider<void>((ref) {
  final subscription = SupabaseService.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      ref.read(passwordRecoveryPendingProvider.notifier).state = true;
    }
  });
  ref.onDispose(subscription.cancel);
});
