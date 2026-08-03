import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../providers/app_providers.dart';

/// Zona peligrosa al final del perfil: borrado de cuenta con varias confirmaciones.
class DeleteAccountSection extends ConsumerStatefulWidget {
  const DeleteAccountSection({super.key});

  @override
  ConsumerState<DeleteAccountSection> createState() => _DeleteAccountSectionState();
}

class _DeleteAccountSectionState extends ConsumerState<DeleteAccountSection> {
  bool _busy = false;

  Future<void> _startDeleteFlow() async {
    if (_busy) return;
    final l10n = context.l10n;

    final continue1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.deleteAccountContinue),
          ),
        ],
      ),
    );
    if (continue1 != true || !mounted) return;

    final continue2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => _UnderstandDialog(
        title: l10n.deleteAccountConfirmTitle,
        message: l10n.deleteAccountConfirmMessage,
        checkboxLabel: l10n.deleteAccountUnderstand,
        cancelLabel: l10n.cancel,
        continueLabel: l10n.deleteAccountContinue,
      ),
    );
    if (continue2 != true || !mounted) return;

    final phrase = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TypePhraseDialog(
        title: l10n.deleteAccountTypeTitle,
        message: l10n.deleteAccountTypeMessage,
        hint: l10n.deleteAccountTypeHint,
        cancelLabel: l10n.cancel,
        deleteLabel: l10n.deleteAccountAction,
      ),
    );
    if (phrase == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).deleteAccount(confirmation: phrase);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deleteAccountFailed('$e')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.deleteAccountSectionTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.deleteAccountSectionSubtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.35),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _startDeleteFlow,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            minimumSize: const Size.fromHeight(48),
          ),
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                )
              : const Icon(Icons.delete_forever_outlined),
          label: Text(l10n.deleteAccountAction),
        ),
      ],
    );
  }
}

class _UnderstandDialog extends StatefulWidget {
  const _UnderstandDialog({
    required this.title,
    required this.message,
    required this.checkboxLabel,
    required this.cancelLabel,
    required this.continueLabel,
  });

  final String title;
  final String message;
  final String checkboxLabel;
  final String cancelLabel;
  final String continueLabel;

  @override
  State<_UnderstandDialog> createState() => _UnderstandDialogState();
}

class _UnderstandDialogState extends State<_UnderstandDialog> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _understood,
            onChanged: (v) => setState(() => _understood = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(widget.checkboxLabel, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _understood ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: Text(widget.continueLabel),
        ),
      ],
    );
  }
}

class _TypePhraseDialog extends StatefulWidget {
  const _TypePhraseDialog({
    required this.title,
    required this.message,
    required this.hint,
    required this.cancelLabel,
    required this.deleteLabel,
  });

  final String title;
  final String message;
  final String hint;
  final String cancelLabel;
  final String deleteLabel;

  @override
  State<_TypePhraseDialog> createState() => _TypePhraseDialogState();
}

class _TypePhraseDialogState extends State<_TypePhraseDialog> {
  final _phraseController = TextEditingController();
  bool _enabled = false;

  static final _allowed = RegExp(r'^(BORRAR|DELETE)$', caseSensitive: false);

  @override
  void initState() {
    super.initState();
    _phraseController.addListener(_recompute);
  }

  void _recompute() {
    final next = _allowed.hasMatch(_phraseController.text.trim());
    if (next != _enabled) setState(() => _enabled = next);
  }

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message),
            const SizedBox(height: 16),
            TextField(
              controller: _phraseController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: widget.hint,
                hintText: 'BORRAR / DELETE',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _enabled
              ? () => Navigator.pop(
                    context,
                    _phraseController.text.trim().toUpperCase(),
                  )
              : null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: Text(widget.deleteLabel),
        ),
      ],
    );
  }
}
