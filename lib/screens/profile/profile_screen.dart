import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/unit_converter.dart';
import '../../models/body_metric.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../widgets/body_metric_card.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final metricsAsync = ref.watch(bodyMetricSnapshotsProvider);

    return Scaffold(
      appBar: FitForgeAppBar(
        title: 'Perfil',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          final unitSystem = ref.watch(unitSystemProvider);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileProvider);
              ref.invalidate(bodyMetricSnapshotsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.card,
                    backgroundImage:
                        profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
                    child: profile?.avatarUrl == null
                        ? const Icon(Icons.person, size: 40, color: AppColors.textMuted)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    profile?.displayName ?? 'Usuario',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 20),
                _UnitSelector(
                  unitSystem: unitSystem,
                  onChanged: (unit) async {
                    await ref.read(profileServiceProvider).updateUnitSystem(unit);
                    ref.invalidate(profileProvider);
                  },
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Métricas corporales'),
                const SizedBox(height: 8),
                metricsAsync.when(
                  data: (snapshots) => _MetricsGrid(
                    snapshots: snapshots,
                    unitSystem: unitSystem,
                    onEdit: (def) => _editMetric(profile, def, snapshots[def.key], unitSystem),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: FitForgeLoadingIndicator(size: 100)),
                  ),
                  error: (e, _) => Text('Error al cargar métricas: $e'),
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Configuración de entrenamiento'),
                ListTile(
                  leading: const Icon(Icons.flag, color: AppColors.orange),
                  title: const Text('Objetivo'),
                  subtitle: Text(profile?.fitnessGoal ?? 'No definido'),
                  onTap: () => _editGoal(profile),
                ),
                ListTile(
                  leading: const Icon(Icons.trending_up, color: AppColors.orange),
                  title: const Text('Nivel de experiencia'),
                  subtitle: Text(profile?.experienceLevel ?? 'intermedio'),
                  onTap: () => _editExperience(profile),
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Inteligencia artificial'),
                ListTile(
                  leading: const Icon(Icons.key, color: AppColors.orange),
                  title: const Text('API Keys (OpenAI / Gemini)'),
                  subtitle: Text(
                    profile?.hasAiKey == true
                        ? 'Configurado (${profile?.aiProvider.name})'
                        : 'No configurado',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/api-keys'),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome, color: AppColors.orange),
                  title: const Text('Coach IA'),
                  subtitle: const Text('Recomendaciones personalizadas'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/ai-coach'),
                ),
              ],
            ),
          );
        },
        loading: () => const FitForgeLoadingScreen(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _editGoal(UserProfile? profile) async {
    const goals = ['Hipertrofia', 'Fuerza', 'Pérdida de grasa', 'Resistencia', 'Mantenimiento'];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Objetivo fitness'),
        children: goals
            .map((g) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, g), child: Text(g)))
            .toList(),
      ),
    );
    if (selected != null) {
      await ref.read(profileServiceProvider).updateProfile({'fitness_goal': selected});
      ref.invalidate(profileProvider);
    }
  }

  Future<void> _editExperience(UserProfile? profile) async {
    const levels = ['principiante', 'intermedio', 'avanzado'];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Nivel de experiencia'),
        children: levels
            .map((l) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, l), child: Text(l)))
            .toList(),
      ),
    );
    if (selected != null) {
      await ref.read(profileServiceProvider).updateProfile({'experience_level': selected});
      ref.invalidate(profileProvider);
    }
  }

  Future<void> _editMetric(
    UserProfile? profile,
    BodyMetricDefinition def,
    BodyMetricSnapshot? snapshot,
    String unitSystem,
  ) async {
    String initialText = '';
    if (snapshot?.hasValue == true) {
      if (def.kind == BodyMetricKind.mass) {
        initialText = UnitConverter.kgToDisplay(snapshot!.valueKg!, unitSystem).toStringAsFixed(1);
      } else {
        final decimals = def.kind == BodyMetricKind.kcal || def.kind == BodyMetricKind.years ? 0 : 1;
        initialText = snapshot!.rawValue!.toStringAsFixed(decimals);
      }
    }

    final controller = TextEditingController(text: initialText);
    final suffix = def.kind == BodyMetricKind.mass
        ? UnitConverter.massLabel(unitSystem)
        : def.unitLabel(unitSystem);

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(def.label),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            suffixText: suffix.isEmpty ? null : suffix,
            hintText: 'Ingresa el valor',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text.replaceAll(',', '.'))),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(profileServiceProvider).saveBodyMetric(
            type: def.key,
            displayValue: result,
            unitSystem: unitSystem,
          );
      ref.invalidate(bodyMetricSnapshotsProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(bodyMeasurementsProvider);
    }
  }
}

class _UnitSelector extends StatelessWidget {
  final String unitSystem;
  final ValueChanged<String> onChanged;

  const _UnitSelector({required this.unitSystem, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _UnitChip(
              label: 'Kilogramos',
              shortLabel: 'kg',
              selected: unitSystem == 'kg',
              onTap: () => onChanged('kg'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _UnitChip(
              label: 'Libras',
              shortLabel: 'lb',
              selected: unitSystem == 'lb',
              onTap: () => onChanged('lb'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;
  final String shortLabel;
  final bool selected;
  final VoidCallback onTap;

  const _UnitChip({
    required this.label,
    required this.shortLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.orange : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                shortLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? Colors.white70 : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final Map<String, BodyMetricSnapshot> snapshots;
  final String unitSystem;
  final void Function(BodyMetricDefinition def) onEdit;

  const _MetricsGrid({
    required this.snapshots,
    required this.unitSystem,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemCount: BodyMetricDefinition.all.length,
      itemBuilder: (context, index) {
        final def = BodyMetricDefinition.all[index];
        final snapshot = snapshots[def.key] ?? BodyMetricSnapshot(type: def.key);
        return BodyMetricCard(
          definition: def,
          snapshot: snapshot,
          unitSystem: unitSystem,
          onTap: () => onEdit(def),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textMuted),
    );
  }
}
