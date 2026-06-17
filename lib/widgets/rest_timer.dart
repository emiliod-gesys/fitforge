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

class _RestTimerState extends State<RestTimer> {
  static int? _activeSessionId;

  late int _remaining;
  late int _total;
  Timer? _timer;
  bool _finished = false;
  bool _cancelled = false;

  bool get _isActiveSession =>
      !_cancelled && _activeSessionId == widget.sessionId && mounted;

  @override
  void initState() {
    super.initState();
    _activeSessionId = widget.sessionId;
    _total = widget.seconds;
    _remaining = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _cancelled = true;
    _timer?.cancel();
    if (_activeSessionId == widget.sessionId) {
      _activeSessionId = null;
    }
    super.dispose();
  }

  Future<void> _tick() async {
    if (!_isActiveSession) return;

    if (_remaining <= 1) {
      _timer?.cancel();
      if (_finished || !_isActiveSession) return;

      _finished = true;
      await RestSoundService.playRestCompleteBell();
      if (!_isActiveSession) return;
      widget.onComplete();
    } else {
      if (!_isActiveSession) return;
      setState(() => _remaining--);
    }
  }

  void _adjust(int delta) {
    if (!_isActiveSession) return;
    setState(() {
      _remaining = (_remaining + delta).clamp(0, 600);
      _total = _total < _remaining ? _remaining : _total;
    });
    if (_remaining == 0) {
      _timer?.cancel();
      _tick();
    }
  }

  void _skip() {
    if (!_isActiveSession) return;
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
