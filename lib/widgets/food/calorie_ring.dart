import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CalorieRing extends StatelessWidget {
  final int remaining;
  final int budget;
  final int eaten;
  final int burned;

  const CalorieRing({
    super.key,
    required this.remaining,
    required this.budget,
    required this.eaten,
    required this.burned,
  });

  @override
  Widget build(BuildContext context) {
    final progress = budget > 0 ? (eaten / budget).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: AppColors.cardElevated,
              color: AppColors.orange,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$remaining',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'kcal',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
