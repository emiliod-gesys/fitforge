import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_accent.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';

/// Solicita actualizar el peso cuando el último registro supera 15 días.
class WeightUpdateDialog extends ConsumerStatefulWidget {
  const WeightUpdateDialog({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<WeightUpdateDialog> createState() => _WeightUpdateDialogState();
}

class _WeightUpdateDialogState extends ConsumerState<WeightUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final unit = widget.profile.unitSystem;
    final kg = widget.profile.bodyWeight;
    _weightController = TextEditingController(
      text: kg != null ? UnitConverter.kgToDisplay(kg, unit).toStringAsFixed(1) : '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final unit = widget.profile.unitSystem;
    final display = double.parse(_weightController.text.replaceAll(',', '.'));

    setState(() => _saving = true);
    try {
      await ref.read(profileServiceProvider).saveBodyMetric(
            type: 'weight',
            displayValue: display,
            unitSystem: unit,
          );

      ref.invalidate(profileProvider);
      ref.invalidate(bodyMetricSnapshotsProvider);
      ref.invalidate(dailyNutritionProvider);
      ref.invalidate(leaderboardProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unit = widget.profile.unitSystem;

    return AlertDialog(
      title: Text(l10n.weightUpdateTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.weightUpdateMessage,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.metricWeight,
                suffixText: UnitConverter.massLabel(unit),
              ),
              validator: (value) {
                final display = double.tryParse(value?.replaceAll(',', '.') ?? '');
                if (display == null) return l10n.weightInvalid;
                final kg = UnitConverter.displayToKg(display, unit);
                if (kg < 20 || kg > 500) return l10n.weightInvalid;
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: context.accentColor,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(l10n.weightUpdateSave),
        ),
      ],
    );
  }
}
