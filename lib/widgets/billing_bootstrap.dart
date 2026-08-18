import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/billing_service.dart';
import '../services/supabase_service.dart';

/// Arranca el listener de compras cuando hay sesión.
class BillingBootstrap extends ConsumerStatefulWidget {
  final Widget child;

  const BillingBootstrap({super.key, required this.child});

  @override
  ConsumerState<BillingBootstrap> createState() => _BillingBootstrapState();
}

class _BillingBootstrapState extends ConsumerState<BillingBootstrap> {
  String? _startedForUserId;

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      final userId = next.valueOrNull?.session?.user.id ??
          SupabaseService.currentUser?.id;
      unawaited(_sync(userId));
    });
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_sync(SupabaseService.currentUser?.id));
    });
  }

  Future<void> _sync(String? userId) async {
    if (!BillingService.isSupported) return;
    if (userId == null) {
      _startedForUserId = null;
      return;
    }
    if (_startedForUserId == userId) return;
    _startedForUserId = userId;
    await ref.read(billingServiceProvider).startForUser();
  }
}
