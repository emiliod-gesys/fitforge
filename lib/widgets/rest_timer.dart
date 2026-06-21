import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../services/rest_sound_service.dart';

class RestTimer extends StatefulWidget {
  final int sessionId;
  final int seconds;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const RestTimer({
    super.key,
    required this.sessionId,
    required this.seconds,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> with WidgetsBindingObserver {
  static int? _activeSessionId;

  late DateTime _endsAt;
  late int _total;
  late int _remaining;
  Timer? _timer;
  bool _finished = false;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeSessionId = widget.sessionId;
    _resetClock(widget.seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _syncFromClock());
  }

  @override
  void didUpdateWidget(RestTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId || oldWidget.seconds != widget.seconds) {
      _finished = false;
      _activeSessionId = widget.sessionId;
      _resetClock(widget.seconds);
    }
  }

  void _resetClock(int seconds) {
    _total = seconds;
    _endsAt = DateTime.now().add(Duration(seconds: seconds));
    _remaining = seconds;
  }

  @override
  void dispose() {
    _cancelled = true;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (_activeSessionId == widget.sessionId) {
      _activeSessionId = null;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncFromClock();
    }
  }

  Future<void> _syncFromClock() async {
    if (_finished || _cancelled || !mounted) return;

    final remainingMs = _endsAt.difference(DateTime.now()).inMilliseconds;
    if (remainingMs <= 0) {
      await _complete();
      return;
    }

    final remaining = ((remainingMs + 999) ~/ 1000).clamp(1, _total);
    if (remaining != _remaining) {
      setState(() => _remaining = remaining);
    }
  }

  Future<void> _complete() async {
    if (_finished) return;

    _timer?.cancel();
    _finished = true;
    if (mounted) setState(() => _remaining = 0);

    // Cierra el banner de inmediato; el sonido no debe bloquear el dismiss.
    widget.onComplete();
    unawaited(RestSoundService.playRestCompleteAlert());
  }

  void _adjust(int delta) {
    if (_finished || _cancelled || !mounted) return;

    _endsAt = _endsAt.add(Duration(seconds: delta));
    final remainingMs = _endsAt.difference(DateTime.now()).inMilliseconds;

    if (remainingMs <= 0) {
      unawaited(_complete());
      return;
    }

    final remaining = ((remainingMs + 999) ~/ 1000).clamp(0, 600);
    if (remaining > _total) _total = remaining;
    setState(() => _remaining = remaining);
  }

  void _skip() {
    if (_finished || _cancelled || !mounted) return;
    _timer?.cancel();
    _finished = true;
    unawaited(RestSoundService.cancelBell());
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = _total > 0 ? _remaining / _total : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.orange.withValues(alpha: 0.12),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 4,
              backgroundColor: Colors.white12,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.rest, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(l10n.restRemaining(_remaining)),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.minus15s,
            onPressed: () => _adjust(-15),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          IconButton(
            tooltip: l10n.plus15s,
            onPressed: () => _adjust(15),
            icon: const Icon(Icons.add_circle_outline),
          ),
          TextButton(onPressed: _skip, child: Text(l10n.skip)),
        ],
      ),
    );
  }
}
