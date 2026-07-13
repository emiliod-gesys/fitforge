import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';

/// Cronómetro de fase/estación para rutinas Hyrox.
class HyroxPhaseTimer extends StatefulWidget {
  final int phaseIndex;
  final int totalPhases;
  final DateTime startedAt;
  final DateTime? stoppedAt;
  final double? targetDistanceMeters;

  const HyroxPhaseTimer({
    super.key,
    required this.phaseIndex,
    required this.totalPhases,
    required this.startedAt,
    this.stoppedAt,
    this.targetDistanceMeters,
  });

  @override
  State<HyroxPhaseTimer> createState() => _HyroxPhaseTimerState();
}

class _HyroxPhaseTimerState extends State<HyroxPhaseTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant HyroxPhaseTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAt != widget.startedAt || oldWidget.stoppedAt != widget.stoppedAt) {
      _tick();
    }
  }

  void _tick() {
    if (!mounted) return;
    if (widget.stoppedAt != null) {
      _timer?.cancel();
    }
    setState(() {
      final end = widget.stoppedAt ?? DateTime.now();
      final elapsed = end.difference(widget.startedAt);
      _elapsed = elapsed.isNegative ? Duration.zero : elapsed;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final meters = widget.targetDistanceMeters?.round();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.accentColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: context.accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.hyroxPhaseTimer(widget.phaseIndex + 1, widget.totalPhases),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: context.accentColor,
                  ),
                ),
                Text(
                  meters != null
                      ? '${l10n.hyroxPhaseSplit} · ${l10n.hyroxTargetDistance(meters)}'
                      : l10n.hyroxPhaseSplit,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _format(_elapsed),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: context.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
