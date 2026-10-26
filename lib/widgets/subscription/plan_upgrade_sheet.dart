import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_scaffold.dart';
import '../../core/subscription/billing_products.dart';
import '../../core/subscription/store_subscriptions.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../services/billing_service.dart';
import '../ff/ff_button.dart';
import 'plan_offer_card.dart';

/// Popup de planes. No cambia de ruta: la pantalla de debajo sigue abierta.
class PlanUpgradeSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final height = MediaQuery.sizeOf(ctx).height * 0.92;
        return SizedBox(
          height: height,
          child: const PlanOfferBody(presentedAsSheet: true),
        );
      },
    );
  }
}

/// Tarjetas de plan con beneficios, compra, restaurar y gestión en tienda.
class PlanOfferBody extends ConsumerStatefulWidget {
  final UserProfile? fallbackProfile;
  final bool presentedAsSheet;

  const PlanOfferBody({
    super.key,
    this.fallbackProfile,
    this.presentedAsSheet = false,
  });

  @override
  ConsumerState<PlanOfferBody> createState() => _PlanOfferBodyState();
}

class _PlanOfferBodyState extends ConsumerState<PlanOfferBody> {
  SubscriptionTier? _knownTier;
  SubscriptionTier _selected = SubscriptionTier.gymratPro;
  bool _busy = false;
  bool _revealed = false;
  bool _revealScheduled = false;
  String? _notice;

  final _cardKeys = <SubscriptionTier, GlobalKey>{
    for (final tier in SubscriptionTier.values) tier: GlobalKey(),
  };

  SubscriptionTier _preferred(SubscriptionTier current) {
    if (BillingProducts.rank(current) <
        BillingProducts.rank(SubscriptionTier.gymratPro)) {
      return SubscriptionTier.gymratPro;
    }
    return current;
  }

  bool _canBuy(UserProfile? profile, SubscriptionTier current) {
    if (profile?.hidesStoreUpgrades == true) return false;
    return BillingProducts.rank(_selected) > BillingProducts.rank(current);
  }

  void _revealSelected() {
    if (_revealed || _revealScheduled || !widget.presentedAsSheet) return;
    _revealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealScheduled = false;
      if (!mounted || _revealed) return;
      final target = _cardKeys[_selected]?.currentContext;
      if (target == null || !target.mounted) return;
      _revealed = true;
      Scrollable.ensureVisible(
        target,
        alignment: 0.05,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String? _messageFor(AppLocalizations l10n, BillingFlowResult result) {
    return switch (result.outcome) {
      BillingOutcome.success => l10n.subscriptionPurchaseSuccess,
      BillingOutcome.restored => l10n.subscriptionRestoreSuccess,
      BillingOutcome.none => l10n.subscriptionRestoreNone,
      BillingOutcome.cancelled => l10n.onboardingPlanPurchaseCancelled,
      BillingOutcome.unavailable => l10n.subscriptionNotAvailable,
      BillingOutcome.pending => null,
      BillingOutcome.error => l10n.subscriptionPurchaseFailed,
    };
  }

  void _showMessage(String message, {bool behindSheet = false}) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (behindSheet || !mounted) {
      messenger?.showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    setState(() => _notice = message);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _purchase() async {
    if (_busy) return;
    final l10n = context.l10n;
    if (!BillingService.isSupported) {
      setState(() => _notice = l10n.subscriptionNotAvailable);
      return;
    }

    final billing = ref.read(billingServiceProvider);
    final container = ProviderScope.containerOf(context);
    final tier = _selected;
    final asSheet = widget.presentedAsSheet;
    setState(() {
      _busy = true;
      _notice = null;
    });

    // Play dibuja su hoja sobre la actividad. Si este panel sigue abierto,
    // el flujo vuelve al instante y el aviso queda tapado.
    if (asSheet) {
      Navigator.of(context).pop();
      await Future<void>.delayed(const Duration(milliseconds: 280));
    }

    try {
      final result = await billing.purchase(tier);
      container.invalidate(profileProvider);
      final message = _messageFor(l10n, result);
      if (message != null) {
        _showMessage(message, behindSheet: asSheet);
      }
    } catch (_) {
      _showMessage(l10n.subscriptionPurchaseFailed, behindSheet: asSheet);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    final l10n = context.l10n;
    if (!BillingService.isSupported) {
      setState(() => _notice = l10n.subscriptionNotAvailable);
      return;
    }
    final billing = ref.read(billingServiceProvider);
    final container = ProviderScope.containerOf(context);
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final result = await billing.restore();
      if (!mounted) return;
      container.invalidate(profileProvider);
      final message = _messageFor(l10n, result);
      if (message != null) _showMessage(message);
    } catch (_) {
      if (mounted) _showMessage(l10n.subscriptionPurchaseFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openStoreSubscriptions() async {
    final l10n = context.l10n;
    final opened = await StoreSubscriptions.openManage();
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.subscriptionManageFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = context.accentColor;
    final profile = ref.watch(profileProvider).value ?? widget.fallbackProfile;
    final current = profile?.subscriptionTier ?? SubscriptionTier.free;
    if (_knownTier != current) {
      _knownTier = current;
      _selected = _preferred(current);
    }
    _revealSelected();

    final canBuy = _canBuy(profile, current);
    final sourceLabel = profile?.isReferralSubscription == true
        ? l10n.subscriptionReferral
        : profile?.isCourtesySubscription == true
            ? l10n.subscriptionCourtesy
            : null;
    final currentName =
        l10n.subscriptionTierLabel(current) ?? l10n.onboardingPlanFree;
    final buyLabel = switch (_selected) {
      SubscriptionTier.gymrat => l10n.subscriptionUpgradeGymrat,
      SubscriptionTier.gymratPro => l10n.subscriptionUpgradePro,
      SubscriptionTier.free => l10n.onboardingPlanSelectFree,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.presentedAsSheet) ...[
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  l10n.onboardingPlanTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
              ),
              if (widget.presentedAsSheet)
                IconButton(
                  tooltip: l10n.close,
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                )
              else
                const SizedBox(width: 40),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.planUpgradeSheetSubtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  sourceLabel != null
                      ? '${l10n.subscriptionCurrentPlan}: $currentName · $sourceLabel'
                      : '${l10n.subscriptionCurrentPlan}: $currentName',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                for (final tier in SubscriptionTier.values) ...[
                  KeyedSubtree(
                    key: _cardKeys[tier],
                    child: PlanOfferCard(
                      accent: accent,
                      selected: _selected == tier,
                      onTap:
                          _busy ? null : () => setState(() => _selected = tier),
                      name: planOfferName(l10n, tier),
                      price: planOfferPrice(l10n, tier),
                      period: l10n.onboardingPlanPerMonth,
                      originalPrice: planOfferCompareAt(tier),
                      badge: tier == current
                          ? l10n.planUpgradeCurrentBadge
                          : switch (tier) {
                              SubscriptionTier.gymrat =>
                                l10n.onboardingPlanDiscount,
                              SubscriptionTier.gymratPro =>
                                l10n.onboardingPlanRecommended,
                              SubscriptionTier.free => null,
                            },
                      highlighted: tier == SubscriptionTier.gymratPro,
                      benefits: planOfferBenefits(l10n, tier),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 4),
                Text(
                  StoreSubscriptions.isIos
                      ? l10n.subscriptionManageHintIos
                      : l10n.subscriptionManageHintAndroid,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.4,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_notice != null) ...[
                Text(
                  _notice!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (canBuy)
                FfButton(
                  label: buyLabel,
                  expanded: true,
                  loading: _busy,
                  onPressed: _purchase,
                ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _busy ? null : _restore,
                      child: Text(
                        l10n.subscriptionRestore,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (StoreSubscriptions.canOpenManage)
                    Expanded(
                      child: TextButton(
                        onPressed: _busy ? null : _openStoreSubscriptions,
                        child: Text(
                          StoreSubscriptions.isIos
                              ? l10n.subscriptionManageInStoreIos
                              : l10n.subscriptionManageInStoreAndroid,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
