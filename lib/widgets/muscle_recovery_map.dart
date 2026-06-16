import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class MuscleRecoveryMap extends StatelessWidget {
  final Map<String, double> recovery;

  const MuscleRecoveryMap({super.key, required this.recovery});

  Color _colorFor(double percent) {
    if (percent >= 80) return AppColors.orange;
    if (percent >= 50) return const Color(0xFFE8A87C);
    return AppColors.slateLight;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: AppColors.orange, size: 20),
                const SizedBox(width: 8),
                Text('Recuperación muscular', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Basado en tus entrenamientos recientes · recuperación en 48 h', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            ...recovery.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(fontSize: 13)),
                        Text('${e.value.toStringAsFixed(0)}%', style: TextStyle(color: _colorFor(e.value), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: e.value / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.cardElevated,
                        color: _colorFor(e.value),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
