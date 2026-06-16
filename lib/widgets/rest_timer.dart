import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/rest_sound_service.dart';

class RestTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const RestTimer({
    super.key,
    required this.seconds,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> {
  late int _remaining;
  late int _total;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _total = widget.seconds;
    _remaining = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _tick() async {
    if (_remaining <= 1) {
      _timer?.cancel();
      if (!_finished) {
        _finished = true;
        await RestSoundService.playRestCompleteBell();
        widget.onComplete();
      }
    } else {
      setState(() => _remaining--);
    }
  }

  void _adjust(int delta) {
    setState(() {
      _remaining = (_remaining + delta).clamp(0, 600);
      _total = _total < _remaining ? _remaining : _total;
    });
    if (_remaining == 0) {
      _timer?.cancel();
      _tick();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                const Text('Descanso', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${_remaining}s restantes'),
              ],
            ),
          ),
          IconButton(
            tooltip: '-15s',
            onPressed: () => _adjust(-15),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          IconButton(
            tooltip: '+15s',
            onPressed: () => _adjust(15),
            icon: const Icon(Icons.add_circle_outline),
          ),
          TextButton(onPressed: widget.onSkip, child: const Text('Saltar')),
        ],
      ),
    );
  }
}
