import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/profile_completeness.dart';
import '../core/content/fitness_daily_tips.dart';
import '../models/profile.dart';
import '../providers/app_providers.dart';
import '../services/daily_tip_preferences.dart';
import 'daily_tip_dialog.dart';
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
      var profile = ref.read(profileProvider).valueOrNull;
      if (profile == null) return;

      if (ProfileCompleteness.needsOnboarding(profile)) {
        return;
      }

      final lastWeightAt = await ref.read(profileServiceProvider).getLastWeightMeasuredAt();
      if (!mounted) return;

      if (ProfileCompleteness.needsWeightUpdate(lastWeightAt)) {
        await _showWeightUpdate(profile);
        if (!mounted) return;
        profile = ref.read(profileProvider).valueOrNull;
        if (profile == null) return;
      }

      await _maybeShowDailyTip(profile);
    } finally {
      _gateRunning = false;
    }
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

  Future<void> _maybeShowDailyTip(UserProfile profile) async {
    if (!await DailyTipPreferences.shouldShowToday()) return;
    if (!mounted) return;

    final tip = FitnessDailyTips.pickFor(
      date: DateTime.now(),
      userId: profile.id,
      fitnessGoal: profile.fitnessGoal,
    );

    final languageCode = ref.read(preferredLanguageProvider);
    await showDailyTipDialog(
      context,
      tip: tip,
      languageCode: languageCode,
    );
    if (!mounted) return;
    await DailyTipPreferences.markShownToday();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
