import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/profile.dart';
import '../../widgets/subscription/plan_offer_card.dart';

class OnboardingPlanStep extends StatelessWidget {
  final AppLocalizations l10n;
  final Color accent;
  final SubscriptionTier selected;
  final ValueChanged<SubscriptionTier> onSelected;

  const OnboardingPlanStep({
    super.key,
    required this.l10n,
    required this.accent,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          l10n.onboardingPlanTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingPlanSubtitle,
          style: const TextStyle(color: AppColors.textMuted, height: 1.45),
        ),
        const SizedBox(height: 22),
        PlanOfferCard(
          accent: accent,
          selected: selected == SubscriptionTier.free,
          onTap: () => onSelected(SubscriptionTier.free),
          name: planOfferName(l10n, SubscriptionTier.free),
          price: planOfferPrice(l10n, SubscriptionTier.free),
          period: l10n.onboardingPlanPerMonth,
          benefits: planOfferBenefits(l10n, SubscriptionTier.free),
        ),
        const SizedBox(height: 12),
        PlanOfferCard(
          accent: accent,
          selected: selected == SubscriptionTier.gymrat,
          onTap: () => onSelected(SubscriptionTier.gymrat),
          name: planOfferName(l10n, SubscriptionTier.gymrat),
          price: planOfferPrice(l10n, SubscriptionTier.gymrat),
          period: l10n.onboardingPlanPerMonth,
          originalPrice: planOfferCompareAt(SubscriptionTier.gymrat),
          badge: l10n.onboardingPlanDiscount,
          benefits: planOfferBenefits(l10n, SubscriptionTier.gymrat),
        ),
        const SizedBox(height: 12),
        PlanOfferCard(
          accent: accent,
          selected: selected == SubscriptionTier.gymratPro,
          onTap: () => onSelected(SubscriptionTier.gymratPro),
          name: planOfferName(l10n, SubscriptionTier.gymratPro),
          price: planOfferPrice(l10n, SubscriptionTier.gymratPro),
          period: l10n.onboardingPlanPerMonth,
          originalPrice: planOfferCompareAt(SubscriptionTier.gymratPro),
          badge: l10n.onboardingPlanRecommended,
          highlighted: true,
          benefits: planOfferBenefits(l10n, SubscriptionTier.gymratPro),
        ),
      ],
    );
  }
}
