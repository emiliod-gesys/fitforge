/// Código de referido: 3 dígitos (2-9) + 3 letras (sin I, L, O).
abstract final class ReferralCode {
  static const digitAlphabet = '23456789';
  static const letterAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ';
  static final format = RegExp(r'^[2-9]{3}[ABCDEFGHJKMNPQRSTUVWXYZ]{3}$');

  static String normalize(String raw) {
    return raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static bool isValid(String raw) => format.hasMatch(normalize(raw));
}

const referralGymratThreshold = 3;
const referralProThreshold = 5;
const referralGrace = Duration(days: 7);

DateTime referralUtcWeekStart(DateTime now) {
  final utc = now.toUtc();
  final day = DateTime.utc(utc.year, utc.month, utc.day);
  return day.subtract(Duration(days: utc.weekday - DateTime.monday));
}

int referralCompletedWorkoutsInPreviousIsoWeek({
  required Iterable<DateTime> completedAt,
  required DateTime now,
}) {
  final end = referralUtcWeekStart(now);
  final start = end.subtract(const Duration(days: 7));
  var count = 0;
  for (final stamp in completedAt) {
    final utc = stamp.toUtc();
    if (!utc.isBefore(start) && utc.isBefore(end)) count++;
  }
  return count;
}

bool isReferralActiveUser({
  required DateTime createdAt,
  required DateTime now,
  required int completedWorkoutsPreviousIsoWeek,
}) {
  if (now.toUtc().difference(createdAt.toUtc()) < referralGrace) return true;
  return completedWorkoutsPreviousIsoWeek >= 2;
}

class ReferralEntitlementDecision {
  final String? tier;
  final String? source;

  const ReferralEntitlementDecision({this.tier, this.source});
}

/// Mirrors `sync_referral_entitlement` so grant/revoke can be unit-tested.
ReferralEntitlementDecision referralEntitlementFor({
  required int activeCount,
  required String? currentTier,
  required String? currentSource,
}) {
  if (currentSource == 'iap' || currentSource == 'courtesy') {
    return ReferralEntitlementDecision(
      tier: currentTier,
      source: currentSource,
    );
  }
  if (activeCount >= referralProThreshold) {
    return const ReferralEntitlementDecision(
      tier: 'gymrat_pro',
      source: 'referral',
    );
  }
  if (activeCount >= referralGymratThreshold) {
    return const ReferralEntitlementDecision(
      tier: 'gymrat',
      source: 'referral',
    );
  }
  if (currentSource == 'referral') {
    return const ReferralEntitlementDecision(tier: 'free');
  }
  return ReferralEntitlementDecision(
    tier: currentTier,
    source: currentSource,
  );
}
