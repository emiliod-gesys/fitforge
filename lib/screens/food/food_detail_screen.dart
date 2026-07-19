import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/food_serving_parser.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/food_entry.dart';
import '../../providers/app_providers.dart';
import '../../providers/onboarding_progress_provider.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../core/theme/app_accent.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final FoodNutritionEstimate estimate;
  final MealType mealType;
  final DateTime day;
  final FoodEntrySource source;
  final String? originalQuery;
  final List<int>? imageBytes;
  final bool onboardingMode;

  const FoodDetailScreen({
    super.key,
    required this.estimate,
    required this.mealType,
    required this.day,
    required this.source,
    this.originalQuery,
    this.imageBytes,
    this.onboardingMode = false,
  });

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  late FoodNutritionEstimate _baseEstimate;
  late double _amount;
  final _nameController = TextEditingController();
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
    _nameController.text = widget.estimate.name;
    _amountController.text = _formatAmount(_amount);
  }

  String _formatAmount(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  String _formatPortionGrams(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _correctionController.dispose();
    super.dispose();
  }

  double _parseDouble(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  void _onNameChanged(String text) {
    setState(() => _baseEstimate = _baseEstimate.copyWith(name: text));
  }

  void _onAmountChanged(String text) {
    final amount = _parseDouble(text);
    if (amount <= 0) return;
    setState(() => _amount = amount);
  }

  bool get _hasPhotoReference =>
      widget.imageBytes != null && widget.imageBytes!.isNotEmpty;

  void _openPhotoPreview() {
    final bytes = widget.imageBytes;
    if (bytes == null || bytes.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Image.memory(
                Uint8List.fromList(bytes),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reviseWithAi() async {
    final correction = _correctionController.text.trim();
    if (correction.isEmpty) return;

    setState(() => _revising = true);
    try {
      final profile = await ref.read(profileProvider.future);
      final estimate = await ref.read(aiCoachServiceProvider).reviseFoodEstimate(
            previous: _baseEstimate,
            correction: correction,
            imageBytes: widget.imageBytes,
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
        _nameController.text = estimate.name;
        _amountController.text = _formatAmount(_amount);
        _correctionController.clear();
      });
    } finally {
      if (mounted) setState(() => _revising = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _amount <= 0) return;

    final scaled = _scaled;
    final serving = FoodServingParser.formatAmount(_amount, _baseEstimate.amountUnit);

    setState(() => _saving = true);
    try {
      final entry = await ref.read(foodServiceProvider).addEntry(
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
      if (!mounted) return;
      if (widget.onboardingMode) {
        ref.read(onboardingProgressProvider.notifier).markFoodLogged(entry.id);
        context.go('/onboarding');
        return;
      }
      context.go('/food');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scaled = _scaled;
    final unit = _baseEstimate.amountUnit;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
            padding: EdgeInsets.fromLTRB(16, 16, 16, 96 + keyboardInset),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              if (_hasPhotoReference) ...[
                GestureDetector(
                  onTap: _openPhotoPreview,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(
                            Uint8List.fromList(widget.imageBytes!),
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black87, Colors.transparent],
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.photo_camera, size: 16, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l10n.foodPhotoReferenceCaption,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    l10n.foodPhotoTapToExpand,
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (_baseEstimate.ingredients.isNotEmpty) ...[
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(Icons.restaurant, size: 56, color: context.accentColor),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                onChanged: _onNameChanged,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: l10n.foodNameLabel,
                  hintText: l10n.foodNameHint,
                ),
              ),
              if (_baseEstimate.brand != null) ...[
                const SizedBox(height: 4),
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
              if (_scaled.ingredientPortions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.foodIngredients, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  l10n.foodIngredientBreakdownHint,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                ..._scaled.ingredientPortions.map(
                  (portion) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            portion.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          l10n.foodIngredientGrams(_formatPortionGrams(portion.gramsG)),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  l10n.foodIngredientTotalGrams(_formatPortionGrams(
                    _scaled.ingredientPortions.fold<double>(0, (sum, p) => sum + p.gramsG),
                  )),
                  style: TextStyle(
                    color: context.accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else if (_baseEstimate.ingredients.isNotEmpty) ...[
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
                  icon: Icon(Icons.auto_awesome, color: context.accentColor),
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
      bottomNavigationBar: AnimatedPadding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _saving || _amount <= 0 || _nameController.text.trim().isEmpty ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: context.accentColor,
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
              color: prominent ? context.accentColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
