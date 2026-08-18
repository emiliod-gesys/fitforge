import '../../models/profile.dart';

/// IDs de producto en Play Console / App Store Connect.
///
/// Hay que crear estas suscripciones mensuales en cada tienda antes de que
/// la compra funcione de punta a punta. El `applicationId` de Android es
/// `forgen.app`.
abstract final class BillingProducts {
  static const gymratMonthly = 'forgen.gymrat.monthly';
  static const gymratProMonthly = 'forgen.gymrat_pro.monthly';

  static const ids = {gymratMonthly, gymratProMonthly};

  static String? productIdFor(SubscriptionTier tier) {
    return switch (tier) {
      SubscriptionTier.gymrat => gymratMonthly,
      SubscriptionTier.gymratPro => gymratProMonthly,
      SubscriptionTier.free => null,
    };
  }

  static SubscriptionTier? tierForProduct(String productId) {
    return switch (productId) {
      gymratMonthly => SubscriptionTier.gymrat,
      gymratProMonthly => SubscriptionTier.gymratPro,
      _ => null,
    };
  }

  static int rank(SubscriptionTier tier) => switch (tier) {
        SubscriptionTier.free => 0,
        SubscriptionTier.gymrat => 1,
        SubscriptionTier.gymratPro => 2,
      };
}
