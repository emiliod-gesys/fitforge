import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/profile_completeness.dart';
import '../models/profile.dart';
import '../providers/app_providers.dart';
import 'profile/profile_onboarding_dialog.dart';
import 'profile/weight_update_dialog.dart';

/// Muestra onboarding obligatorio o actualización de peso al abrir la app.
class ProfileGateListener extends ConsumerStatefulWidget {
  const ProfileGateListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ProfileGateListener> createState() => _ProfileGateListenerState();
}

class _ProfileGateListenerState extends ConsumerState<ProfileGateListener>
    with WidgetsBindingObserver {
  bool _gateRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual<AsyncValue<UserProfile?>>(
      profileProvider,
      (previous, next) {
        next.whenData((profile) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _runGates(profile);
          });
        });
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runGates(profile);
    });
  }

  Future<void> _runGates(UserProfile? profile) async {
    if (_gateRunning || !mounted || profile == null) return;

    _gateRunning = true;
    try {
      var current = profile;

      if (ProfileCompleteness.needsOnboarding(current)) {
        await _showOnboarding(current);
        ref.invalidate(profileProvider);
        final updated = await ref.read(profileProvider.future);
        if (!mounted || updated == null || ProfileCompleteness.needsOnboarding(updated)) {
          return;
        }
        current = updated;
      }

      final lastWeightAt = await ref.read(profileServiceProvider).getLastWeightMeasuredAt();
      if (!mounted) return;

      if (ProfileCompleteness.needsWeightUpdate(lastWeightAt)) {
        await _showWeightUpdate(current);
      }
    } finally {
      _gateRunning = false;
    }
  }

  Future<void> _showOnboarding(UserProfile profile) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: ProfileOnboardingDialog(initialProfile: profile),
      ),
    );
  }

  Future<void> _showWeightUpdate(UserProfile profile) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: WeightUpdateDialog(profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
