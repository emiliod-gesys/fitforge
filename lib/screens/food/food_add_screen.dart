import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/food_entry.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/food/barcode_scanner_view.dart';

enum FoodAddMode { barcode, search, photo, quick }

class FoodAddScreen extends ConsumerStatefulWidget {
  final MealType mealType;
  final DateTime day;

  const FoodAddScreen({super.key, required this.mealType, required this.day});

  @override
  ConsumerState<FoodAddScreen> createState() => _FoodAddScreenState();
}

class _FoodAddScreenState extends ConsumerState<FoodAddScreen> {
  FoodAddMode _mode = FoodAddMode.search;
  final _filterController = TextEditingController();
  final _quickController = TextEditingController();
  bool _loading = false;
  List<FoodEntry> _recent = const [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _filterController.addListener(_loadRecent);
  }

  Future<void> _loadRecent() async {
    final recent = await ref.read(foodServiceProvider).getDistinctRecentFoods(
          query: _filterController.text,
        );
    if (mounted) setState(() => _recent = recent);
  }

  @override
  void dispose() {
    _filterController.dispose();
    _quickController.dispose();
    super.dispose();
  }

  String get _mealTitle => context.l10n.mealLabel(widget.mealType);

  void _openDetail(
    FoodNutritionEstimate estimate,
    FoodEntrySource source, {
    String? originalQuery,
  }) {
    context.push(
      '/food/detail',
      extra: {
        'estimate': estimate,
        'meal': widget.mealType,
        'day': widget.day,
        'source': source,
        if (originalQuery != null) 'originalQuery': originalQuery,
      },
    );
  }

  void _openFromEntry(FoodEntry entry) {
    _openDetail(FoodNutritionEstimate.fromEntry(entry), FoodEntrySource.search);
  }

  Future<void> _quickAddWithAi() async {
    final description = _quickController.text.trim();
    if (description.isEmpty) return;

    setState(() => _loading = true);
    try {
      final profile = await ref.read(profileProvider.future);
      final estimate = await ref.read(aiCoachServiceProvider).estimateFoodFromText(
            query: description,
            profile: profile,
          );
      if (!mounted) return;
      if (estimate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.foodAiFailed)),
        );
        return;
      }
      _openDetail(estimate, FoodEntrySource.quick, originalQuery: description);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image == null || !mounted) return;

    setState(() => _loading = true);
    try {
      final bytes = await image.readAsBytes();
      final profile = await ref.read(profileProvider.future);
      final estimate = await ref.read(aiCoachServiceProvider).estimateFoodFromImage(
            imageBytes: bytes,
            profile: profile,
          );
      if (!mounted) return;
      if (estimate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.foodAiFailed)),
        );
        return;
      }
      _openDetail(estimate, FoodEntrySource.aiPhoto);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _lookupBarcode(String code) async {
    setState(() => _loading = true);
    try {
      final estimate = await ref.read(openFoodFactsServiceProvider).lookupBarcode(code);
      if (!mounted) return;
      if (estimate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.foodBarcodeNotFound)),
        );
        return;
      }
      _openDetail(estimate, FoodEntrySource.barcode);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summaryAsync = ref.watch(dailyNutritionProvider);
    final mealEaten = summaryAsync.valueOrNull?.eatenForMeal(widget.mealType).caloriesKcal ?? 0;
    final mealGoal = summaryAsync.valueOrNull?.mealCalorieGoal(widget.mealType) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_mealTitle, style: const TextStyle(fontSize: 16)),
            Text(
              l10n.foodMealGoalPlaceholder(mealEaten, mealGoal),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ModeTabs(
                mode: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
              const SizedBox(height: 16),
              switch (_mode) {
                FoodAddMode.search => _SearchPane(
                    filterController: _filterController,
                    recent: _recent,
                    onSelect: _openFromEntry,
                  ),
                FoodAddMode.quick => _QuickAddPane(
                    controller: _quickController,
                    onSubmit: _quickAddWithAi,
                  ),
                FoodAddMode.photo => _PhotoPane(onTakePhoto: _pickPhoto),
                FoodAddMode.barcode => _BarcodePane(onDetected: _lookupBarcode),
              },
            ],
          ),
          if (_loading)
            const ColoredBox(
              color: Colors.black54,
              child: Center(child: FitForgeLoadingIndicator(size: 80)),
            ),
        ],
      ),
    );
  }
}

class _SearchPane extends StatelessWidget {
  final TextEditingController filterController;
  final List<FoodEntry> recent;
  final ValueChanged<FoodEntry> onSelect;

  const _SearchPane({
    required this.filterController,
    required this.recent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: filterController,
          decoration: InputDecoration(
            hintText: l10n.foodSearchHint,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.foodRecentSearches,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Text(l10n.foodNoRecent, style: const TextStyle(color: AppColors.textMuted)),
        ...recent.map(
          (entry) => _RecentFoodTile(entry: entry, onTap: () => onSelect(entry)),
        ),
      ],
    );
  }
}

class _RecentFoodTile extends StatelessWidget {
  final FoodEntry entry;
  final VoidCallback onTap;

  const _RecentFoodTile({required this.entry, required this.onTap});

  bool get _isAi =>
      entry.source == FoodEntrySource.aiPhoto ||
      entry.source == FoodEntrySource.aiText ||
      entry.source == FoodEntrySource.quick;

  @override
  Widget build(BuildContext context) {
    final serving = entry.servingDescription;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Row(
          children: [
            Expanded(child: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (_isAi) const Icon(Icons.auto_awesome, size: 16, color: AppColors.orange),
          ],
        ),
        subtitle: Text(
          '${entry.caloriesKcal} kcal${serving != null ? ', $serving' : ''}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle, color: AppColors.orange),
          onPressed: onTap,
        ),
      ),
    );
  }
}

class _QuickAddPane extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _QuickAddPane({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.foodQuickAddHint,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: l10n.foodQuickAddPlaceholder,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onSubmit,
          icon: const Icon(Icons.auto_awesome),
          label: Text(l10n.foodQuickAddAction),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}

class _PhotoPane extends StatelessWidget {
  final VoidCallback onTakePhoto;

  const _PhotoPane({required this.onTakePhoto});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.photo_camera_outlined, size: 64, color: AppColors.orange),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.foodPhotoHint,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onTakePhoto,
          icon: const Icon(Icons.camera_alt),
          label: Text(l10n.foodPhotoAction),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}

class _BarcodePane extends StatelessWidget {
  final ValueChanged<String> onDetected;

  const _BarcodePane({required this.onDetected});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.foodBarcodeHint,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        FoodBarcodeScannerView(onDetected: onDetected),
        const SizedBox(height: 12),
        Text(
          l10n.foodPer100gNote,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _ModeTabs extends StatelessWidget {
  final FoodAddMode mode;
  final ValueChanged<FoodAddMode> onChanged;

  const _ModeTabs({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (FoodAddMode.barcode, Icons.qr_code_scanner, l10n.foodModeBarcode),
      (FoodAddMode.search, Icons.search, l10n.foodModeSearch),
      (FoodAddMode.photo, Icons.photo_camera_outlined, l10n.foodModePhoto),
      (FoodAddMode.quick, Icons.bolt, l10n.foodModeQuick),
    ];

    return Row(
      children: items.map((item) {
        final selected = mode == item.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => onChanged(item.$1),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.orange.withValues(alpha: 0.15) : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.orange : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(item.$2, color: selected ? AppColors.orange : AppColors.textMuted),
                    const SizedBox(height: 4),
                    Text(
                      item.$3,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? AppColors.orange : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
