import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/unit_converter.dart';
import '../../core/utils/water_goal_calculator.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/body_metric.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../ff/ff_button.dart';
import '../ff/ff_glass.dart';

class WaterBudgetEditorSheet {
  static Future<void> show(
    BuildContext context, {
    required UserProfile? profile,
    required Map<String, BodyMetricSnapshot>? bodyMetrics,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FfGlassSheetScaffold(
        child: _WaterBudgetEditorBody(
          profile: profile,
          bodyMetrics: bodyMetrics,
          onSaved: onSaved,
        ),
      ),
    );
  }
}

class _WaterBudgetEditorBody extends ConsumerStatefulWidget {
  final UserProfile? profile;
  final Map<String, BodyMetricSnapshot>? bodyMetrics;
  final VoidCallback onSaved;

  const _WaterBudgetEditorBody({
    required this.profile,
    required this.bodyMetrics,
    required this.onSaved,
  });

  @override
  ConsumerState<_WaterBudgetEditorBody> createState() =>
      _WaterBudgetEditorBodyState();
}

class _WaterBudgetEditorBodyState extends ConsumerState<_WaterBudgetEditorBody> {
  static const _waterBlue = Color(0xFF5BB8F0);

  late int _selectedMl;
  late bool _useFlOz;
  bool _saving = false;

  int get _suggestedMl => WaterGoalCalculator.suggestedGoalMl(
        profile: widget.profile,
        bodyMetrics: widget.bodyMetrics,
      );

  @override
  void initState() {
    super.initState();
    _useFlOz = UnitConverter.isLb(widget.profile?.unitSystem ?? 'kg');
    final suggested = WaterGoalCalculator.suggestedGoalMl(
      profile: widget.profile,
      bodyMetrics: widget.bodyMetrics,
    );
    final override = widget.profile?.waterGoalMl;
    _selectedMl = (override ?? suggested).clamp(
      WaterGoalCalculator.minCustomMl,
      WaterGoalCalculator.maxCustomMl,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final value = _selectedMl == _suggestedMl ? null : _selectedMl;
      await ref.read(profileServiceProvider).updateProfile({
        'water_goal_ml': value,
      });
      ref.invalidate(profileProvider);
      ref.invalidate(waterEntriesProvider);
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = context.accentColor;
    final suggested = _suggestedMl;
    final warning = WaterGoalCalculator.evaluate(
      selectedMl: _selectedMl,
      suggestedMl: suggested,
    );
    final warningText = warning == null
        ? null
        : l10n.waterGoalWarningMessage(warning);
    final useFlOz = _useFlOz;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.waterBudgetEditorTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                _WaterBudgetUnitToggle(
                  useFlOz: useFlOz,
                  accent: _waterBlue,
                  litersLabel: l10n.foodWaterUnitLiters,
                  ozLabel: l10n.foodWaterUnitOz,
                  onChanged: (value) => setState(() => _useFlOz = value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.waterBudgetEditorSubtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(AppTokens.space16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppTokens.borderRadiusLg,
                border: Border.all(color: _waterBlue.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.waterBudgetSuggestedLabel,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        WaterGoalCalculator.formatVolume(
                          suggested,
                          useFlOz: useFlOz,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.waterBudgetYourGoalLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        WaterGoalCalculator.formatVolume(
                          _selectedMl,
                          useFlOz: useFlOz,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.waterBudgetSliderTitle,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            Slider(
              value: _selectedMl.toDouble(),
              min: WaterGoalCalculator.minCustomMl.toDouble(),
              max: WaterGoalCalculator.maxCustomMl.toDouble(),
              divisions: (WaterGoalCalculator.maxCustomMl -
                      WaterGoalCalculator.minCustomMl) ~/
                  50,
              activeColor: _waterBlue,
              onChanged: (v) => setState(() {
                _selectedMl = (v / 50).round() * 50;
              }),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  WaterGoalCalculator.formatVolume(
                    WaterGoalCalculator.minCustomMl,
                    useFlOz: useFlOz,
                  ),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                Text(
                  WaterGoalCalculator.formatVolume(
                    WaterGoalCalculator.maxCustomMl,
                    useFlOz: useFlOz,
                  ),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (warningText != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        warningText,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _selectedMl = suggested),
              child: Text(l10n.waterBudgetResetRecommended),
            ),
            const SizedBox(height: 8),
            FfButton(
              label: l10n.waterBudgetSave,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterBudgetUnitToggle extends StatelessWidget {
  final bool useFlOz;
  final Color accent;
  final String litersLabel;
  final String ozLabel;
  final ValueChanged<bool> onChanged;

  const _WaterBudgetUnitToggle({
    required this.useFlOz,
    required this.accent,
    required this.litersLabel,
    required this.ozLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BudgetUnitChip(
            label: litersLabel,
            selected: !useFlOz,
            accent: accent,
            onTap: () => onChanged(false),
          ),
          _BudgetUnitChip(
            label: ozLabel,
            selected: useFlOz,
            accent: accent,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _BudgetUnitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _BudgetUnitChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.22) : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? accent : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
