import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
                  child: profile?.avatarUrl == null ? const Icon(Icons.person, size: 48) : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  profile?.displayName ?? 'Usuario',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 32),
              _SectionTitle('Configuración de entrenamiento'),
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Objetivo'),
                subtitle: Text(profile?.fitnessGoal ?? 'No definido'),
                onTap: () => _editGoal(profile),
              ),
              ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('Nivel de experiencia'),
                subtitle: Text(profile?.experienceLevel ?? 'intermedio'),
                onTap: () => _editExperience(profile),
              ),
              ListTile(
                leading: const Icon(Icons.monitor_weight),
                title: const Text('Peso corporal'),
                subtitle: Text(profile?.bodyWeight != null ? '${profile!.bodyWeight} kg' : 'No registrado'),
                onTap: () => _editBodyWeight(profile),
              ),
              const SizedBox(height: 16),
              _SectionTitle('Inteligencia artificial'),
              ListTile(
                leading: const Icon(Icons.key),
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
                leading: const Icon(Icons.auto_awesome),
                title: const Text('Coach IA'),
                subtitle: const Text('Recomendaciones personalizadas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/ai-coach'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
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
        children: goals.map((g) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, g), child: Text(g))).toList(),
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
        children: levels.map((l) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, l), child: Text(l))).toList(),
      ),
    );
    if (selected != null) {
      await ref.read(profileServiceProvider).updateProfile({'experience_level': selected});
      ref.invalidate(profileProvider);
    }
  }

  Future<void> _editBodyWeight(UserProfile? profile) async {
    final controller = TextEditingController(text: profile?.bodyWeight?.toString() ?? '');
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Peso corporal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'kg'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref.read(profileServiceProvider).updateProfile({'body_weight': result});
      ref.invalidate(profileProvider);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white54)),
    );
  }
}
