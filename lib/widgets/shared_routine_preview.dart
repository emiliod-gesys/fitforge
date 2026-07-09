import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/subscription/routine_limit_gate.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../models/routine.dart';
import '../providers/app_providers.dart';
import 'ai_routine_preview_card.dart';

abstract final class SharedRoutinePreview {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
  ) async {
    final l10n = context.l10n;
    var isSaved = false;
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (isSaved) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ctx.mounted) Navigator.pop(ctx);
            });
          }

          return AlertDialog(
            title: Text(l10n.previewRoutine),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Consumer(
                  builder: (_, ref, __) => AiRoutinePreviewCard(
                    routine: routine,
                    isSaved: isSaved,
                    isDiscarded: false,
                    isSaving: isSaving,
                    shareMode: true,
                    onSave: () async {
                      if (isSaving) return;
                      final canCreate = await ensureCanCreateRoutine(context, ref);
                      if (!canCreate) return;
                      setDialogState(() => isSaving = true);
                      try {
                        await ref.read(routineServiceProvider).copyRoutineToCurrentUser(routine);
                        ref.invalidate(routinesProvider);
                        ref.invalidate(routineLimitStatusProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.routineSavedNamed(routine.name))),
                          );
                        }
                        setDialogState(() => isSaved = true);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (context.mounted) {
                          showRoutineSaveErrorSnackBar(context, e);
                        }
                      }
                    },
                    onEdit: () {},
                    onDiscard: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
