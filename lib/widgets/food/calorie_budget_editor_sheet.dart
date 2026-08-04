import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/bmr_calculator.dart';
import '../../core/utils/calorie_budget_adjustment.dart';
import '../../core/utils/daily_nutrition_budget.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/body_metric.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../ff/ff_button.dart';

class CalorieBudgetEditorSheet {
  static Future<void> show(
    BuildContext context, {
    required UserProfile? profile,
    required Map<String, BodyMetricSnapshot>? bodyMetrics,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CalorieBudgetEditorBody(
        profile: profile,
        bodyMetrics: bodyMetrics,
        onSaved: onSaved,
      ),
    );
  }
}

class _CalorieBudgetEditorBody extends ConsumerStatefulWidget {
  final UserProfile? profile;
  final Map<String, BodyMetricSnapshot>? bodyMetrics;
  final VoidCallback onSaved;

  const _CalorieBudgetEditorBody({
    required this.profile,
    required this.bodyMetrics,
    required this.onSaved,
  });

  @override
  ConsumerState<_CalorieBudgetEditorBody> createState() => _CalorieBudgetEditorBodyState();
}

class _CalorieBudgetEditorBodyState extends ConsumerState<_CalorieBudgetEditorBody> {
  late int _adjustmentPct;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final goal = widget.profile?.fitnessGoal;
    _adjustmentPct = CalorieBudgetAdjustment.resolvedPercent(
      goal,
      widget.profile?.calorieAdjustmentPct,
    );
  }

  int? get _tdee {
    final bmr = BmrCalculator.calculate(
      profile: widget.profile,
      snapshots: widget.bodyMetrics,
    );
    if (bmr == null) return null;
    return DailyNutritionBudget.computeTdee(
      bmr: bmr,
      activityLevel: widget.profile?.activityLevel ?? DailyActivityLevel.moderate,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final defaultPct = CalorieBudgetAdjustment.defaultPercent(widget.profile?.fitnessGoal);
      final value = _adjustmentPct == defaultPct ? null : _adjustmentPct;
      await ref.read(profileServiceProvider).updateProfile({
        'calorie_adjustment_pct': value,
      });
      ref.invalidate(profileProvider);
      ref.invalidate(dailyNutritionProvider);
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color _modeColor(CalorieGoalMode mode) => switch (mode) {
        CalorieGoalMode.deficit => const Color(0xFF64B5F6),
        CalorieGoalMode.surplus => const Color(0xFFFFB74D),
        CalorieGoalMode.maintenance => context.accentColor,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = context.accentColor;
    final goal = widget.profile?.fitnessGoal;
    final goalLabel = l10n.goalLabel(goal);
    final mode = CalorieBudgetAdjustment.goalMode(goal);
    final modeColor = _modeColor(mode);
    final tdee = _tdee;
    final numberFmt = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());

    if (tdee == null) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 16),
            Text(l10n.calorieBudgetEditorTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(
              l10n.calorieBudgetBmrRequired,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            FfButton(label: l10n.close, onPressed: () => Navigator.pop(context)),
          ],
        ),
      );
    }

    final spec = CalorieBudgetAdjustment.displaySliderSpec(goal);
    final display = CalorieBudgetAdjustment.displayIntensity(goal, _adjustmentPct)
        .clamp(spec.min, spec.max);
    _adjustmentPct = CalorieBudgetAdjustment.adjustmentFromDisplay(goal, display);
    final baseGoal = CalorieBudgetAdjustment.goalFromTdee(tdee, _adjustmentPct);
    final absKcal = CalorieBudgetAdjustment.absoluteKcal(tdee, _adjustmentPct);
    final warning = CalorieBudgetAdjustment.evaluate(
      goal: goal,
      tdee: tdee,
      adjustmentPct: _adjustmentPct,
    );
    final warningText = warning != null
        ? l10n.calorieBudgetWarningMessage(warning, kcal: absKcal)
        : null;
    final defaultPct = CalorieBudgetAdjustment.defaultPercent(goal);
    final defaultDisplay = CalorieBudgetAdjustment.displayIntensity(goal, defaultPct);
    final intensityLabel = l10n.calorieBudgetIntensityLabel(mode, display);
    final endpoints = l10n.calorieBudgetSliderEndpoints(mode);
    final kcalDeltaLabel = mode == CalorieGoalMode.maintenance
        ? l10n.calorieBudgetMaintenanceDelta(
            _adjustmentPct == 0
                ? '0'
                : _adjustmentPct > 0
                    ? '+$absKcal'
                    : '−$absKcal',
          )
        : l10n.calorieBudgetKcalDeltaLabel(mode, absKcal);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 16),
            Text(
              l10n.calorieBudgetEditorTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _GoalHero(
              goalLabel: goalLabel,
              modeLabel: l10n.fitnessGoalCalorieModeLabel(goalLabel),
              modeColor: modeColor,
              currentGoalCaption: l10n.calorieBudgetCurrentGoal,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.calorieBudgetEditorSubtitle(mode),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(AppTokens.space16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppTokens.borderRadiusLg,
                border: Border.all(color: modeColor.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  _BudgetRow(
                    label: l10n.calorieBudgetTdeeLabel,
                    value: '${numberFmt.format(tdee)} kcal',
                  ),
                  if (mode != CalorieGoalMode.maintenance) ...[
                    const SizedBox(height: 12),
                    _BudgetRow(
                      label: l10n.calorieBudgetModeLabel(mode),
                      value: intensityLabel,
                      valueColor: modeColor,
                      subtitle: kcalDeltaLabel,
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: AppColors.border.withValues(alpha: 0.6), height: 1),
                  ),
                  _BudgetRow(
                    label: l10n.calorieBudgetResultLabel,
                    value: '${numberFmt.format(baseGoal)} kcal',
                    emphasized: true,
                    valueColor: accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.calorieBudgetSliderTitle(mode),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  endpoints.$1,
                  style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.85), fontSize: 11),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: modeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: modeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    intensityLabel,
                    style: TextStyle(color: modeColor, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                Text(
                  endpoints.$2,
                  style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.85), fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: modeColor,
                inactiveTrackColor: AppColors.border,
                thumbColor: modeColor,
                overlayColor: modeColor.withValues(alpha: 0.15),
              ),
              child: Slider(
                min: spec.min.toDouble(),
                max: spec.max.toDouble(),
                divisions: spec.divisions,
                value: display.toDouble(),
                label: intensityLabel,
                onChanged: (v) => setState(() {
                  _adjustmentPct = CalorieBudgetAdjustment.adjustmentFromDisplay(goal, v.round());
                }),
              ),
            ),
            Center(
              child: Text(
                kcalDeltaLabel,
                style: TextStyle(color: modeColor.withValues(alpha: 0.9), fontSize: 12),
              ),
            ),
            if (warningText != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.12),
                  borderRadius: AppTokens.borderRadiusMd,
                  border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.45)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Color(0xFFFFB74D)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        warningText,
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(
                () => _adjustmentPct = defaultPct,
              ),
              child: Text(
                l10n.calorieBudgetResetRecommended(
                  l10n.calorieBudgetIntensityLabel(mode, defaultDisplay),
                ),
                style: TextStyle(color: accent.withValues(alpha: 0.9)),
              ),
            ),
            const SizedBox(height: 8),
            FfButton(
              label: l10n.calorieBudgetSave,
              loading: _saving,
              expanded: true,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalHero extends StatelessWidget {
  final String goalLabel;
  final String modeLabel;
  final Color modeColor;
  final String currentGoalCaption;

  const _GoalHero({
    required this.goalLabel,
    required this.modeLabel,
    required this.modeColor,
    required this.currentGoalCaption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            modeColor.withValues(alpha: 0.22),
            AppColors.card,
          ],
        ),
        borderRadius: AppTokens.borderRadiusLg,
        border: Border.all(color: modeColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentGoalCaption,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            goalLabel,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: modeColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: modeColor.withValues(alpha: 0.45)),
            ),
            child: Text(
              modeLabel,
              style: TextStyle(
                color: modeColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final bool emphasized;
  final Color? valueColor;

  const _BudgetRow({
    required this.label,
    required this.value,
    this.subtitle,
    this.emphasized = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: emphasized ? 13 : 12,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
            fontSize: emphasized ? 22 : 15,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
