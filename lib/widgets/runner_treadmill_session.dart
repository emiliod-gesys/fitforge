import 'dart:async';

import 'package:flutter/material.dart';

import '../core/runner/runner_tracking.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/cardio_format.dart';
import '../l10n/l10n_extensions.dart';

class RunnerTreadmillResult {
  final int durationSeconds;
  final double distanceMeters;
  final double inclinePercent;

  const RunnerTreadmillResult({
    required this.durationSeconds,
    required this.distanceMeters,
    required this.inclinePercent,
  });

  double? get avgPaceSecPerKm => RunnerTracking.paceSecPerKm(
        distanceMeters: distanceMeters,
        elapsedSeconds: durationSeconds,
      );
}

class RunnerTreadmillSession extends StatefulWidget {
  final String unitSystem;
  final Future<void> Function(RunnerTreadmillResult result) onFinish;
  final VoidCallback onCancel;

  const RunnerTreadmillSession({
    super.key,
    required this.unitSystem,
    required this.onFinish,
    required this.onCancel,
  });

  @override
  State<RunnerTreadmillSession> createState() => _RunnerTreadmillSessionState();
}

class _RunnerTreadmillSessionState extends State<RunnerTreadmillSession> {
  DateTime? _startedAt;
  DateTime? _pausedAt;
  int _accumulatedPauseMs = 0;
  bool _paused = false;
  bool _finishing = false;
  DateTime? _frozenAt;
  Timer? _timer;
  final _inclineController = TextEditingController(text: '0');
  final _distanceController = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    _inclineController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _startedAt = DateTime.now();
      _paused = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_finishing) setState(() {});
    });
  }

  void _togglePause() {
    if (_startedAt == null) return;
    if (_paused) {
      if (_pausedAt != null) {
        _accumulatedPauseMs += DateTime.now().difference(_pausedAt!).inMilliseconds;
      }
      setState(() {
        _paused = false;
        _pausedAt = null;
      });
    } else {
      setState(() {
        _paused = true;
        _pausedAt = DateTime.now();
      });
    }
  }

  int _elapsedSeconds() {
    if (_startedAt == null) return 0;
    final end = _frozenAt ?? DateTime.now();
    var ms = end.difference(_startedAt!).inMilliseconds - _accumulatedPauseMs;
    if (_paused && _pausedAt != null && _frozenAt == null) {
      ms -= end.difference(_pausedAt!).inMilliseconds;
    }
    return (ms / 1000).floor().clamp(0, 86400);
  }

  Future<void> _finish() async {
    if (_finishing || _startedAt == null) return;
    final incline = double.tryParse(_inclineController.text.replaceAll(',', '.'));
    if (incline == null || incline < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.runnerInclineRequired)),
      );
      return;
    }
    final distanceMeters = CardioFormat.parseDistanceMeters(
      _distanceController.text,
      widget.unitSystem,
    );
    if (distanceMeters == null || distanceMeters <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.distanceRequired)),
      );
      return;
    }
    _timer?.cancel();
    _frozenAt = DateTime.now();
    setState(() => _finishing = true);
    await widget.onFinish(
      RunnerTreadmillResult(
        durationSeconds: _elapsedSeconds(),
        distanceMeters: distanceMeters,
        inclinePercent: incline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final elapsed = _elapsedSeconds();
    final distanceMeters = CardioFormat.parseDistanceMeters(
      _distanceController.text,
      widget.unitSystem,
    );
    final pace = distanceMeters != null && distanceMeters > 0
        ? RunnerTracking.paceSecPerKm(distanceMeters: distanceMeters, elapsedSeconds: elapsed)
        : null;

    if (_startedAt == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.runnerTreadmillHint, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.runnerStart),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            CardioFormat.duration(elapsed),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            pace != null ? CardioFormat.pace(pace, widget.unitSystem) : '—',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _inclineController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.runnerInclineLabel,
              suffixText: '%',
              helperText: l10n.runnerInclineHelper,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _distanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.runnerDistance,
              suffixText: CardioFormat.distanceInputLabel(widget.unitSystem),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _finishing ? null : _togglePause,
                  child: Text(_paused ? l10n.runnerResume : l10n.runnerPause),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _finishing ? null : _finish,
                  child: Text(_finishing ? l10n.finish : l10n.runnerFinish),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
