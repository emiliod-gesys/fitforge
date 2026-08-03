import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/age_calculator.dart';
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
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  Gender? _gender;
  DateTime? _dateOfBirth;
  String _unitSystem = 'kg';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _nameController = TextEditingController(text: profile.displayName ?? '');
    _dateOfBirth = profile.dateOfBirth ??
        (profile.age != null ? AgeCalculator.estimateDateOfBirthFromAge(profile.age!) : null);
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

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 119, 1, 1),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: context.l10n.dateOfBirthTitle,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.genderRequired)),
      );
      return;
    }
    if (_dateOfBirth == null || !AgeCalculator.isValidDateOfBirth(_dateOfBirth!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dateOfBirthInvalid)),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final dob = _dateOfBirth!;
    final heightCm = double.parse(_heightController.text.replaceAll(',', '.'));
    final weightKg = _parseWeightKg()!;

    setState(() => _saving = true);
    try {
      final profileService = ref.read(profileServiceProvider);
      await profileService.updateProfile({
        'display_name': name,
        'search_name': name.toLowerCase(),
        'date_of_birth': AgeCalculator.toDateString(dob),
        'age': AgeCalculator.yearsFromDateOfBirth(dob),
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
    final age = _dateOfBirth != null ? AgeCalculator.yearsFromDateOfBirth(_dateOfBirth!) : null;
    final dateLabel = _dateOfBirth != null
        ? DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(_dateOfBirth!)
        : l10n.dateOfBirthHint;

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
                InkWell(
                  onTap: _pickDateOfBirth,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.dateOfBirthTitle,
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        color: _dateOfBirth != null ? null : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                if (age != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.dateOfBirthAgePreview(age),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
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
                    final h = double.tryParse(value?.replaceAll(',', '.') ?? '');
                    if (h == null || h < 50 || h > 280) return l10n.heightInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Text(l10n.unitSystem, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(l10n.kilograms),
                        selected: _unitSystem == 'kg',
                        onSelected: (_) => _onUnitChanged('kg'),
                        selectedColor: context.accentColor.withValues(alpha: 0.25),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(l10n.pounds),
                        selected: _unitSystem == 'lb',
                        onSelected: (_) => _onUnitChanged('lb'),
                        selectedColor: context.accentColor.withValues(alpha: 0.25),
                      ),
                    ),
                  ],
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
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.profileOnboardingContinue),
        ),
      ],
    );
  }
}
