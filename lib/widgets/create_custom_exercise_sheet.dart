import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../providers/app_providers.dart';

class CreateCustomExerciseSheet extends ConsumerStatefulWidget {
  const CreateCustomExerciseSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: const CreateCustomExerciseSheet(),
      ),
    );
  }

  @override
  ConsumerState<CreateCustomExerciseSheet> createState() => _CreateCustomExerciseSheetState();
}

class _CreateCustomExerciseSheetState extends ConsumerState<CreateCustomExerciseSheet> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  final _selectedMuscles = <String>{};
  XFile? _photo;
  bool _perArmWeight = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (file != null) setState(() => _photo = file);
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.customExerciseNameRequired)));
      return;
    }
    if (_selectedMuscles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.customExerciseMusclesRequired)));
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(customExerciseRepositoryProvider);
      await repo.create(
        name: name,
        muscles: _selectedMuscles.toList()..sort(),
        perArmWeight: _perArmWeight,
        photo: _photo,
      );
      repo.clearCache();
      ref.read(exerciseServiceProvider).clearCache();
      ref.invalidate(exercisesProvider);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.customExerciseSaved)));
    } on StateError catch (e) {
      if (!mounted) return;
      final message = e.message == 'max_custom_exercises'
          ? l10n.customExerciseLimitReached
          : l10n.errorGeneric(e.message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorGeneric('$e'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.createCustomExercise, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(l10n.customExercisePhoto, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.cardElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: _photo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_photo!.path), fit: BoxFit.cover),
                    )
                  : Center(
                      child: Icon(Icons.fitness_center, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.takePhoto),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.chooseFromGallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.customExerciseName),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.customExercisePerArmWeight),
            subtitle: Text(
              l10n.customExercisePerArmWeightHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            value: _perArmWeight,
            onChanged: _saving ? null : (v) => setState(() => _perArmWeight = v),
          ),
          const SizedBox(height: 16),
          Text(l10n.customExerciseMuscles, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.muscleGroups.map((muscle) {
              final selected = _selectedMuscles.contains(muscle);
              return FilterChip(
                label: Text(l10n.muscleLabel(muscle)),
                selected: selected,
                onSelected: _saving
                    ? null
                    : (_) {
                        setState(() {
                          if (selected) {
                            _selectedMuscles.remove(muscle);
                          } else {
                            _selectedMuscles.add(muscle);
                          }
                        });
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> openCreateCustomExerciseSheet(BuildContext context, WidgetRef ref) async {
  final created = await CreateCustomExerciseSheet.show(context);
  if (created == true) {
    ref.read(customExerciseRepositoryProvider).clearCache();
    ref.read(exerciseServiceProvider).clearCache();
    ref.invalidate(exercisesProvider);
  }
}
