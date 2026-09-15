import 'package:fitforge/core/referrals/referral_rules.dart';
import 'package:fitforge/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReferralCode', () {
    test('normalizes and validates NNNLLL without ambiguous characters', () {
      expect(ReferralCode.normalize(' 482-kmt '), '482KMT');
      expect(ReferralCode.isValid('482KMT'), isTrue);
      expect(ReferralCode.isValid('482-kmt'), isTrue);
      expect(ReferralCode.isValid('482OIL'), isFalse);
      expect(ReferralCode.isValid('012ABC'), isFalse);
      expect(ReferralCode.isValid('KMT482'), isFalse);
      expect(ReferralCode.isValid('48KMT2'), isFalse);
      expect(ReferralCode.isValid(''), isFalse);
    });
  });

  group('isReferralActiveUser', () {
    final created = DateTime.utc(2026, 9, 1, 12);

    test('grace period covers the first 7 days without workouts', () {
      expect(
        isReferralActiveUser(
          createdAt: created,
          now: DateTime.utc(2026, 9, 7, 12),
          completedWorkoutsPreviousIsoWeek: 0,
        ),
        isTrue,
      );
    });

    test('after grace, needs 2 completed workouts in the previous ISO week',
        () {
      expect(
        isReferralActiveUser(
          createdAt: created,
          now: DateTime.utc(2026, 9, 14, 12),
          completedWorkoutsPreviousIsoWeek: 1,
        ),
        isFalse,
      );
      expect(
        isReferralActiveUser(
          createdAt: created,
          now: DateTime.utc(2026, 9, 14, 12),
          completedWorkoutsPreviousIsoWeek: 2,
        ),
        isTrue,
      );
    });

    test('counts only the previous Monday-Sunday UTC window', () {
      final now = DateTime.utc(2026, 9, 14, 15); // Monday
      final previousWeek = [
        DateTime.utc(2026, 9, 7, 10),
        DateTime.utc(2026, 9, 13, 18),
      ];
      final thisWeek = [DateTime.utc(2026, 9, 14, 8)];
      expect(
        referralCompletedWorkoutsInPreviousIsoWeek(
          completedAt: [...previousWeek, ...thisWeek],
          now: now,
        ),
        2,
      );
    });
  });

  group('referralEntitlementFor', () {
    test('grants gymrat at 3 actives and gymrat_pro at 5', () {
      expect(
        referralEntitlementFor(
          activeCount: 3,
          currentTier: 'free',
          currentSource: null,
        ).tier,
        'gymrat',
      );
      expect(
        referralEntitlementFor(
          activeCount: 4,
          currentTier: 'gymrat',
          currentSource: 'referral',
        ).tier,
        'gymrat',
      );
      final pro = referralEntitlementFor(
        activeCount: 5,
        currentTier: 'gymrat',
        currentSource: 'referral',
      );
      expect(pro.tier, 'gymrat_pro');
      expect(pro.source, 'referral');
    });

    test('demotes referral Pro to Gymrat below 5, and to free below 3', () {
      expect(
        referralEntitlementFor(
          activeCount: 4,
          currentTier: 'gymrat_pro',
          currentSource: 'referral',
        ).tier,
        'gymrat',
      );
      final free = referralEntitlementFor(
        activeCount: 2,
        currentTier: 'gymrat',
        currentSource: 'referral',
      );
      expect(free.tier, 'free');
      expect(free.source, isNull);
    });

    test('does not overwrite iap or courtesy', () {
      final iap = referralEntitlementFor(
        activeCount: 5,
        currentTier: 'gymrat',
        currentSource: 'iap',
      );
      expect(iap.tier, 'gymrat');
      expect(iap.source, 'iap');

      final courtesy = referralEntitlementFor(
        activeCount: 0,
        currentTier: 'gymrat_pro',
        currentSource: 'courtesy',
      );
      expect(courtesy.tier, 'gymrat_pro');
      expect(courtesy.source, 'courtesy');
    });
  });

  test('referral source is distinct from courtesy', () {
    final referred = UserProfile(
      id: 'u1',
      createdAt: DateTime.utc(2026, 1, 1),
      subscriptionTier: SubscriptionTier.gymratPro,
      subscriptionSource: SubscriptionSource.referral,
      referralCode: '482KMT',
    );
    expect(referred.isReferralSubscription, isTrue);
    expect(referred.isCourtesySubscription, isFalse);
    expect(referred.hidesStoreUpgrades, isTrue);
    expect(SubscriptionSource.fromCode('referral').code, 'referral');

    final gymratFromReferrals = UserProfile(
      id: 'u2',
      createdAt: DateTime.utc(2026, 1, 1),
      subscriptionTier: SubscriptionTier.gymrat,
      subscriptionSource: SubscriptionSource.referral,
    );
    expect(gymratFromReferrals.hidesStoreUpgrades, isFalse);
  });
}
