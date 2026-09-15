import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/routine_limit_exception.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../services/routine_limit_service.dart';
import 'plan_upgrade.dart';

final routineLimitServiceProvider = Provider((ref) => RoutineLimitService());

final routineLimitStatusProvider = FutureProvider<RoutineLimitStatus>((ref) async {
  ref.watch(authStateProvider);
  final profile = await ref.watch(profileProvider.future);
  final routines = await ref.watch(routinesProvider.future);
  final tier = profile?.subscriptionTier ?? SubscriptionTier.free;
  final countable = routines.where((r) => !r.isHyroxSystem).length;
  return ref.watch(routineLimitServiceProvider).statusFor(
        tier: tier,
        routineCount: countable,
      );
});

Future<bool> ensureCanCreateRoutine(BuildContext context, WidgetRef ref) async {
  final status = await ref.read(routineLimitStatusProvider.future);
  if (status.canCreate) return true;
  if (context.mounted) {
    final profile = ref.read(profileProvider).valueOrNull;
    PlanUpgrade.showLimitSnackBar(
      context,
      message: PlanUpgrade.routinesMessage(
        context.l10n,
        status.tier,
        status.limit,
      ),
      canUpgrade: PlanUpgrade.canOfferStoreUpgrade(profile),
    );
  }
  return false;
}

void showRoutineSaveErrorSnackBar(
  BuildContext context,
  Object error, {
  UserProfile? profile,
}) {
  final l10n = context.l10n;
  if (error is RoutineLimitReachedException) {
    PlanUpgrade.showLimitSnackBar(
      context,
      message: PlanUpgrade.routinesMessage(l10n, error.tier, error.limit),
      canUpgrade: profile != null
          ? PlanUpgrade.canOfferStoreUpgrade(profile)
          : PlanUpgrade.nextStoreTier(error.tier) != null,
    );
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.saveFailed('$error'))),
  );
}
