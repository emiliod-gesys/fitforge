import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/water_goal_calculator.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/water_entry.dart';
import '../../providers/app_providers.dart';

class WaterIntakeSection extends ConsumerStatefulWidget {
  final DateTime day;
  final List<WaterEntry> entries;
  final int goalMl;
  final bool goalFromMetrics;
  final VoidCallback onChanged;

  const WaterIntakeSection({
    super.key,
    required this.day,
    required this.entries,
    required this.goalMl,
    required this.goalFromMetrics,
    required this.onChanged,
  });

  @override
  ConsumerState<WaterIntakeSection> createState() => _WaterIntakeSectionState();
}

class _WaterIntakeSectionState extends ConsumerState<WaterIntakeSection> {
  static const _waterBlue = Color(0xFF5BB8F0);

  bool _busy = false;
  bool? _pendingFlOz;

  bool get _useFlOz =>
      _pendingFlOz ??
      (ref.watch(profileProvider).valueOrNull?.waterUseFlOz ?? false);

  Future<void> _setUseFlOz(bool value) async {
    if (_useFlOz == value) return;
    setState(() => _pendingFlOz = value);
    try {
      await ref.read(profileServiceProvider).updateProfile({
        'water_use_fl_oz': value,
      });
      ref.invalidate(profileProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _pendingFlOz = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorGeneric('$e'))),
      );
    }
  }

  int get _intakeMl =>
      widget.entries.fold<int>(0, (sum, e) => sum + e.amountMl);

  Future<void> _addAmount(int amountMl) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final day = widget.day;
      final now = DateTime.now();
      final loggedAt = DateTime(
        day.year,
        day.month,
        day.day,
        now.hour,
        now.minute,
        now.second,
      );
      await ref.read(waterLogServiceProvider).addGlass(
            loggedAt: loggedAt,
            amountMl: amountMl,
          );
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorGeneric('$e'))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addGlass() => _addAmount(WaterGoalCalculator.glassMl);

  Future<void> _showCustomAmountDialog() async {
    if (_busy) return;
    final useFlOz = _useFlOz;
    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) => _WaterCustomAmountDialog(useFlOz: useFlOz),
    );
    if (amount == null || !mounted) return;
    await _addAmount(amount);
  }

  Future<void> _undoLast() async {
    if (_busy || widget.entries.isEmpty) return;
    setState(() => _busy = true);
    try {
      final last = widget.entries.last;
      await ref.read(waterLogServiceProvider).deleteEntry(last.id);
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorGeneric('$e'))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final intake = _intakeMl;
    final goal = widget.goalMl;
    final progress = goal > 0 ? (intake / goal) : 0.0;
    final reached = intake >= goal && goal > 0;
    final glasses = WaterGoalCalculator.glassesTowardGoal(intake, goal);
    final accent = reached ? AppColors.success : _waterBlue;
    final useFlOz = _useFlOz;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_outlined, color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.foodWaterTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              _WaterUnitToggle(
                useFlOz: useFlOz,
                accent: accent,
                litersLabel: l10n.foodWaterUnitLiters,
                ozLabel: l10n.foodWaterUnitOz,
                onChanged: _setUseFlOz,
              ),
              if (widget.entries.isNotEmpty)
                IconButton(
                  tooltip: l10n.foodWaterUndo,
                  onPressed: _busy ? null : _undoLast,
                  icon: const Icon(Icons.undo_rounded, size: 20),
                  color: AppColors.textMuted,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                WaterGoalCalculator.formatVolume(intake, useFlOz: useFlOz),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: reached ? AppColors.success : AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.foodWaterOfGoal(
                  WaterGoalCalculator.formatVolume(goal, useFlOz: useFlOz),
                ),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.goalFromMetrics
                ? l10n.foodWaterGoalHint
                : l10n.foodWaterGoalFallbackHint,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.cardElevated,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.foodWaterGlassesLogged(glasses),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _addGlass,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded, size: 22),
              label: Text(
                l10n.foodWaterAddGlass(
                  WaterGoalCalculator.glassAmountLabel(useFlOz: useFlOz),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: _busy ? null : _showCustomAmountDialog,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.foodWaterAddCustom,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accent,
                  decoration: TextDecoration.underline,
                  decorationColor: accent.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterUnitToggle extends StatelessWidget {
  final bool useFlOz;
  final Color accent;
  final String litersLabel;
  final String ozLabel;
  final ValueChanged<bool> onChanged;

  const _WaterUnitToggle({
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
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnitChip(
            label: litersLabel,
            selected: !useFlOz,
            accent: accent,
            onTap: () => onChanged(false),
          ),
          _UnitChip(
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

class _UnitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _UnitChip({
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

class _WaterCustomAmountDialog extends StatefulWidget {
  final bool useFlOz;

  const _WaterCustomAmountDialog({required this.useFlOz});

  @override
  State<_WaterCustomAmountDialog> createState() => _WaterCustomAmountDialogState();
}

class _WaterCustomAmountDialogState extends State<_WaterCustomAmountDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final raw = _controller.text.trim().replaceAll(',', '.');
    if (widget.useFlOz) {
      final parsed = double.tryParse(raw);
      if (parsed == null || parsed < 0.1 || parsed > 169) {
        setState(() => _errorText = l10n.foodWaterCustomInvalidOz);
        return;
      }
      Navigator.pop(context, WaterGoalCalculator.flOzToMl(parsed));
      return;
    }

    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 1 || parsed > 5000) {
      setState(() => _errorText = l10n.foodWaterCustomInvalid);
      return;
    }
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final useFlOz = widget.useFlOz;
    return AlertDialog(
      title: Text(l10n.foodWaterCustomTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(decimal: useFlOz),
        inputFormatters: [
          if (useFlOz)
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
          else
            FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          hintText: useFlOz ? '8.5' : '250',
          suffixText: useFlOz ? l10n.foodWaterCustomHintOz : l10n.foodWaterCustomHint,
          errorText: _errorText,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.foodWaterCustomConfirm),
        ),
      ],
    );
  }
}
