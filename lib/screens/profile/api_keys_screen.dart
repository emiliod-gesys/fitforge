import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api_key_guides.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../widgets/api_key_guide_card.dart';
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
      final key = await ref.read(profileServiceProvider).getUserStoredApiKey(profile.aiProvider);
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
          SnackBar(content: Text(context.l10n.apiKeySaved)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.apiKeyDeleted)),
      );
    }
  }

  Future<void> _switchProvider(AiProvider provider) async {
    setState(() {
      _provider = provider;
      _keyController.clear();
    });
    final key = await ref.read(profileServiceProvider).getUserStoredApiKey(provider);
    if (key != null && mounted) {
      setState(() => _keyController.text = key);
    }
  }

  String _keyLabel(AppLocalizations l10n) => switch (_provider) {
        AiProvider.openai => l10n.openAiKey,
        AiProvider.gemini => l10n.geminiKey,
        AiProvider.anthropic => l10n.claudeKey,
        AiProvider.none => l10n.openAiKey,
      };

  String _keyHint(AppLocalizations l10n) => switch (_provider) {
        AiProvider.openai => l10n.openAiHint,
        AiProvider.gemini => l10n.geminiHint,
        AiProvider.anthropic => l10n.claudeHint,
        AiProvider.none => l10n.openAiHint,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: FitForgeAppBar(title: l10n.apiKeysTitle),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.amber.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.apiKeyPrivacy),
            ),
          ),
          const SizedBox(height: 24),
          SegmentedButton<AiProvider>(
            segments: const [
              ButtonSegment(value: AiProvider.openai, label: Text('OpenAI')),
              ButtonSegment(value: AiProvider.gemini, label: Text('Gemini')),
              ButtonSegment(value: AiProvider.anthropic, label: Text('Claude')),
            ],
            selected: {_provider},
            onSelectionChanged: (s) => unawaited(_switchProvider(s.first)),
          ),
          if (_provider == AiProvider.anthropic) ...[
            const SizedBox(height: 8),
            Text(
              l10n.claudeApiNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _keyController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: _keyLabel(l10n),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _keyHint(l10n),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.saveApiKey),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _delete,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.deleteApiKey),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.apiGuidesTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.apiGuidesSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 12),
          ApiKeyGuideCard(
            title: l10n.openAiGuideTitle,
            portalLabel: l10n.openAiGuidePortal,
            portalUrl: Uri.parse(ApiKeyGuides.openAiPortal),
            steps: ApiKeyGuides.openAiSteps(l10n),
            pdfAssetPath: ApiKeyGuides.openAiPdfAsset,
            pdfFileName: 'fitforge-openai-api-key.pdf',
            l10n: l10n,
          ),
          const SizedBox(height: 8),
          ApiKeyGuideCard(
            title: l10n.geminiGuideTitle,
            portalLabel: l10n.geminiGuidePortal,
            portalUrl: Uri.parse(ApiKeyGuides.geminiPortal),
            steps: ApiKeyGuides.geminiSteps(l10n),
            pdfAssetPath: ApiKeyGuides.geminiPdfAsset,
            pdfFileName: 'fitforge-gemini-api-key.pdf',
            l10n: l10n,
          ),
          const SizedBox(height: 8),
          ApiKeyGuideCard(
            title: l10n.claudeGuideTitle,
            portalLabel: l10n.claudeGuidePortal,
            portalUrl: Uri.parse(ApiKeyGuides.claudePortal),
            steps: ApiKeyGuides.claudeSteps(l10n),
            l10n: l10n,
          ),
          const SizedBox(height: 24),
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
