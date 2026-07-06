import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../models/profile.dart';
import '../providers/app_providers.dart';
import 'body_mannequin/body_mannequin.dart';

/// Mapa con todos los grupos al 100 % (placeholder mientras carga).
Map<String, double> fullMuscleRecoveryMap() {
  return {
    for (final muscle in AppConstants.muscleGroups)
      if (muscle != 'Cardio') muscle: 100.0,
  };
}

class MuscleRecoveryMap extends ConsumerStatefulWidget {
  final Map<String, double> recovery;
  final bool compact;
  final bool isLoading;
  final Gender? gender;

  const MuscleRecoveryMap({
    super.key,
    required this.recovery,
    this.compact = false,
    this.isLoading = false,
    this.gender,
  });

  @override
  ConsumerState<MuscleRecoveryMap> createState() => _MuscleRecoveryMapState();
}

class _MuscleRecoveryMapState extends ConsumerState<MuscleRecoveryMap> {
  String? _highlightedMuscle;

  Color _barColor(double percent) {
    final fatigue = (100 - percent).clamp(0.0, 100.0);
    if (fatigue <= 12) return AppColors.slateLight;
    if (fatigue <= 40) return const Color(0xFF9E4A58);
    return const Color(0xFFE82E45);
  }

  Gender? _genderFromProfile() {
    return widget.gender ?? ref.watch(profileProvider).value?.gender;
  }

  List<MapEntry<String, double>> _sortedEntries() {
    return widget.recovery.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
  }

  void _openDetailSheet() {
    final l10n = context.l10n;
    final gender = _genderFromProfile();
    final sorted = _sortedEntries();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            var sheetHighlight = _highlightedMuscle;

            return StatefulBuilder(
              builder: (context, setSheetState) {
                void toggleHighlight(String key) {
                  setSheetState(() {
                    sheetHighlight = sheetHighlight == key ? null : key;
                  });
                  setState(() => _highlightedMuscle = sheetHighlight);
                }

                return SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt, color: AppColors.orange, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              l10n.recoveryDetailTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          children: [
                            RepaintBoundary(
                              child: BodyMannequin(
                                recovery: widget.recovery,
                                gender: gender,
                                focusGroup: sheetHighlight,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...sorted.map(
                              (entry) => _MuscleRecoveryRow(
                                entry: entry,
                                barColor: _barColor(entry.value),
                                highlighted: entry.key == sheetHighlight,
                                onTap: () => toggleHighlight(entry.key),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gender = _genderFromProfile();
    final sorted = _sortedEntries();
    final topFatigued = sorted.take(3).toList();

    final mannequin = RepaintBoundary(
      child: BodyMannequin(
        recovery: widget.recovery,
        gender: gender,
        focusGroup: _highlightedMuscle,
        compact: widget.compact,
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, color: AppColors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.muscleRecovery, style: Theme.of(context).textTheme.titleMedium),
                ),
                if (widget.compact)
                  TextButton(
                    onPressed: widget.isLoading ? null : _openDetailSheet,
                    child: Text(l10n.recoveryViewDetail),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(l10n.recoveryHint, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 12),
            if (widget.isLoading)
              Shimmer.fromColors(
                baseColor: AppColors.cardElevated,
                highlightColor: AppColors.card,
                child: Container(
                  height: widget.compact ? 220 : 280,
                  decoration: BoxDecoration(
                    color: AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              mannequin,
            if (widget.compact) ...[
              const SizedBox(height: 14),
              Text(
                l10n.recoveryTopFatigued,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...topFatigued.map(
                (entry) => _MuscleRecoveryRow(
                  entry: entry,
                  barColor: _barColor(entry.value),
                  highlighted: entry.key == _highlightedMuscle,
                  compact: true,
                  onTap: () => setState(() {
                    _highlightedMuscle = _highlightedMuscle == entry.key ? null : entry.key;
                  }),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              ...sorted.map(
                (entry) => _MuscleRecoveryRow(
                  entry: entry,
                  barColor: _barColor(entry.value),
                  highlighted: entry.key == _highlightedMuscle,
                  onTap: () => setState(() {
                    _highlightedMuscle = _highlightedMuscle == entry.key ? null : entry.key;
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MuscleRecoveryRow extends StatelessWidget {
  final MapEntry<String, double> entry;
  final Color barColor;
  final bool highlighted;
  final bool compact;
  final VoidCallback? onTap;

  const _MuscleRecoveryRow({
    required this.entry,
    required this.barColor,
    this.highlighted = false,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 10),
      child: Material(
        color: highlighted ? AppColors.orange.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.muscleLabel(entry.key), style: const TextStyle(fontSize: 13)),
                    Text(
                      '${entry.value.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: barColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entry.value / 100,
                    minHeight: compact ? 5 : 6,
                    backgroundColor: AppColors.cardElevated,
                    color: barColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
