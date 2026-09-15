import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'billing_products.dart';

/// Enlaces de gestión de suscripción en la tienda del dispositivo.
abstract final class StoreSubscriptions {
  static bool get canOpenManage {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool get isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static Uri manageHttpsUri({TargetPlatform? platform}) {
    final resolved = platform ?? defaultTargetPlatform;
    if (resolved == TargetPlatform.iOS) {
      return Uri.parse('https://apps.apple.com/account/subscriptions');
    }
    return Uri.https(
      'play.google.com',
      '/store/account/subscriptions',
      {'package': BillingProducts.androidPackage},
    );
  }

  static Uri get _iosNativeManageUri =>
      Uri.parse('itms-apps://apps.apple.com/account/subscriptions');

  static Future<bool> openManage() async {
    if (!canOpenManage) return false;
    final uris = <Uri>[
      if (isIos) _iosNativeManageUri,
      manageHttpsUri(),
    ];
    for (final uri in uris) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (_) {}
    }
    return false;
  }
}
