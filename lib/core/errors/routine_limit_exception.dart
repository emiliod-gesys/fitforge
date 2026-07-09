import '../../models/profile.dart';

class RoutineLimitReachedException implements Exception {
  const RoutineLimitReachedException({
    required this.limit,
    required this.tier,
  });

  final int limit;
  final SubscriptionTier tier;

  @override
  String toString() => 'routine_limit_reached';
}
