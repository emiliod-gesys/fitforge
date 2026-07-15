import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/hyrox/hyrox_validation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cardio_format.dart';
import '../../core/utils/unit_converter.dart';
import '../../core/utils/workout_summary_share.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../models/workout.dart';
import '../../models/workout_summary.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/runner_surface_picker.dart';
import '../../widgets/workout_calorie_estimate_display.dart';
import '../../widgets/workout_share_cards.dart';
import '../../widgets/localized_exercise_name.dart';
import '../../core/theme/app_accent.dart';
import '../../core/utils/feed_personal_record.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  final WorkoutSummaryData summary;

  const WorkoutSummaryScreen({super.key, required this.summary});

  @override
  ConsumerState<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  final _shareCardKey = GlobalKey();
  final _shareButtonKey = GlobalKey();
  bool _sharing = false;
  bool _finishing = false;
  bool _allowPop = false;
  final Set<String> _selectedPrKeys = {};

  WorkoutSummaryData get summary => widget.summary;

  Rect? _shareOriginRect() {
    final context = _shareButtonKey.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  String _shareImageFileName(String displayName) {
    final label = displayName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim();
    return '${label.isEmpty ? 'FitForge' : label} — FitForge.png';
  }

  Future<bool> _shareWithImageCard({
    required String text,
    required String displayName,
    required String shareSubject,
    Rect? shareOrigin,
  }) async {
    final boundary =
        _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return false;

    await WidgetsBinding.instance.endOfFrame;

    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null || !mounted) return false;

    final fileName = _shareImageFileName(displayName);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

    // iOS lists image + text as separate items ("1 Document" / "Plain Text").
    // The summary card image already contains the workout details.
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png', name: fileName)],
      text: Platform.isIOS ? null : text,
      subject: shareSubject,
      sharePositionOrigin: shareOrigin,
    );
    return true;
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    final unit = ref.read(unitSystemProvider);
    final l10n = context.l10n;
    final displayName = l10n.workoutDisplayName(summary.workout.name);
    final text = WorkoutSummaryShare.formatText(l10n, summary, unit, displayName: displayName);
    final shareSubject = l10n.shareWorkoutTitle(displayName);
    final shareOrigin = _shareOriginRect();

    try {
      final sharedWithImage = await _shareWithImageCard(
        text: text,
        displayName: displayName,
        shareSubject: shareSubject,
        shareOrigin: shareOrigin,
      );
      if (!sharedWithImage) {
        await Share.share(
          text,
          subject: shareSubject,
          sharePositionOrigin: shareOrigin,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorGeneric('$e')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  List<PersonalRecord> get _selectedPersonalRecords => summary.newPersonalRecords
      .where((pr) => _selectedPrKeys.contains(FeedPersonalRecord.keyFor(pr)))
      .toList();

  Future<int> _publishSelectedFeedRecords() async {
    final selected = _selectedPersonalRecords;
    if (selected.isEmpty) return 0;
    return ref.read(socialServiceProvider).publishPersonalRecords(selected);
  }

  Future<void> _finishSummary() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    var publishedCount = 0;
    if (_selectedPrKeys.isNotEmpty && summary.hasNewPersonalRecords) {
      try {
        publishedCount = await _publishSelectedFeedRecords();
        ref.invalidate(socialFeedProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.feedPrShareFailed),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    if (!mounted) return;

    ref.read(pendingWorkoutSummaryProvider.notifier).state = null;
    ref.invalidate(profileProvider);

    final messenger = ScaffoldMessenger.of(context);
    if (publishedCount > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.feedPrShared(publishedCount))),
      );
    }

    setState(() => _allowPop = true);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unit = ref.watch(unitSystemProvider);

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_finishing) {
          _finishSummary();
        }
      },
      child: Scaffold(
      appBar: FitForgeAppBar(
        title: l10n.summaryTitle,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _finishing ? null : _finishSummary,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                RepaintBoundary(
                  key: _shareCardKey,
                  child: WorkoutShareCard(summary: summary, unitSystem: unit, l10n: l10n),
                ),
                const SizedBox(height: 20),
                if (summary.hasRunnerSummary) ...[
                  _RunnerSummarySection(summary: summary, unitSystem: unit, l10n: l10n),
                  const SizedBox(height: 20),
                ],
                if (summary.hyroxValidation?.status == HyroxValidationStatus.rejected ||
                    summary.hyroxValidation?.status == HyroxValidationStatus.suspicious) ...[
                  _HyroxValidationBanner(summary: summary, l10n: l10n),
                  const SizedBox(height: 16),
                ],
                if (summary.hasHyroxSplits) ...[
                  _HyroxSplitsSection(summary: summary, l10n: l10n),
                  const SizedBox(height: 20),
                ],
                if (summary.hasPreviousComparison) ...[
                  Text(
                    l10n.vsLastTime(l10n.workoutDisplayName(summary.previousSameRoutine!.name)),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _ComparisonSection(summary: summary, unitSystem: unit, l10n: l10n),
                  const SizedBox(height: 20),
                ],
                Text(
                  l10n.exercisesCompleted,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                ...summary.exercises.map(
                  (ex) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: LocalizedExerciseName(
                              ex.exerciseName,
                              exerciseId: ex.exerciseId,
                            ),
                          ),
                          if (ex.isNewPersonalRecord)
                            _PrBadge(label: l10n.summaryPersonalRecordBadge),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex.bestWeightKg != null
                                ? l10n.setsRepsBest(
                                    ex.completedSets,
                                    ex.totalReps,
                                    UnitConverter.formatMass(ex.bestWeightKg, unit),
                                  )
                                : l10n.setsReps(ex.completedSets, ex.totalReps),
                          ),
                          if (ex.improvedBestWeight || ex.improvedVolume)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                l10n.summaryExerciseImproved,
                                style: TextStyle(
                                  color: context.accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (summary.hasNewPersonalRecords) ...[
                  const SizedBox(height: 20),
                  _FeedShareSection(
                    records: summary.newPersonalRecords,
                    unitSystem: unit,
                    selectedKeys: _selectedPrKeys,
                    onToggle: (key, selected) {
                      setState(() {
                        if (selected) {
                          _selectedPrKeys.add(key);
                        } else {
                          _selectedPrKeys.remove(key);
                        }
                      });
                    },
                    l10n: l10n,
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _finishing ? null : _finishSummary,
                      child: Text(l10n.close),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      key: _shareButtonKey,
                      onPressed: _sharing ? null : _share,
                      icon: _sharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(Icons.share_outlined),
                      label: Text(l10n.share),
                      style: FilledButton.styleFrom(
                        backgroundColor: context.accentColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _RunnerSummarySection extends StatelessWidget {
  final WorkoutSummaryData summary;
  final String unitSystem;
  final AppLocalizations l10n;

  const _RunnerSummarySection({
    required this.summary,
    required this.unitSystem,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final workout = summary.workout;
    final accent = context.accentColor;
    final points = workout.runnerRoute.map((p) => LatLng(p.lat, p.lng)).toList();
    WorkoutSet? cardioSet;
    for (final ex in workout.exercises) {
      for (final s in ex.sets) {
        if (s.completed && s.isCardio) {
          cardioSet = s;
          break;
        }
      }
      if (cardioSet != null) break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.runnerSummaryTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (workout.runnerSurface != null) ...[
            const SizedBox(height: 6),
            Text(
              runnerSurfaceLabel(l10n, workout.runnerSurface!),
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
          if (cardioSet?.inclinePercent != null) ...[
            const SizedBox(height: 6),
            Text('${l10n.runnerInclineLabel}: ${CardioFormat.incline(cardioSet!.inclinePercent)}'),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RunnerStat(
                label: l10n.runnerDistance,
                value: CardioFormat.distance(cardioSet?.distanceMeters, unitSystem),
              ),
              _RunnerStat(
                label: l10n.runnerAvgPace,
                value: CardioFormat.pace(workout.runnerAvgPaceSecPerKm, unitSystem),
              ),
              _RunnerStat(
                label: l10n.runnerTime,
                value: CardioFormat.duration(cardioSet?.durationSeconds),
              ),
            ],
          ),
          if (points.length >= 2) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RunnerStat(
                  label: l10n.runnerElevationGain,
                  value: CardioFormat.elevationLive(
                    workout.runnerElevationGainMeters ?? 0,
                    unitSystem,
                  ),
                ),
                _RunnerStat(
                  label: l10n.runnerElevationLoss,
                  value: CardioFormat.elevationLive(
                    workout.runnerElevationLossMeters ?? 0,
                    unitSystem,
                  ),
                ),
                _RunnerStat(
                  label: l10n.runnerElevationNet,
                  value: CardioFormat.elevationNet(
                    gainMeters: workout.runnerElevationGainMeters ?? 0,
                    lossMeters: workout.runnerElevationLossMeters ?? 0,
                    unitSystem: unitSystem,
                  ),
                ),
              ],
            ),
          ],
          if (summary.hasCalorieEstimate) ...[
            const SizedBox(height: 12),
            WorkoutCalorieEstimateDisplay(summary: summary, l10n: l10n, accent: accent),
          ],
          if (points.length >= 2) ...[
            const SizedBox(height: 12),
            Text(l10n.runnerRouteTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: points.last,
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.fitforge.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(points: points, strokeWidth: 3, color: accent),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (workout.runnerSplits.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.runnerSplitsTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
            ...workout.runnerSplits.map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.runnerSplitKm(s.km))),
                    Text(CardioFormat.duration(s.seconds)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RunnerStat extends StatelessWidget {
  final String label;
  final String value;

  const _RunnerStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _HyroxValidationBanner extends StatelessWidget {
  final WorkoutSummaryData summary;
  final AppLocalizations l10n;

  const _HyroxValidationBanner({
    required this.summary,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final validation = summary.hyroxValidation;
    if (validation?.status == null) return const SizedBox.shrink();

    final rejected = validation!.status == HyroxValidationStatus.rejected;
    final color = rejected ? AppColors.error : const Color(0xFFE6A700);
    final message = rejected ? l10n.hyroxValidationRejected : l10n.hyroxValidationSuspicious;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(rejected ? Icons.block : Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _HyroxSplitsSection extends StatelessWidget {
  final WorkoutSummaryData summary;
  final AppLocalizations l10n;

  const _HyroxSplitsSection({required this.summary, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.hyroxSplitsSummaryTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                CardioFormat.duration(summary.hyroxTotalSeconds),
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          if (summary.hasCalorieEstimate) ...[
            const SizedBox(height: 12),
            WorkoutCalorieEstimateDisplay(summary: summary, l10n: l10n, accent: accent),
          ],
          const SizedBox(height: 12),
          ...summary.hyroxSplits.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LocalizedExerciseName(
                      entry.value.exerciseName,
                      exerciseId: entry.value.exerciseId,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    CardioFormat.duration(entry.value.seconds),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonSection extends StatelessWidget {
  final WorkoutSummaryData summary;
  final String unitSystem;
  final AppLocalizations l10n;

  const _ComparisonSection({required this.summary, required this.unitSystem, required this.l10n});

  Widget _row(BuildContext context, String label, String current, String? previous, String? delta, bool isRecord) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(
            flex: 2,
            child: Text(current, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (previous != null)
            Expanded(
              flex: 2,
              child: Text(previous, style: TextStyle(color: AppColors.textMuted)),
            ),
          if (delta != null)
            Text(
              delta,
              style: TextStyle(
                color: isRecord ? context.accentColor : AppColors.textMuted,
                fontWeight: isRecord ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }

  String? _delta(num? current, num? previous, {bool isWeight = false}) {
    if (current == null || previous == null) return null;
    final diff = current - previous;
    if (diff == 0) return '=';
    if (isWeight) {
      return UnitConverter.formatDelta(diff.toDouble(), unitSystem, decimals: 0);
    }
    final sign = diff > 0 ? '+' : '';
    return '$sign$diff';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(flex: 2, child: SizedBox()),
                Expanded(flex: 2, child: Text(l10n.today, style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                  flex: 2,
                  child: Text(l10n.before, style: TextStyle(color: AppColors.textMuted)),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const Divider(height: 16),
            _row(
              context,
              l10n.reps,
              '${summary.totalReps}',
              summary.previousTotalReps?.toString(),
              _delta(summary.totalReps, summary.previousTotalReps),
              summary.isRepsRecord,
            ),
            _row(
              context,
              l10n.maxWeight,
              summary.maxWeightKg != null
                  ? UnitConverter.formatMass(summary.maxWeightKg, unitSystem, decimals: 0)
                  : '—',
              summary.previousMaxWeightKg != null
                  ? UnitConverter.formatMass(summary.previousMaxWeightKg, unitSystem, decimals: 0)
                  : null,
              _delta(summary.maxWeightKg, summary.previousMaxWeightKg, isWeight: true),
              summary.isMaxWeightRecord,
            ),
            _row(
              context,
              l10n.volume,
              UnitConverter.formatVolume(summary.totalVolumeKg, unitSystem),
              summary.previousTotalVolumeKg != null
                  ? UnitConverter.formatVolume(summary.previousTotalVolumeKg!, unitSystem)
                  : null,
              _delta(summary.totalVolumeKg, summary.previousTotalVolumeKg, isWeight: true),
              summary.isVolumeRecord,
            ),
            _row(
              context,
              l10n.durationMin,
              '${summary.durationMinutes}',
              summary.previousDurationMinutes?.toString(),
              _delta(summary.durationMinutes, summary.previousDurationMinutes),
              false,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrBadge extends StatelessWidget {
  final String label;

  const _PrBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 8),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.accentColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.accentColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.accentColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _FeedShareSection extends StatelessWidget {
  final List<PersonalRecord> records;
  final String unitSystem;
  final Set<String> selectedKeys;
  final void Function(String key, bool selected) onToggle;
  final AppLocalizations l10n;

  const _FeedShareSection({
    required this.records,
    required this.unitSystem,
    required this.selectedKeys,
    required this.onToggle,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_outline, color: context.accentColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.feedSharePrTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.feedSharePrSubtitle,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...records.map((pr) {
              final key = FeedPersonalRecord.keyFor(pr);
              return CheckboxListTile(
                value: selectedKeys.contains(key),
                onChanged: (checked) => onToggle(key, checked ?? false),
                activeColor: context.accentColor,
                secondary: Icon(Icons.emoji_events, color: context.accentColor, size: 22),
                title: LocalizedExerciseName(
                  pr.exerciseName,
                  exerciseId: pr.exerciseId,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  FeedPersonalRecord.formatValue(pr, unitSystem),
                  style: TextStyle(color: context.accentColor, fontWeight: FontWeight.w600),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Fallback cuando GoRouter reconstruye `/workout/summary` sin `extra`.
class WorkoutSummaryMissingScreen extends ConsumerStatefulWidget {
  const WorkoutSummaryMissingScreen({super.key});

  @override
  ConsumerState<WorkoutSummaryMissingScreen> createState() => _WorkoutSummaryMissingScreenState();
}

class _WorkoutSummaryMissingScreenState extends ConsumerState<WorkoutSummaryMissingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = ref.read(pendingWorkoutSummaryProvider);
      if (pending == null) {
        context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingWorkoutSummaryProvider);
    if (pending != null) {
      return WorkoutSummaryScreen(summary: pending);
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
