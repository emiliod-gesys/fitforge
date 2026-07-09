import 'package:flutter/material.dart';

import '../../core/theme/app_accent.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';

class SubscriptionTierLabel extends StatelessWidget {
  final SubscriptionTier tier;

  const SubscriptionTierLabel({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.subscriptionTierLabel(tier);
    if (label == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.accentColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
