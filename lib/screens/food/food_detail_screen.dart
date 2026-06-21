import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/food_serving_parser.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/food_entry.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_loading_indicator.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final FoodNutritionEstimate estimate;
  final MealType mealType;
  final DateTime day;
  final FoodEntrySource source;
  final String? originalQuery;

  const FoodDetailScreen({
    super.key,
    required this.estimate,
    required this.mealType,
    required this.day,
    required this.source,
    this.originalQuery,
  });

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  late FoodNutritionEstimate _baseEstimate;
  late double _amount;
  late String? _originalQuery;
  final _amountController = TextEditingController();
  final _correctionController = TextEditingController();
  bool _saving = false;
  bool _revising = false;

  FoodNutritionEstimate get _scaled => _baseEstimate.scaledTo(_amount);

  bool get _showAiCorrection =>
      widget.source == FoodEntrySource.quick ||
      widget.source == FoodEntrySource.aiText ||
      widget.source == FoodEntrySource.aiPhoto;

  @override
  void initState() {
    super.initState();
    _baseEstimate = widget.estimate;
    _amount = widget.estimate.referenceAmount;
    _originalQuery = widget.originalQuery;
    _amountController.text = _formatAmount(_amount);
  }

  String _formatAmount(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _correctionController.dispose();
    super.dispose();
  }

  double _parseDouble(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  void _onAmountChanged(String text) {
    final amount = _parseDouble(text);
    if (amount <= 0) return;
    setState(() => _amount = amount);
  }

  Future<void> _reviseWithAi() async {
    final correction = _correctionController.text.trim();
    if (correction.isEmpty) return;

    final query = _originalQuery != null && _originalQuery!.isNotEmpty
        ? '$_originalQuery. Corrección: $correction'
        : correction;

    setState(() => _revising = true);
    try {
      final profile = await ref.read(profileProvider.future);
      final estimate = await ref.read(aiCoachServiceProvider).estimateFoodFromText(
            query: query,
            profile: profile,
          );
      if (!mounted) return;
      if (estimate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.foodAiFailed)),
        );
        return;
      }
      setState(() {
        _baseEstimate = estimate;
        _amount = estimate.referenceAmount;
        _originalQuery = query;
        _amountController.text = _formatAmount(_amount);
        _correctionController.clear();
      });
    } finally {
      if (mounted) setState(() => _revising = false);
    }
  }

  Future<void> _save() async {
    final scaled = _scaled;
    final name = scaled.name.trim();
    if (name.isEmpty || _amount <= 0) return;

    final serving = FoodServingParser.formatAmount(_amount, _baseEstimate.amountUnit);

    setState(() => _saving = true);
    try {
      await ref.read(foodServiceProvider).addEntry(
            mealType: widget.mealType,
            name: name,
            brand: _baseEstimate.brand,
            caloriesKcal: scaled.caloriesKcal,
            proteinG: scaled.proteinG,
            carbsG: scaled.carbsG,
            fatG: scaled.fatG,
            fiberG: scaled.fiberG,
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
    final scaled = _scaled;
    final unit = _baseEstimate.amountUnit;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.foodDetailTitle),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_baseEstimate.ingredients.isNotEmpty) ...[
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.restaurant, size: 56, color: AppColors.orange),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                scaled.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (_baseEstimate.brand != null) ...[
                const SizedBox(height: 4),
                Text(
                  _baseEstimate.brand!,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: _onAmountChanged,
                decoration: InputDecoration(
                  labelText: l10n.foodQuantityLabel(unit),
                  suffixText: unit,
                  helperText: widget.source == FoodEntrySource.barcode
                      ? l10n.foodPer100gNote
                      : l10n.foodMacrosAutoHint,
                ),
              ),
              const SizedBox(height: 20),
              _NutrientCard(
                label: l10n.foodCaloriesLabel,
                value: '${scaled.caloriesKcal} kcal',
                prominent: true,
              ),
              const SizedBox(height: 12),
              _NutrientCard(
                label: l10n.macroProtein,
                value: '${scaled.proteinG.toStringAsFixed(1)} g',
              ),
              _NutrientCard(
                label: l10n.macroFat,
                value: '${scaled.fatG.toStringAsFixed(1)} g',
              ),
              _NutrientCard(
                label: l10n.macroCarbs,
                value: '${scaled.carbsG.toStringAsFixed(1)} g',
              ),
              _NutrientCard(
                label: l10n.macroFiber,
                value: '${scaled.fiberG.toStringAsFixed(1)} g',
              ),
              if (_baseEstimate.ingredients.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.foodIngredients, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  _baseEstimate.ingredients.join(', '),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
              if (_showAiCorrection) ...[
                const SizedBox(height: 24),
                Text(l10n.foodAiCorrectionHint, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _correctionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: l10n.foodAiCorrectionPlaceholder,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _revising ? null : _reviseWithAi,
                  icon: const Icon(Icons.auto_awesome, color: AppColors.orange),
                  label: Text(l10n.foodAiCorrectionAction),
                ),
              ],
            ],
          ),
          if (_revising)
            const ColoredBox(
              color: Colors.black54,
              child: Center(child: FitForgeLoadingIndicator(size: 72)),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving || _amount <= 0 ? null : _save,
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

class _NutrientCard extends StatelessWidget {
  final String label;
  final String value;
  final bool prominent;

  const _NutrientCard({
    required this.label,
    required this.value,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: prominent ? 14 : 13,
              fontWeight: prominent ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: prominent ? 18 : 15,
              color: prominent ? AppColors.orange : null,
            ),
          ),
        ],
      ),
    );
  }
}
