import 'package:flutter/material.dart';

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
    final controller = TextEditingController(text: selectedSeconds.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descanso personalizado'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Segundos',
            suffixText: 's',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v != null && v > 0 && v <= 600) Navigator.pop(ctx, v);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final isPreset = _presets.contains(selectedSeconds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Descanso', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._presets.map(
              (s) => ChoiceChip(
                label: Text('${s}s'),
                selected: selectedSeconds == s,
                onSelected: (_) => onChanged(s),
              ),
            ),
            ChoiceChip(
              label: Text(isPreset ? 'Personalizado' : '${selectedSeconds}s ✎'),
              selected: !isPreset,
              onSelected: (_) => _pickCustom(context),
            ),
          ],
        ),
      ],
    );
  }
}
