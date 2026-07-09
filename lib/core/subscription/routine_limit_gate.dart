import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/routine_limit_exception.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../services/routine_limit_service.dart';

final routineLimitServiceProvider = Provider((ref) => RoutineLimitService());

final routineLimitStatusProvider = FutureProvider<RoutineLimitStatus>((ref) async {
  ref.watch(authStateProvider);
  final profile = await ref.watch(profileProvider.future);
  final routines = await ref.watch(routinesProvider.future);
  final tier = profile?.subscriptionTier ?? SubscriptionTier.free;
  return ref.watch(routineLimitServiceProvider).statusFor(
        tier: tier,
        routineCount: routines.length,
      );
});

Future<bool> ensureCanCreateRoutine(BuildContext context, WidgetRef ref) async {
  final status = await ref.read(routineLimitStatusProvider.future);
  if (status.canCreate) return true;
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.routineLimitReached(status.limit))),
    );
  }
  return false;
}

void showRoutineSaveErrorSnackBar(BuildContext context, Object error) {
  final l10n = context.l10n;
  final message = error is RoutineLimitReachedException
      ? l10n.routineLimitReached(error.limit)
      : l10n.saveFailed('$error');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
