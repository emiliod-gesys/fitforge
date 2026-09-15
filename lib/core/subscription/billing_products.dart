import '../../models/profile.dart';

/// IDs de producto en Play Console / App Store Connect.
///
/// Hay que crear estas suscripciones mensuales en cada tienda antes de que
/// la compra funcione de punta a punta. El `applicationId` de Android es
/// `forgen.app`.
abstract final class BillingProducts {
  static const gymratMonthly = 'forgen.gymrat.monthly';
  static const gymratProMonthly = 'forgen.gymrat_pro.monthly';

  /// Precio de lista mensual (USD), alineado con los planes básicos de Play.
  static const gymratMonthlyPrice = r'$4.99';
  static const gymratProMonthlyPrice = r'$9.99';

  /// Precio tachado de anclaje (percepción de oferta de lanzamiento).
  static const gymratCompareAtPrice = r'$7.99';
  static const gymratProCompareAtPrice = r'$11.99';

  static const androidPackage = 'forgen.app';
  static const iosBundleId = 'io.fitforge.app';

  static const ids = {gymratMonthly, gymratProMonthly};

  static String monthlyPriceLabel(SubscriptionTier tier) => switch (tier) {
        SubscriptionTier.free => r'$0',
        SubscriptionTier.gymrat => gymratMonthlyPrice,
        SubscriptionTier.gymratPro => gymratProMonthlyPrice,
      };

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
