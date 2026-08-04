import 'package:flutter/material.dart';
import '../core/theme/app_accent.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';

class RestTimeSelector extends StatelessWidget {
  final int selectedSeconds;
  final ValueChanged<int> onChanged;
  final bool compact;

  const RestTimeSelector({
    super.key,
    required this.selectedSeconds,
    required this.onChanged,
    this.compact = true,
  });

  static const _presets = [30, 60, 90, 120, 180];

  Future<void> _pickCustom(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: selectedSeconds.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.customRest),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.secondsLabel,
            suffixText: 's',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v != null && v > 0 && v <= 600) Navigator.pop(ctx, v);
            },
            child: Text(l10n.apply),
          ),
        ],
      ),
    );
    if (result != null) onChanged(result);
  }

  Future<void> _openSheet(BuildContext context) async {
    final l10n = context.l10n;
    final isPreset = _presets.contains(selectedSeconds);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.rest,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._presets.map(
                      (s) => ChoiceChip(
                        label: Text(l10n.restSeconds(s)),
                        selected: selectedSeconds == s,
                        onSelected: (_) {
                          onChanged(s);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                    ChoiceChip(
                      label: Text(
                        isPreset
                            ? l10n.customRestChip
                            : '${l10n.restSeconds(selectedSeconds)} ✎',
                      ),
                      selected: !isPreset,
                      onSelected: (_) async {
                        Navigator.pop(ctx);
                        await _pickCustom(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!compact) {
      final isPreset = _presets.contains(selectedSeconds);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.rest, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._presets.map(
                (s) => ChoiceChip(
                  label: Text(l10n.restSeconds(s)),
                  selected: selectedSeconds == s,
                  onSelected: (_) => onChanged(s),
                ),
              ),
              ChoiceChip(
                label: Text(
                  isPreset ? l10n.customRestChip : '${l10n.restSeconds(selectedSeconds)} ✎',
                ),
                selected: !isPreset,
                onSelected: (_) => _pickCustom(context),
              ),
            ],
          ),
        ],
      );
    }

    return Material(
      color: AppColors.cardElevated,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openSheet(context),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 18, color: context.accentColor),
              const SizedBox(width: 6),
              Text(
                l10n.restPeriod(selectedSeconds),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more,
                size: 18,
                color: AppColors.textMuted.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
