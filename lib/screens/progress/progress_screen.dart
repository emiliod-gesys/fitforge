import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';

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
    final unitSystem = ref.read(unitSystemProvider);
    final value = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (value == null) return;

    await ref.read(profileServiceProvider).saveBodyMetric(
          type: 'weight',
          displayValue: value,
          unitSystem: unitSystem,
        );

    _weightController.clear();
    ref.invalidate(bodyMeasurementsProvider);
    ref.invalidate(bodyMetricSnapshotsProvider);
    ref.invalidate(profileProvider);
    if (mounted) Navigator.pop(context);
  }

  void _showAddWeight() {
    final unitLabel = UnitConverter.massLabel(ref.read(unitSystemProvider));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar peso'),
        content: TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Peso ($unitLabel)', suffixText: unitLabel),
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
    final unitSystem = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: FitForgeAppBar(
        title: 'Progreso',
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
                    Expanded(
                      child: _StatBox(
                        'Volumen total',
                        UnitConverter.formatVolume(totalVolume, unitSystem),
                      ),
                    ),
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
                            final display = UnitConverter.kgToDisplay(e.value.value, unitSystem);
                            return FlSpot(e.key.toDouble(), display);
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
                        subtitle: Text(UnitConverter.formatSetLine(pr.weight, pr.reps, unitSystem)),
                        trailing: Text(
                          '1RM: ${UnitConverter.formatMass(pr.oneRepMax, unitSystem)}',
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
