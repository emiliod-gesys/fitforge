import 'package:fitforge/core/subscription/billing_products.dart';
import 'package:fitforge/models/profile.dart';
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
  });
}
