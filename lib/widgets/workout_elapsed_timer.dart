import 'dart:async';

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/supabase_datetime.dart';
import '../core/theme/app_accent.dart';

/// Cronómetro del tiempo total transcurrido desde el inicio del entrenamiento.
class WorkoutElapsedTimer extends StatefulWidget {
  final DateTime startedAt;
  final DateTime? stoppedAt;

  const WorkoutElapsedTimer({super.key, required this.startedAt, this.stoppedAt});

  @override
  State<WorkoutElapsedTimer> createState() => _WorkoutElapsedTimerState();
}

class _WorkoutElapsedTimerState extends State<WorkoutElapsedTimer> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = _currentElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (widget.stoppedAt != null) return;
      setState(() => _elapsed = _currentElapsed());
    });
  }

  @override
  void didUpdateWidget(covariant WorkoutElapsedTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAt != widget.startedAt || oldWidget.stoppedAt != widget.stoppedAt) {
      setState(() => _elapsed = _currentElapsed());
    }
  }

  Duration _currentElapsed() {
    final end = widget.stoppedAt?.toUtc() ?? SupabaseDateTime.nowUtc;
    final elapsed = end.difference(widget.startedAt.toUtc());
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  static String _format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 18, color: context.accentColor),
          const SizedBox(width: 8),
          Text(
            _format(_elapsed),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}
