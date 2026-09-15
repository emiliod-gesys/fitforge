import 'package:flutter/material.dart';

import '../core/subscription/plan_upgrade.dart';
import '../core/theme/app_accent.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';

class PlanLimitBanner extends StatelessWidget {
  const PlanLimitBanner({
    super.key,
    required this.message,
    this.canUpgrade = false,
    this.emphasized = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  final String message;
  final bool canUpgrade;
  final bool emphasized;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final color = emphasized ? AppColors.error : context.accentColor;
    final child = Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: color, height: 1.35),
            ),
          ),
          if (canUpgrade) ...[
            const SizedBox(width: 8),
            Text(
              context.l10n.subscriptionSeePlans,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: color.withValues(alpha: 0.12),
      child: SizedBox(
        width: double.infinity,
        child: canUpgrade
            ? InkWell(onTap: () => PlanUpgrade.openPlan(context), child: child)
            : child,
      ),
    );
  }
}
