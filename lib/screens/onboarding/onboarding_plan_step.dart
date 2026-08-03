import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/profile.dart';

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
        _PlanCard(
          accent: accent,
          selected: selected == SubscriptionTier.free,
          onTap: () => onSelected(SubscriptionTier.free),
          name: l10n.onboardingPlanFree,
          price: l10n.onboardingPlanFreePrice,
          period: l10n.onboardingPlanPerMonth,
          benefits: [
            l10n.onboardingPlanBenefitFree1,
            l10n.onboardingPlanBenefitFree2,
            l10n.onboardingPlanBenefitFree3,
          ],
        ),
        const SizedBox(height: 12),
        _PlanCard(
          accent: accent,
          selected: selected == SubscriptionTier.gymrat,
          onTap: () => onSelected(SubscriptionTier.gymrat),
          name: 'Gymrat',
          price: r'$4.99',
          period: l10n.onboardingPlanPerMonth,
          originalPrice: r'$7.99',
          badge: l10n.onboardingPlanDiscount,
          benefits: [
            l10n.onboardingPlanBenefitGymrat1,
            l10n.onboardingPlanBenefitGymrat2,
            l10n.onboardingPlanBenefitGymrat3,
            l10n.onboardingPlanBenefitGymrat4,
          ],
        ),
        const SizedBox(height: 12),
        _PlanCard(
          accent: accent,
          selected: selected == SubscriptionTier.gymratPro,
          onTap: () => onSelected(SubscriptionTier.gymratPro),
          name: 'Gymrat Pro',
          price: r'$9.99',
          period: l10n.onboardingPlanPerMonth,
          originalPrice: r'$11.99',
          badge: l10n.onboardingPlanRecommended,
          highlighted: true,
          benefits: [
            l10n.onboardingPlanBenefitPro1,
            l10n.onboardingPlanBenefitPro2,
            l10n.onboardingPlanBenefitPro3,
            l10n.onboardingPlanBenefitPro4,
          ],
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  final String name;
  final String price;
  final String period;
  final String? originalPrice;
  final String? badge;
  final bool highlighted;
  final List<String> benefits;

  const _PlanCard({
    required this.accent,
    required this.selected,
    required this.onTap,
    required this.name,
    required this.price,
    required this.period,
    this.originalPrice,
    this.badge,
    this.highlighted = false,
    required this.benefits,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? accent
        : highlighted
            ? accent.withValues(alpha: 0.45)
            : AppColors.border.withValues(alpha: 0.7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? [
                      accent.withValues(alpha: 0.22),
                      AppColors.cardElevated,
                    ]
                  : highlighted
                      ? [
                          accent.withValues(alpha: 0.10),
                          AppColors.card,
                        ]
                      : [
                          AppColors.cardElevated,
                          AppColors.card,
                        ],
            ),
            border: Border.all(color: borderColor, width: selected ? 1.8 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: accent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  if (selected) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle, color: accent, size: 22),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (originalPrice != null) ...[
                    Text(
                      originalPrice!,
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.85),
                        fontSize: 16,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    price,
                    style: TextStyle(
                      color: accent,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      period,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...benefits.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_rounded, size: 18, color: accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b,
                          style: const TextStyle(fontSize: 13.5, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
