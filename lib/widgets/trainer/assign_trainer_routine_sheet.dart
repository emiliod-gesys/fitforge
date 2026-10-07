import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/subscription/routine_limit_gate.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/routine.dart';
import '../../providers/app_providers.dart';
import '../fitforge_loading_indicator.dart';

/// Copia una rutina guardada del entrenador a la biblioteca del alumno.
class AssignTrainerRoutineSheet extends ConsumerStatefulWidget {
  final String studentId;
  final ScrollController scrollController;

  const AssignTrainerRoutineSheet({
    super.key,
    required this.studentId,
    required this.scrollController,
  });

  static Future<void> show(BuildContext context, {required String studentId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, scrollController) => AssignTrainerRoutineSheet(
          studentId: studentId,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  ConsumerState<AssignTrainerRoutineSheet> createState() => _AssignTrainerRoutineSheetState();
}

class _AssignTrainerRoutineSheetState extends ConsumerState<AssignTrainerRoutineSheet> {
  String? _sendingId;

  Future<void> _send(Routine routine) async {
    if (_sendingId != null) return;
    setState(() => _sendingId = routine.id);
    try {
      await ref.read(routineServiceProvider).createRoutine(
            routine.copyForCurrentUser(),
            forUserId: widget.studentId,
          );
      ref.invalidate(studentRoutinesProvider(widget.studentId));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.studentRoutineSent)),
      );
    } catch (e) {
      if (!mounted) return;
      showRoutineSaveErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _sendingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final routinesAsync = ref.watch(routinesProvider);

    return Material(
      color: AppColors.card,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.studentRoutineSendTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: _sendingId == null ? () => Navigator.pop(context) : null,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              l10n.studentRoutineSendHint,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: routinesAsync.when(
              loading: () => const Center(child: FitForgeLoadingIndicator(size: 72)),
              error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
              data: (routines) {
                final mine = routines
                    .where((routine) => !routine.isHyroxSystem && !routine.isRunnerSystem)
                    .toList();
                if (mine.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      l10n.studentRoutineSendEmpty,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }
                return ListView.separated(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: mine.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final routine = mine[index];
                    final sending = _sendingId == routine.id;
                    return ListTile(
                      enabled: _sendingId == null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: CircleAvatar(
                        backgroundColor: context.accentColor.withValues(alpha: 0.15),
                        child: sending
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.accentColor,
                                ),
                              )
                            : Icon(Icons.list_alt, color: context.accentColor),
                      ),
                      title: Text(routine.name),
                      subtitle: Text(l10n.exercisesInRoutine(routine.exercises.length)),
                      onTap: () => _send(routine),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
