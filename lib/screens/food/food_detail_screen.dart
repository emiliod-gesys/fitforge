import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/food_serving_parser.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/food_entry.dart';
import '../../providers/app_providers.dart';
import '../../widgets/food/macro_progress_bar.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final FoodNutritionEstimate estimate;
  final MealType mealType;
  final DateTime day;
  final FoodEntrySource source;
  final bool manual;

  const FoodDetailScreen({
    super.key,
    required this.estimate,
    required this.mealType,
    required this.day,
    required this.source,
    this.manual = false,
  });

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  late final FoodNutritionEstimate _baseEstimate;
  late final TextEditingController _nameController;
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _fiberController;
  late final TextEditingController _amountController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _baseEstimate = widget.estimate;
    final e = widget.estimate;
    _nameController = TextEditingController(text: e.name);
    _amountController = TextEditingController(
      text: _formatAmount(e.referenceAmount),
    );
    _kcalController = TextEditingController(text: '${e.caloriesKcal}');
    _proteinController = TextEditingController(text: e.proteinG.toStringAsFixed(0));
    _carbsController = TextEditingController(text: e.carbsG.toStringAsFixed(0));
    _fatController = TextEditingController(text: e.fatG.toStringAsFixed(0));
    _fiberController = TextEditingController(text: e.fiberG.toStringAsFixed(0));
  }

  String _formatAmount(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double _parseDouble(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  void _applyScaledAmount(double amount) {
    if (amount <= 0) return;
    final scaled = _baseEstimate.scaledTo(amount);
    _kcalController.text = '${scaled.caloriesKcal}';
    _proteinController.text = scaled.proteinG.toStringAsFixed(1);
    _carbsController.text = scaled.carbsG.toStringAsFixed(1);
    _fatController.text = scaled.fatG.toStringAsFixed(1);
    _fiberController.text = scaled.fiberG.toStringAsFixed(1);
  }

  void _onAmountChanged(String text) {
    final amount = _parseDouble(text);
    if (amount <= 0) return;
    _applyScaledAmount(amount);
    setState(() {});
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final amount = _parseDouble(_amountController.text);
    final unit = _baseEstimate.amountUnit;
    final serving = amount > 0
        ? FoodServingParser.formatAmount(amount, unit)
        : _baseEstimate.servingDescription;

    setState(() => _saving = true);
    try {
      await ref.read(foodServiceProvider).addEntry(
            mealType: widget.mealType,
            name: name,
            brand: _baseEstimate.brand,
            caloriesKcal: int.tryParse(_kcalController.text) ?? 0,
            proteinG: _parseDouble(_proteinController.text),
            carbsG: _parseDouble(_carbsController.text),
            fatG: _parseDouble(_fatController.text),
            fiberG: _parseDouble(_fiberController.text),
            servingDescription: serving,
            source: widget.source,
            loggedAt: widget.day,
          );
      ref.invalidate(dailyNutritionProvider);
      ref.invalidate(foodEntriesProvider);
      if (mounted) {
        context.go('/food');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final protein = _parseDouble(_proteinController.text);
    final carbs = _parseDouble(_carbsController.text);
    final fat = _parseDouble(_fatController.text);
    final fiber = _parseDouble(_fiberController.text);
    final unit = _baseEstimate.amountUnit;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.foodDetailTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!widget.manual && widget.estimate.ingredients.isNotEmpty) ...[
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.cardElevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.restaurant, size: 64, color: AppColors.orange),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.foodNameLabel),
          ),
          if (_baseEstimate.brand != null) ...[
            const SizedBox(height: 8),
            Text(
              _baseEstimate.brand!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _onAmountChanged,
            decoration: InputDecoration(
              labelText: l10n.foodQuantityLabel(unit),
              suffixText: unit,
              helperText: widget.source == FoodEntrySource.barcode ? l10n.foodPer100gNote : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _kcalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.foodCaloriesLabel),
          ),
          const SizedBox(height: 16),
          MacroProgressBar(
            label: l10n.macroProtein,
            current: protein,
            target: protein > 0 ? protein : 1,
            color: const Color(0xFFE85D75),
          ),
          TextField(
            controller: _proteinController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: '${l10n.macroProtein} (g)'),
          ),
          const SizedBox(height: 12),
          MacroProgressBar(
            label: l10n.macroFat,
            current: fat,
            target: fat > 0 ? fat : 1,
            color: const Color(0xFFF5B942),
          ),
          TextField(
            controller: _fatController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: '${l10n.macroFat} (g)'),
          ),
          const SizedBox(height: 12),
          MacroProgressBar(
            label: l10n.macroCarbs,
            current: carbs,
            target: carbs > 0 ? carbs : 1,
            color: const Color(0xFF5BB8F0),
          ),
          TextField(
            controller: _carbsController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: '${l10n.macroCarbs} (g)'),
          ),
          const SizedBox(height: 12),
          MacroProgressBar(
            label: l10n.macroFiber,
            current: fiber,
            target: fiber > 0 ? fiber : 1,
            color: const Color(0xFF9E7B5A),
          ),
          TextField(
            controller: _fiberController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: '${l10n.macroFiber} (g)'),
          ),
          if (widget.estimate.ingredients.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.foodIngredients, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              widget.estimate.ingredients.join(', '),
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n.foodAddThis),
          ),
        ),
      ),
    );
  }
}
