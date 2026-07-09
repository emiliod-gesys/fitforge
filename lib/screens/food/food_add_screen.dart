import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/food_serving_parser.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/food_entry.dart';
import '../../models/manual_food_template.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../core/theme/app_accent.dart';

enum FoodAddMode { search, photo, quick, manual }

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
  List<ManualFoodTemplate> _manualSaved = const [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _loadManualSaved();
    _filterController.addListener(_loadRecent);
  }

  Future<void> _loadManualSaved() async {
    final saved = await ref.read(localManualFoodStoreProvider).getAll();
    if (mounted) setState(() => _manualSaved = saved);
  }

  Future<void> _loadRecent() async {
    final remote = await ref.read(foodServiceProvider).getDistinctRecentFoods(
          query: _filterController.text,
        );
    final local = await ref.read(localManualFoodStoreProvider).search(
          query: _filterController.text,
        );
    final localEntries = local
        .map((template) => template.toPreviewEntry(mealType: widget.mealType))
        .toList();
    final seen = <String>{};
    final merged = <FoodEntry>[];
    for (final entry in [...localEntries, ...remote]) {
      final key = '${entry.name.toLowerCase()}|${entry.source.name}';
      if (seen.add(key)) merged.add(entry);
    }
    if (mounted) setState(() => _recent = merged);
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
    List<int>? imageBytes,
  }) {
    context.push(
      '/food/detail',
      extra: {
        'estimate': estimate,
        'meal': widget.mealType,
        'day': widget.day,
        'source': source,
        if (originalQuery != null) 'originalQuery': originalQuery,
        if (imageBytes != null) 'imageBytes': imageBytes,
      },
    );
  }

  void _openFromEntry(FoodEntry entry) {
    _openDetail(FoodNutritionEstimate.fromEntry(entry), entry.source);
  }

  void _openFromManualTemplate(ManualFoodTemplate template) {
    _openDetail(template.toEstimate(), FoodEntrySource.manual);
  }

  Future<void> _saveManualTemplate(ManualFoodTemplate template) async {
    await ref.read(localManualFoodStoreProvider).save(
          id: template.id,
          name: template.name,
          caloriesKcal: template.caloriesKcal,
          proteinG: template.proteinG,
          carbsG: template.carbsG,
          fatG: template.fatG,
          fiberG: template.fiberG,
          servingDescription: template.servingDescription,
        );
    await _loadManualSaved();
    await _loadRecent();
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

  Future<void> _processFoodImage(XFile image) async {
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
      _openDetail(estimate, FoodEntrySource.aiPhoto, imageBytes: bytes);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFoodImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (image == null || !mounted) return;
    await _processFoodImage(image);
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _ModeTabs(
                  mode: _mode,
                  onChanged: (m) {
                    setState(() => _mode = m);
                    if (m == FoodAddMode.manual) _loadManualSaved();
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: switch (_mode) {
                    FoodAddMode.search => _SearchPane(
                        filterController: _filterController,
                        recent: _recent,
                        onSelect: _openFromEntry,
                      ),
                    FoodAddMode.quick => _QuickAddPane(
                        controller: _quickController,
                        onSubmit: _quickAddWithAi,
                      ),
                    FoodAddMode.manual => _ManualAddPane(
                        saved: _manualSaved,
                        onContinue: (template) async {
                          await _saveManualTemplate(template);
                          if (!mounted) return;
                          _openFromManualTemplate(template);
                        },
                        onSelectSaved: _openFromManualTemplate,
                        onDeleteSaved: (id) async {
                          await ref.read(localManualFoodStoreProvider).delete(id);
                          await _loadManualSaved();
                          await _loadRecent();
                        },
                      ),
                    FoodAddMode.photo => _PhotoPane(
                        onPickImage: _pickFoodImage,
                      ),
                  },
                ),
              ),
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
        Expanded(
          child: recent.isEmpty
              ? Align(
                  alignment: Alignment.topLeft,
                  child: Text(l10n.foodNoRecent, style: const TextStyle(color: AppColors.textMuted)),
                )
              : ListView(
                  children: recent
                      .map(
                        (entry) => _RecentFoodTile(entry: entry, onTap: () => onSelect(entry)),
                      )
                      .toList(),
                ),
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

  bool get _isManual => entry.source == FoodEntrySource.manual && entry.userId == 'local';

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
            if (_isAi) Icon(Icons.auto_awesome, size: 16, color: context.accentColor),
            if (_isManual)
              const Icon(Icons.edit_note, size: 16, color: AppColors.textMuted),
          ],
        ),
        subtitle: Text(
          '${entry.caloriesKcal} kcal${serving != null ? ', $serving' : ''}',
        ),
        trailing: IconButton(
          icon: Icon(Icons.add_circle, color: context.accentColor),
          onPressed: onTap,
        ),
      ),
    );
  }
}

class _ManualAddPane extends StatefulWidget {
  final List<ManualFoodTemplate> saved;
  final Future<void> Function(ManualFoodTemplate template) onContinue;
  final void Function(ManualFoodTemplate template) onSelectSaved;
  final Future<void> Function(String id) onDeleteSaved;

  const _ManualAddPane({
    required this.saved,
    required this.onContinue,
    required this.onSelectSaved,
    required this.onDeleteSaved,
  });

  @override
  State<_ManualAddPane> createState() => _ManualAddPaneState();
}

class _ManualAddPaneState extends State<_ManualAddPane> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();
  final _servingController = TextEditingController();
  bool _submitting = false;
  String? _editingId;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _servingController.dispose();
    super.dispose();
  }

  double _parseDouble(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  Future<void> _submit() async {
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    final calories = int.tryParse(_caloriesController.text.trim());

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.foodManualNameRequired)),
      );
      return;
    }
    if (calories == null || calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.foodManualCaloriesRequired)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final gramsText = _servingController.text.trim();
      final grams = double.tryParse(gramsText.replaceAll(',', '.'));
      final referenceGrams = grams != null && grams > 0 ? grams : 100.0;
      final servingDescription = gramsText.isEmpty
          ? null
          : FoodServingParser.formatAmount(referenceGrams, 'g');

      final template = ManualFoodTemplate(
        id: _editingId ?? '',
        name: name,
        caloriesKcal: calories,
        proteinG: _parseDouble(_proteinController.text),
        carbsG: _parseDouble(_carbsController.text),
        fatG: _parseDouble(_fatController.text),
        fiberG: _parseDouble(_fiberController.text),
        servingDescription: servingDescription,
        updatedAt: DateTime.now(),
      );
      await widget.onContinue(template);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _fillFromSaved(ManualFoodTemplate template) {
    _editingId = template.id;
    _nameController.text = template.name;
    _caloriesController.text = '${template.caloriesKcal}';
    _proteinController.text = template.proteinG > 0 ? template.proteinG.toStringAsFixed(1) : '';
    _carbsController.text = template.carbsG > 0 ? template.carbsG.toStringAsFixed(1) : '';
    _fatController.text = template.fatG > 0 ? template.fatG.toStringAsFixed(1) : '';
    _fiberController.text = template.fiberG > 0 ? template.fiberG.toStringAsFixed(1) : '';
    final grams = FoodServingParser.amountFromDescription(template.servingDescription);
    _servingController.text = grams != null && grams > 0
        ? (grams == grams.roundToDouble() ? '${grams.toInt()}' : grams.toStringAsFixed(1))
        : '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    InputDecoration decoration(String label) => InputDecoration(
          labelText: label,
          isDense: true,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.foodManualAddHint,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: decoration(l10n.foodNameLabel),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: decoration(l10n.foodCaloriesLabel),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _proteinController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: decoration('${l10n.macroProtein} (g)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _carbsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: decoration('${l10n.macroCarbs} (g)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fatController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: decoration('${l10n.macroFat} (g)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _fiberController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: decoration('${l10n.macroFiber} (g)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _servingController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: decoration(l10n.foodManualGramsLabel),
              ),
              SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: context.accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.foodManualAddAction),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.foodManualSavedFoods,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              if (widget.saved.isEmpty)
                Text(l10n.foodManualNoSaved, style: const TextStyle(color: AppColors.textMuted))
              else
                ...widget.saved.map(
                  (template) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(template.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${template.caloriesKcal} kcal'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l10n.edit,
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _fillFromSaved(template),
                          ),
                          IconButton(
                            tooltip: l10n.delete,
                            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                            onPressed: () => widget.onDeleteSaved(template.id),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: context.accentColor),
                            onPressed: () => widget.onSelectSaved(template),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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
          icon: Icon(Icons.auto_awesome),
          label: Text(l10n.foodQuickAddAction),
          style: FilledButton.styleFrom(
            backgroundColor: context.accentColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}

class _PhotoPane extends StatelessWidget {
  final Future<void> Function(ImageSource source) onPickImage;

  const _PhotoPane({required this.onPickImage});

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
          child: Icon(Icons.photo_camera_outlined, size: 64, color: context.accentColor),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.foodPhotoHint,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => onPickImage(ImageSource.camera),
          icon: Icon(Icons.camera_alt),
          label: Text(l10n.foodPhotoAction),
          style: FilledButton.styleFrom(
            backgroundColor: context.accentColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => onPickImage(ImageSource.gallery),
          icon: Icon(Icons.photo_library_outlined),
          label: Text(l10n.foodPhotoGalleryAction),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.accentColor,
            side: BorderSide(color: context.accentColor),
            minimumSize: const Size.fromHeight(48),
          ),
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
      (FoodAddMode.search, Icons.search, l10n.foodModeSearch),
      (FoodAddMode.photo, Icons.photo_camera_outlined, l10n.foodModePhoto),
      (FoodAddMode.quick, Icons.bolt, l10n.foodModeQuick),
      (FoodAddMode.manual, Icons.edit_note, l10n.foodModeManual),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final selected = mode == item.$1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => onChanged(item.$1),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 84,
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? context.accentColor.withValues(alpha: 0.15) : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? context.accentColor : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(item.$2, color: selected ? context.accentColor : AppColors.textMuted),
                    const SizedBox(height: 4),
                    Text(
                      item.$3,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.1,
                        color: selected ? context.accentColor : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
