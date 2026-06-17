import 'package:flutter/material.dart';
import '../l10n/l10n_extensions.dart';

class RestTimeSelector extends StatelessWidget {
  final int selectedSeconds;
  final ValueChanged<int> onChanged;

  const RestTimeSelector({
    super.key,
    required this.selectedSeconds,
    required this.onChanged,
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              label: Text(isPreset ? l10n.customRestChip : '${l10n.restSeconds(selectedSeconds)} ✎'),
              selected: !isPreset,
              onSelected: (_) => _pickCustom(context),
            ),
          ],
        ),
      ],
    );
  }
}
