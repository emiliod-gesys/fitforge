import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';
import '../services/exercise_report_service.dart';

class ExerciseReportSheet {
  static Future<void> show(
    BuildContext context, {
    required String exerciseId,
    required String exerciseName,
    required ExerciseReportService service,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ExerciseReportSheetBody(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        service: service,
      ),
    );
  }
}

class _ExerciseReportSheetBody extends StatefulWidget {
  final String exerciseId;
  final String exerciseName;
  final ExerciseReportService service;

  const _ExerciseReportSheetBody({
    required this.exerciseId,
    required this.exerciseName,
    required this.service,
  });

  @override
  State<_ExerciseReportSheetBody> createState() => _ExerciseReportSheetBodyState();
}

class _ExerciseReportSheetBodyState extends State<_ExerciseReportSheetBody> {
  ExerciseReportCategory? _category;
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _categoryLabel(AppLocalizations l10n, ExerciseReportCategory category) {
    return switch (category) {
      ExerciseReportCategory.wrongMetrics => l10n.exerciseReportWrongMetrics,
      ExerciseReportCategory.wrongGif => l10n.exerciseReportWrongGif,
      ExerciseReportCategory.wrongName => l10n.exerciseReportWrongName,
      ExerciseReportCategory.wrongMuscles => l10n.exerciseReportWrongMuscles,
      ExerciseReportCategory.other => l10n.exerciseReportOther,
    };
  }

  Future<void> _submit() async {
    final category = _category;
    if (category == null || _submitting) return;

    setState(() => _submitting = true);
    try {
      await widget.service.submit(
        exerciseId: widget.exerciseId,
        exerciseName: widget.exerciseName,
        category: category,
        notes: _notesController.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.exerciseReportThanks)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorGeneric('$e'))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          Text(
            l10n.exerciseReportTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            widget.exerciseName,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...ExerciseReportCategory.values.map(
            (category) => RadioListTile<ExerciseReportCategory>(
              value: category,
              groupValue: _category,
              activeColor: AppColors.orange,
              title: Text(_categoryLabel(l10n, category)),
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _category = value),
            ),
          ),
          TextField(
            controller: _notesController,
            enabled: !_submitting,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.exerciseReportNotes,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _category == null || _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n.exerciseReportSubmit),
          ),
        ],
      ),
    );
  }
}
