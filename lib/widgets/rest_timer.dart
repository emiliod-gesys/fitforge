import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _timer?.cancel();
        widget.onComplete();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / widget.seconds;
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.orange.withValues(alpha: 0.12),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: Colors.white12,
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
          TextButton(onPressed: widget.onSkip, child: const Text('Saltar')),
        ],
      ),
    );
  }
}
