import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../widgets/subscription/plan_upgrade_sheet.dart';

/// Navegación y copy para subir de plan desde límites (Coach / rutinas).
abstract final class PlanUpgrade {
  static SubscriptionTier? nextStoreTier(SubscriptionTier current) {
    return switch (current) {
      SubscriptionTier.free => SubscriptionTier.gymrat,
      SubscriptionTier.gymrat => SubscriptionTier.gymratPro,
      SubscriptionTier.gymratPro => null,
    };
  }

  static bool canOfferStoreUpgrade(UserProfile? profile) {
    if (profile?.hidesStoreUpgrades == true) return false;
    final tier = profile?.subscriptionTier ?? SubscriptionTier.free;
    return nextStoreTier(tier) != null;
  }

  static String coachMessage(
    AppLocalizations l10n,
    SubscriptionTier tier,
    int limit,
  ) {
    return switch (tier) {
      SubscriptionTier.free => l10n.planUpgradeCoachFree(limit),
      SubscriptionTier.gymrat => l10n.planUpgradeCoachGymrat(limit),
      SubscriptionTier.gymratPro => l10n.coachDailyLimitReached(limit),
    };
  }

  static String routinesMessage(
    AppLocalizations l10n,
    SubscriptionTier tier,
    int limit,
  ) {
    return switch (tier) {
      SubscriptionTier.free => l10n.planUpgradeRoutinesFree(limit),
      SubscriptionTier.gymrat => l10n.planUpgradeRoutinesGymrat(limit),
      SubscriptionTier.gymratPro => l10n.planUpgradeRoutinesMax(limit),
    };
  }

  static Future<void> openPlan(BuildContext context) {
    return PlanUpgradeSheet.show(context);
  }

  static void showLimitSnackBar(
    BuildContext context, {
    required String message,
    required bool canUpgrade,
  }) {
    final l10n = context.l10n;
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
        action: canUpgrade
            ? SnackBarAction(
                label: l10n.subscriptionSeePlans,
                onPressed: () {
                  if (!navigator.context.mounted) return;
                  openPlan(navigator.context);
                },
              )
            : null,
      ),
    );
  }
}
