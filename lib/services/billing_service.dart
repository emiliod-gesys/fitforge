import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../core/subscription/billing_products.dart';
import '../models/profile.dart';
import 'profile_service.dart';

enum BillingOutcome {
  success,
  cancelled,
  pending,
  unavailable,
  error,
  restored,
  none,
}

class BillingFlowResult {
  const BillingFlowResult(this.outcome, {this.tier, this.message});

  final BillingOutcome outcome;
  final SubscriptionTier? tier;
  final String? message;
}

/// Play Billing / StoreKit. Las cortesías (`subscription_source = courtesy`)
/// no se pisan ni se bajan a free al caducar un recibo de tienda.
class BillingService {
  BillingService(this._profileService);

  final ProfileService _profileService;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Map<String, Completer<BillingFlowResult>> _pending = {};
  bool _listening = false;

  static bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  void ensureListening() {
    if (_listening || !isSupported) return;
    _listening = true;
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      (purchases) => unawaited(_onPurchases(purchases)),
      onError: (_) {},
    );
  }

  Future<void> startForUser() async {
    if (!isSupported) return;
    ensureListening();
    await _syncAndroidPurchases();
  }

  Future<BillingFlowResult> purchase(SubscriptionTier tier) async {
    if (!isSupported) {
      return const BillingFlowResult(BillingOutcome.unavailable);
    }
    ensureListening();
    final productId = BillingProducts.productIdFor(tier);
    if (productId == null) {
      return const BillingFlowResult(BillingOutcome.error);
    }

    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      return const BillingFlowResult(BillingOutcome.unavailable);
    }

    final response =
        await InAppPurchase.instance.queryProductDetails({productId});
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      return const BillingFlowResult(
        BillingOutcome.unavailable,
        message: 'product_missing',
      );
    }

    final completer = Completer<BillingFlowResult>();
    _pending[productId] = completer;
    final started = await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: _purchaseParam(response.productDetails.first),
    );
    if (!started) {
      _pending.remove(productId);
      return const BillingFlowResult(BillingOutcome.error);
    }
    return completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        _pending.remove(productId);
        return const BillingFlowResult(BillingOutcome.cancelled);
      },
    );
  }

  Future<BillingFlowResult> restore() async {
    if (!isSupported) {
      return const BillingFlowResult(BillingOutcome.unavailable);
    }
    ensureListening();
    await InAppPurchase.instance.restorePurchases();
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _syncAndroidPurchases();
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final after = await _profileService.getProfile();
    if (after != null && !after.subscriptionTier.isFree) {
      return BillingFlowResult(
        BillingOutcome.restored,
        tier: after.subscriptionTier,
      );
    }
    return const BillingFlowResult(BillingOutcome.none);
  }

  PurchaseParam _purchaseParam(ProductDetails details) {
    if (defaultTargetPlatform == TargetPlatform.android &&
        details is GooglePlayProductDetails) {
      return GooglePlayPurchaseParam(
        productDetails: details,
        offerToken: details.offerToken,
      );
    }
    return PurchaseParam(productDetails: details);
  }

  Future<void> _syncAndroidPurchases() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final addition = InAppPurchase.instance
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      if (response.error != null) return;
      await _onPurchases(response.pastPurchases);
    } catch (_) {}
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    SubscriptionTier? best;
    String? bestProduct;

    for (final purchase in purchases) {
      final completer = _pending.remove(purchase.productID);
      void finish(BillingFlowResult result) {
        if (completer != null && !completer.isCompleted) {
          completer.complete(result);
        }
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          finish(const BillingFlowResult(BillingOutcome.pending));
        case PurchaseStatus.error:
          finish(
            BillingFlowResult(
              BillingOutcome.error,
              message: purchase.error?.message,
            ),
          );
        case PurchaseStatus.canceled:
          finish(const BillingFlowResult(BillingOutcome.cancelled));
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final tier = BillingProducts.tierForProduct(purchase.productID);
          if (tier != null &&
              (best == null ||
                  BillingProducts.rank(tier) > BillingProducts.rank(best))) {
            best = tier;
            bestProduct = purchase.productID;
          }
          finish(BillingFlowResult(BillingOutcome.success, tier: tier));
      }

      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }

    if (best != null && bestProduct != null) {
      await _applyStoreTier(best, bestProduct);
    }
  }

  Future<void> _applyStoreTier(SubscriptionTier tier, String productId) async {
    final profile = await _profileService.getProfile();
    if (profile == null) return;
    if (profile.subscriptionSource == SubscriptionSource.courtesy) return;
    await _profileService.updateProfile({
      'subscription_tier': tier.code,
      'subscription_source': SubscriptionSource.iap.code,
      'subscription_product_id': productId,
    });
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _listening = false;
  }
}
