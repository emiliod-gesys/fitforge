import 'package:fitforge/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UserProfile profile({
    SubscriptionSource source = SubscriptionSource.courtesy,
    DateTime? expires,
  }) {
    return UserProfile(
      id: 'u',
      createdAt: DateTime.utc(2026, 1, 1),
      subscriptionTier: SubscriptionTier.gymratPro,
      subscriptionSource: source,
      subscriptionExpiresAt: expires,
    );
  }

  test('courtesy without an end date stays active', () {
    expect(profile().courtesyHasEnded, isFalse);
  });

  test('courtesy ends after its date', () {
    expect(
      profile(expires: DateTime.utc(2026, 1, 2)).courtesyHasEnded,
      isTrue,
    );
  });

  test('courtesy with a future date stays active', () {
    expect(
      profile(expires: DateTime.utc(2027, 12, 9)).courtesyHasEnded,
      isFalse,
    );
  });

  test('a paid plan is not treated as ended courtesy', () {
    expect(
      profile(
        source: SubscriptionSource.iap,
        expires: DateTime.utc(2026, 1, 2),
      ).courtesyHasEnded,
      isFalse,
    );
  });
}
