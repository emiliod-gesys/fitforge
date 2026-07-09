import 'package:fitforge/core/subscription/subscription_features.dart';
import 'package:fitforge/models/profile.dart';
import 'package:fitforge/services/routine_limit_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('max saved routines per tier', () {
    expect(SubscriptionTier.free.maxSavedRoutines, 10);
    expect(SubscriptionTier.gymrat.maxSavedRoutines, 20);
    expect(SubscriptionTier.gymratPro.maxSavedRoutines, 50);
  });

  test('routine limit status blocks at cap', () {
    final service = RoutineLimitService();
    final status = service.statusFor(
      tier: SubscriptionTier.free,
      routineCount: 10,
    );

    expect(status.canCreate, isFalse);
    expect(status.remaining, 0);
  });

  test('routine limit status allows below cap', () {
    final service = RoutineLimitService();
    final status = service.statusFor(
      tier: SubscriptionTier.gymrat,
      routineCount: 19,
    );

    expect(status.canCreate, isTrue);
    expect(status.remaining, 1);
  });
}
