import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../models/routine.dart';
import '../providers/app_providers.dart';
import 'ai_routine_preview_card.dart';

class RoutineShareRequestDialog extends ConsumerStatefulWidget {
  final String requestId;

  const RoutineShareRequestDialog({super.key, required this.requestId});

  static Future<void> show(BuildContext context, String requestId) {
    return showDialog<void>(
      context: context,
      builder: (_) => RoutineShareRequestDialog(requestId: requestId),
    );
  }

  @override
  ConsumerState<RoutineShareRequestDialog> createState() => _RoutineShareRequestDialogState();
}

class _RoutineShareRequestDialogState extends ConsumerState<RoutineShareRequestDialog> {
  Routine? _routine;
  var _loading = true;
  var _responding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final routine = await ref.read(routineShareServiceProvider).getSharePreview(widget.requestId);
      if (!mounted) return;
      setState(() {
        _routine = routine;
        _loading = false;
        if (routine == null) _error = 'not_found';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _respond(bool accept) async {
    if (_responding) return;
    setState(() => _responding = true);
    final l10n = context.l10n;

    try {
      await ref.read(routineShareServiceProvider).respondToShare(
            requestId: widget.requestId,
            accept: accept,
          );
      ref.invalidate(socialNotificationsProvider);
      ref.invalidate(socialUnreadCountProvider);
      if (accept) ref.invalidate(routinesProvider);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? l10n.routineShareAccepted : l10n.routineShareDeclined),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _responding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.saveFailed('$e')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading) {
      return AlertDialog(
        content: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.loading),
        ),
      );
    }

    if (_error != null || _routine == null) {
      return AlertDialog(
        title: Text(l10n.shareRoutine),
        content: Text(l10n.routineShareUnavailable),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
        ],
      );
    }

    return AlertDialog(
      title: Text(l10n.shareRoutine),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: AiRoutinePreviewCard(
            routine: _routine!,
            isSaved: false,
            isDiscarded: false,
            previewOnly: true,
            onSave: () {},
            onEdit: () {},
            onDiscard: () {},
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _responding ? null : () => _respond(false),
          child: Text(l10n.decline),
        ),
        ElevatedButton(
          onPressed: _responding ? null : () => _respond(true),
          child: _responding
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.accept),
        ),
      ],
    );
  }
}
