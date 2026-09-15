import 'package:fitforge/core/subscription/plan_upgrade.dart';
import 'package:fitforge/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

UserProfile _profile({
  SubscriptionTier tier = SubscriptionTier.free,
  SubscriptionSource source = SubscriptionSource.none,
}) {
  return UserProfile(
    id: 'u1',
    createdAt: DateTime.utc(2026, 1, 1),
    subscriptionTier: tier,
    subscriptionSource: source,
  );
}

void main() {
  test('store upgrade path is free → gymrat → pro', () {
    expect(
      PlanUpgrade.nextStoreTier(SubscriptionTier.free),
      SubscriptionTier.gymrat,
    );
    expect(
      PlanUpgrade.nextStoreTier(SubscriptionTier.gymrat),
      SubscriptionTier.gymratPro,
    );
    expect(PlanUpgrade.nextStoreTier(SubscriptionTier.gymratPro), isNull);
  });

  test('offers store upgrade except courtesy and referral pro', () {
    expect(PlanUpgrade.canOfferStoreUpgrade(_profile()), isTrue);
    expect(
      PlanUpgrade.canOfferStoreUpgrade(
        _profile(tier: SubscriptionTier.gymrat),
      ),
      isTrue,
    );
    expect(
      PlanUpgrade.canOfferStoreUpgrade(
        _profile(
          tier: SubscriptionTier.gymrat,
          source: SubscriptionSource.referral,
        ),
      ),
      isTrue,
    );
    expect(
      PlanUpgrade.canOfferStoreUpgrade(
        _profile(tier: SubscriptionTier.gymratPro),
      ),
      isFalse,
    );
    expect(
      PlanUpgrade.canOfferStoreUpgrade(
        _profile(
          tier: SubscriptionTier.gymratPro,
          source: SubscriptionSource.courtesy,
        ),
      ),
      isFalse,
    );
    expect(
      PlanUpgrade.canOfferStoreUpgrade(
        _profile(
          tier: SubscriptionTier.gymratPro,
          source: SubscriptionSource.referral,
        ),
      ),
      isFalse,
    );
  });
}
