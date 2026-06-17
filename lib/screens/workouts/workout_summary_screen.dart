import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/unit_converter.dart';
import '../../core/utils/workout_summary_share.dart';
import '../../models/workout_summary.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_logo.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  final WorkoutSummaryData summary;

  const WorkoutSummaryScreen({super.key, required this.summary});

  @override
  ConsumerState<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  final _shareCardKey = GlobalKey();
  bool _sharing = false;

  WorkoutSummaryData get summary => widget.summary;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    try {
      final unit = ref.read(unitSystemProvider);
      final text = WorkoutSummaryShare.formatText(summary, unit);

      final boundary =
          _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data != null && mounted) {
          final bytes = data.buffer.asUint8List();
          await Share.shareXFiles(
            [
              XFile.fromData(
                bytes,
                mimeType: 'image/png',
                name: 'fitforge-${summary.workout.name.replaceAll(' ', '-').toLowerCase()}.png',
              ),
            ],
            text: text,
            subject: summary.workout.name,
          );
          return;
        }
      }

      await Share.share(text, subject: summary.workout.name);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: FitForgeAppBar(
        title: 'Resumen',
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _close,
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
                  child: _ShareCard(summary: summary, unitSystem: unit),
                ),
                const SizedBox(height: 20),
                if (summary.hasPreviousComparison) ...[
                  Text(
                    'vs última vez (${summary.previousSameRoutine!.name})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _ComparisonSection(summary: summary, unitSystem: unit),
                  const SizedBox(height: 20),
                ],
                Text(
                  'Ejercicios realizados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                ...summary.exercises.map(
                  (ex) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(ex.exerciseName),
                      subtitle: Text(
                        '${ex.completedSets} series · ${ex.totalReps} reps'
                        '${ex.bestWeightKg != null ? ' · mejor: ${UnitConverter.formatMass(ex.bestWeightKg, unit)}' : ''}',
                      ),
                    ),
                  ),
                ),
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
                      onPressed: _close,
                      child: const Text('Cerrar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _sharing ? null : _share,
                      icon: _sharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.share_outlined),
                      label: const Text('Compartir'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
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
    );
  }
}

class _ShareCard extends StatelessWidget {
  final WorkoutSummaryData summary;
  final String unitSystem;

  const _ShareCard({required this.summary, required this.unitSystem});

  @override
  Widget build(BuildContext context) {
    final records = summary.brokenRecords;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardElevated, AppColors.card],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FitForgeLogo.icon(height: 28),
              SizedBox(width: 8),
              Text('FitForge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            summary.workout.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.durationMinutes} min · ${summary.exercises.length} ejercicios',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Reps',
                  value: '${summary.totalReps}',
                  highlight: summary.isRepsRecord,
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: 'Peso máx',
                  value: summary.maxWeightKg != null
                      ? UnitConverter.formatMass(summary.maxWeightKg, unitSystem, decimals: 0)
                      : '—',
                  highlight: summary.isMaxWeightRecord,
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: 'Volumen',
                  value: UnitConverter.formatVolume(summary.totalVolumeKg, unitSystem),
                  highlight: summary.isVolumeRecord,
                ),
              ),
            ],
          ),
          if (records.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: records
                  .map(
                    (r) => Chip(
                      avatar: Icon(Icons.emoji_events, size: 16, color: AppColors.orange),
                      label: Text('Récord: $r'),
                      backgroundColor: AppColors.orange.withValues(alpha: 0.15),
                      side: BorderSide(color: AppColors.orange.withValues(alpha: 0.4)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.orange : AppColors.textPrimary,
          ),
        ),
        if (highlight)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.arrow_upward, size: 14, color: AppColors.orange),
          ),
      ],
    );
  }
}

class _ComparisonSection extends StatelessWidget {
  final WorkoutSummaryData summary;
  final String unitSystem;

  const _ComparisonSection({required this.summary, required this.unitSystem});

  Widget _row(String label, String current, String? previous, String? delta, bool isRecord) {
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
                color: isRecord ? AppColors.orange : AppColors.textMuted,
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
                const Expanded(flex: 2, child: Text('Hoy', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                  flex: 2,
                  child: Text('Antes', style: TextStyle(color: AppColors.textMuted)),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const Divider(height: 16),
            _row(
              'Reps',
              '${summary.totalReps}',
              summary.previousTotalReps?.toString(),
              _delta(summary.totalReps, summary.previousTotalReps),
              summary.isRepsRecord,
            ),
            _row(
              'Peso máx',
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
              'Volumen',
              UnitConverter.formatVolume(summary.totalVolumeKg, unitSystem),
              summary.previousTotalVolumeKg != null
                  ? UnitConverter.formatVolume(summary.previousTotalVolumeKg!, unitSystem)
                  : null,
              _delta(summary.totalVolumeKg, summary.previousTotalVolumeKg, isWeight: true),
              summary.isVolumeRecord,
            ),
          ],
        ),
      ),
    );
  }
}
