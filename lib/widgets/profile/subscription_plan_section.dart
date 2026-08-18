import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/subscription/billing_products.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../services/billing_service.dart';
import '../ff/ff_list_row.dart';
import '../ff/ff_surface.dart';

class SubscriptionPlanSection extends ConsumerStatefulWidget {
  final UserProfile? profile;

  const SubscriptionPlanSection({super.key, required this.profile});

  @override
  ConsumerState<SubscriptionPlanSection> createState() =>
      _SubscriptionPlanSectionState();
}

class _SubscriptionPlanSectionState
    extends ConsumerState<SubscriptionPlanSection> {
  bool _busy = false;

  Future<void> _run(Future<BillingFlowResult> Function() action) async {
    if (_busy) return;
    final l10n = context.l10n;
    if (!BillingService.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.subscriptionNotAvailable)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await action();
      if (!mounted) return;
      ref.invalidate(profileProvider);
      final message = switch (result.outcome) {
        BillingOutcome.success => l10n.subscriptionPurchaseSuccess,
        BillingOutcome.restored => l10n.subscriptionRestoreSuccess,
        BillingOutcome.none => l10n.subscriptionRestoreNone,
        BillingOutcome.cancelled => l10n.onboardingPlanPurchaseCancelled,
        BillingOutcome.unavailable => l10n.subscriptionNotAvailable,
        BillingOutcome.pending => null,
        BillingOutcome.error => l10n.subscriptionPurchaseFailed,
      };
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = widget.profile;
    final tier = profile?.subscriptionTier ?? SubscriptionTier.free;
    final current = l10n.subscriptionTierLabel(tier) ?? l10n.onboardingPlanFree;
    final courtesy = profile?.isCourtesySubscription == true;

    return ListView(
      padding: AppTokens.pagePaddingWithBottomInset(context),
      children: [
        Text(
          l10n.subscriptionCurrentPlan,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          courtesy ? '$current · ${l10n.subscriptionCourtesy}' : current,
          style: TextStyle(
            color: context.accentColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.subscriptionManageHint,
          style: const TextStyle(color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 20),
        FfSurface(
          child: Column(
            children: [
              if (!courtesy &&
                  BillingProducts.rank(tier) <
                  BillingProducts.rank(SubscriptionTier.gymrat))
                FfListRow(
                  icon: Icons.workspace_premium_outlined,
                  title: l10n.subscriptionUpgradeGymrat,
                  subtitle: '\$4.99${l10n.onboardingPlanPerMonth}',
                  onTap: _busy
                      ? null
                      : () => _run(
                            () => ref
                                .read(billingServiceProvider)
                                .purchase(SubscriptionTier.gymrat),
                          ),
                ),
              if (!courtesy &&
                  BillingProducts.rank(tier) <
                  BillingProducts.rank(SubscriptionTier.gymratPro))
                FfListRow(
                  icon: Icons.star_outline,
                  title: l10n.subscriptionUpgradePro,
                  subtitle: '\$9.99${l10n.onboardingPlanPerMonth}',
                  onTap: _busy
                      ? null
                      : () => _run(
                            () => ref
                                .read(billingServiceProvider)
                                .purchase(SubscriptionTier.gymratPro),
                          ),
                ),
              FfListRow(
                icon: Icons.restore,
                title: l10n.subscriptionRestore,
                showChevron: false,
                onTap: _busy
                    ? null
                    : () => _run(() => ref.read(billingServiceProvider).restore()),
              ),
            ],
          ),
        ),
        if (_busy) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}
