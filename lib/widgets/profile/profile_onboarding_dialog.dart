import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';

/// Formulario obligatorio de primer ingreso (no se puede cerrar sin completar).
class ProfileOnboardingDialog extends ConsumerStatefulWidget {
  const ProfileOnboardingDialog({super.key, required this.initialProfile});

  final UserProfile initialProfile;

  @override
  ConsumerState<ProfileOnboardingDialog> createState() => _ProfileOnboardingDialogState();
}

class _ProfileOnboardingDialogState extends ConsumerState<ProfileOnboardingDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  Gender? _gender;
  String _unitSystem = 'kg';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _nameController = TextEditingController(text: profile.displayName ?? '');
    _ageController = TextEditingController(text: profile.age?.toString() ?? '');
    _heightController = TextEditingController(
      text: profile.heightCm != null ? profile.heightCm!.toStringAsFixed(0) : '',
    );
    _unitSystem = profile.unitSystem;
    _gender = profile.gender;
    _weightController = TextEditingController(
      text: profile.bodyWeight != null
          ? UnitConverter.kgToDisplay(profile.bodyWeight!, _unitSystem).toStringAsFixed(1)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onUnitChanged(String unit) {
    final currentKg = _parseWeightKg();
    setState(() => _unitSystem = unit);
    if (currentKg != null) {
      _weightController.text = UnitConverter.kgToDisplay(currentKg, unit).toStringAsFixed(1);
    }
  }

  double? _parseWeightKg() {
    final display = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (display == null) return null;
    return UnitConverter.displayToKg(display, _unitSystem);
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.genderRequired)),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final age = int.parse(_ageController.text.trim());
    final heightCm = double.parse(_heightController.text.replaceAll(',', '.'));
    final weightKg = _parseWeightKg()!;

    setState(() => _saving = true);
    try {
      final profileService = ref.read(profileServiceProvider);
      await profileService.updateProfile({
        'display_name': name,
        'search_name': name.toLowerCase(),
        'age': age,
        'gender': _gender!.code,
        'height_cm': heightCm,
        'unit_system': _unitSystem,
      });
      await profileService.saveBodyMetric(
        type: 'weight',
        displayValue: UnitConverter.kgToDisplay(weightKg, _unitSystem),
        unitSystem: _unitSystem,
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

    return AlertDialog(
      title: Text(l10n.profileOnboardingTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.profileOnboardingSubtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.profileOnboardingNickname,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.displayNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.ageTitle,
                    suffixText: l10n.years,
                  ),
                  validator: (value) {
                    final age = int.tryParse(value?.trim() ?? '');
                    if (age == null || age < 13 || age >= 120) {
                      return l10n.ageInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.genderTitle,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Gender.values.map((gender) {
                    final selected = _gender == gender;
                    return ChoiceChip(
                      label: Text(l10n.genderLabel(gender)),
                      selected: selected,
                      onSelected: (_) => setState(() => _gender = gender),
                      selectedColor: context.accentColor.withValues(alpha: 0.25),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.heightTitle,
                    suffixText: 'cm',
                  ),
                  validator: (value) {
                    final height = double.tryParse(value?.replaceAll(',', '.') ?? '');
                    if (height == null || height < 50 || height > 280) {
                      return l10n.heightInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.unitSystem,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                _UnitToggle(
                  unitSystem: _unitSystem,
                  onChanged: _onUnitChanged,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.metricWeight,
                    suffixText: UnitConverter.massLabel(_unitSystem),
                  ),
                  validator: (value) {
                    final display = double.tryParse(value?.replaceAll(',', '.') ?? '');
                    if (display == null) return l10n.weightInvalid;
                    final kg = UnitConverter.displayToKg(display, _unitSystem);
                    if (kg < 20 || kg > 500) return l10n.weightInvalid;
                    return null;
                  },
                ),
              ],
            ),
          ),
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
              : Text(l10n.profileOnboardingContinue),
        ),
      ],
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.unitSystem, required this.onChanged});

  final String unitSystem;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _UnitChip(
            label: l10n.kilograms,
            selected: unitSystem == 'kg',
            onTap: () => onChanged('kg'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _UnitChip(
            label: l10n.pounds,
            selected: unitSystem == 'lb',
            onTap: () => onChanged('lb'),
          ),
        ),
      ],
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? context.accentColor.withValues(alpha: 0.2) : AppColors.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? context.accentColor : AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? context.accentColor : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
