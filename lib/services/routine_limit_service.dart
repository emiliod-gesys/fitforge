import '../core/subscription/subscription_features.dart';
import '../models/profile.dart';

class RoutineLimitStatus {
  const RoutineLimitStatus({
    required this.used,
    required this.limit,
    required this.tier,
  });

  final int used;
  final int limit;
  final SubscriptionTier tier;

  bool get canCreate => used < limit;

  int get remaining => (limit - used).clamp(0, limit);
}

class RoutineLimitService {
  RoutineLimitStatus statusFor({
    required SubscriptionTier tier,
    required int routineCount,
  }) {
    final limit = tier.maxSavedRoutines;
    return RoutineLimitStatus(used: routineCount, limit: limit, tier: tier);
  }
}
