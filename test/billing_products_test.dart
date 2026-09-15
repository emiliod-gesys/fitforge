import 'package:fitforge/core/subscription/billing_products.dart';
import 'package:fitforge/core/subscription/store_subscriptions.dart';
import 'package:fitforge/models/profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps store product ids to subscription tiers', () {
    expect(
      BillingProducts.tierForProduct(BillingProducts.gymratMonthly),
      SubscriptionTier.gymrat,
    );
    expect(
      BillingProducts.tierForProduct(BillingProducts.gymratProMonthly),
      SubscriptionTier.gymratPro,
    );
    expect(
      BillingProducts.productIdFor(SubscriptionTier.gymratPro),
      BillingProducts.gymratProMonthly,
    );
    expect(BillingProducts.productIdFor(SubscriptionTier.free), isNull);
    expect(
      BillingProducts.monthlyPriceLabel(SubscriptionTier.gymrat),
      BillingProducts.gymratMonthlyPrice,
    );
    expect(
      BillingProducts.monthlyPriceLabel(SubscriptionTier.gymratPro),
      BillingProducts.gymratProMonthlyPrice,
    );
    expect(BillingProducts.gymratMonthlyPrice, r'$4.99');
    expect(BillingProducts.gymratProMonthlyPrice, r'$9.99');
    expect(BillingProducts.gymratCompareAtPrice, r'$7.99');
    expect(BillingProducts.gymratProCompareAtPrice, r'$11.99');
  });

  test('store subscription management urls point to the right store', () {
    expect(
      StoreSubscriptions.manageHttpsUri(platform: TargetPlatform.iOS).toString(),
      'https://apps.apple.com/account/subscriptions',
    );
    expect(
      StoreSubscriptions.manageHttpsUri(platform: TargetPlatform.android)
          .toString(),
      'https://play.google.com/store/account/subscriptions?package=forgen.app',
    );
  });
}
