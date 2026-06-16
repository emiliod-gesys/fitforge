import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';

class ApiKeysScreen extends ConsumerStatefulWidget {
  const ApiKeysScreen({super.key});

  @override
  ConsumerState<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends ConsumerState<ApiKeysScreen> {
  AiProvider _provider = AiProvider.openai;
  final _keyController = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final profile = await ref.read(profileProvider.future);
    if (profile != null && profile.aiProvider != AiProvider.none) {
      setState(() => _provider = profile.aiProvider);
      final key = await ref.read(profileServiceProvider).getApiKey(profile.aiProvider);
      if (key != null) _keyController.text = key;
    }
  }

  Future<void> _save() async {
    if (_keyController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileServiceProvider).saveApiKey(_provider, _keyController.text.trim());
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key guardada de forma segura en el dispositivo')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    await ref.read(profileServiceProvider).deleteApiKey(_provider);
    await ref.read(profileServiceProvider).updateProfile({'ai_provider': null});
    _keyController.clear();
    ref.invalidate(profileProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API key eliminada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FitForgeAppBar(title: 'API Keys'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.amber.withValues(alpha: 0.1),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tu API key se guarda solo en este dispositivo (almacenamiento seguro). '
                'Nunca se envía a nuestros servidores. Las llamadas a IA van directamente a OpenAI o Google.',
              ),
            ),
          ),
          const SizedBox(height: 24),
          SegmentedButton<AiProvider>(
            segments: const [
              ButtonSegment(value: AiProvider.openai, label: Text('OpenAI')),
              ButtonSegment(value: AiProvider.gemini, label: Text('Gemini')),
            ],
            selected: {_provider},
            onSelectionChanged: (s) => setState(() => _provider = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _keyController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: _provider == AiProvider.openai ? 'OpenAI API Key' : 'Gemini API Key',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _provider == AiProvider.openai
                ? 'Obtén tu key en platform.openai.com'
                : 'Obtén tu key en aistudio.google.com',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Guardar API Key'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _delete,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Eliminar API Key'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }
}
