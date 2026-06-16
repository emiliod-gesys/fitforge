import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _addWeight() async {
    final value = double.tryParse(_weightController.text);
    if (value == null) return;

    await ref.read(workoutServiceProvider).addBodyMeasurement(
          BodyMeasurement(
            id: '',
            userId: '',
            type: 'weight',
            value: value,
            measuredAt: DateTime.now(),
          ),
        );

    _weightController.clear();
    ref.invalidate(bodyMeasurementsProvider);
    if (mounted) Navigator.pop(context);
  }

  void _showAddWeight() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar peso'),
        content: TextField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Peso (kg)', suffixText: 'kg'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _addWeight();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prsAsync = ref.watch(personalRecordsProvider);
    final measurementsAsync = ref.watch(bodyMeasurementsProvider);
    final workoutsAsync = ref.watch(workoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddWeight),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(personalRecordsProvider);
          ref.invalidate(bodyMeasurementsProvider);
          ref.invalidate(workoutsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            workoutsAsync.when(
              data: (workouts) {
                final completed = workouts.where((w) => w.completedAt != null).length;
                final totalVolume = workouts.fold<double>(0, (s, w) => s + w.totalVolume);
                return Row(
                  children: [
                    Expanded(child: _StatBox('Entrenos', '$completed')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatBox('Volumen total', '${totalVolume.toStringAsFixed(0)} kg')),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text('Peso corporal', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            measurementsAsync.when(
              data: (measurements) {
                if (measurements.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Registra tu peso para ver el gráfico')),
                    ),
                  );
                }
                return SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: measurements.reversed.toList().asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.value);
                          }).toList(),
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            Text('Records personales', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            prsAsync.when(
              data: (prs) {
                if (prs.isEmpty) {
                  return const Text('Completa entrenamientos para registrar PRs');
                }
                return Column(
                  children: prs.take(10).map((pr) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.emoji_events, color: Colors.amber),
                        title: Text(pr.exerciseName),
                        subtitle: Text('${pr.weight} kg × ${pr.reps} reps'),
                        trailing: Text(
                          '1RM: ${pr.oneRepMax.toStringAsFixed(1)} kg',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
