import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../services/activity_log_service.dart';

class ManualActivitySheet {
  static Future<void> show(
    BuildContext context, {
    required ActivityLogService service,
    required DateTime day,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ManualActivitySheetBody(
        service: service,
        day: day,
        onSaved: onSaved,
      ),
    );
  }
}

class _ManualActivitySheetBody extends StatefulWidget {
  final ActivityLogService service;
  final DateTime day;
  final VoidCallback onSaved;

  const _ManualActivitySheetBody({
    required this.service,
    required this.day,
    required this.onSaved,
  });

  @override
  State<_ManualActivitySheetBody> createState() => _ManualActivitySheetBodyState();
}

class _ManualActivitySheetBodyState extends State<_ManualActivitySheetBody> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final l10n = context.l10n;
    final name = _nameController.text.trim();
    final calories = int.tryParse(_caloriesController.text.trim());

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.foodActivityNameRequired)),
      );
      return;
    }

    if (calories == null || calories < 1 || calories > 9999) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.foodActivityCaloriesInvalid)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final loggedAt = DateTime(
        widget.day.year,
        widget.day.month,
        widget.day.day,
        DateTime.now().hour,
        DateTime.now().minute,
      );
      await widget.service.addEntry(
        name: name,
        caloriesKcal: calories,
        loggedAt: loggedAt,
      );
      if (!mounted) return;
      widget.onSaved();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric('$e'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.foodActivityAdd,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.foodActivityAddHint,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.foodActivityName,
              hintText: l10n.foodActivityNameHint,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _caloriesController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.foodActivityCalories,
              hintText: l10n.foodActivityCaloriesHint,
              suffixText: 'kcal',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n.foodActivitySave),
          ),
        ],
      ),
    );
  }
}
