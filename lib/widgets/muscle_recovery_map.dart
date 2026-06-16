import 'package:flutter/material.dart';

class MuscleRecoveryMap extends StatelessWidget {
  final Map<String, double> recovery;

  const MuscleRecoveryMap({super.key, required this.recovery});

  Color _colorFor(double percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 50) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recuperación muscular', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Basado en tus entrenamientos recientes', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
                        Text('${e.value.toStringAsFixed(0)}%', style: TextStyle(color: _colorFor(e.value), fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: e.value / 100,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
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
