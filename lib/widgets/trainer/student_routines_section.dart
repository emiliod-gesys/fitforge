import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/routine.dart';
import '../../providers/app_providers.dart';
import '../../core/theme/app_accent.dart';

class StudentRoutinesSection extends ConsumerWidget {
  final String studentId;
  final AppLocalizations l10n;

  const StudentRoutinesSection({
    super.key,
    required this.studentId,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(studentRoutinesProvider(studentId));

    return routinesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text(l10n.errorGeneric('$e')),
      data: (routines) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.push('/students/$studentId/routines/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.studentRoutineNew),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.fromHeight(44),
                foregroundColor: context.accentColor,
                side: BorderSide(color: context.accentColor),
              ),
            ),
            const SizedBox(height: 12),
            if (routines.isEmpty)
              Text(
                l10n.studentRoutinesEmpty,
                style: const TextStyle(color: AppColors.textMuted),
              )
            else
              ...routines.map(
                (routine) => _StudentRoutineCard(
                  routine: routine,
                  studentId: studentId,
                  l10n: l10n,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StudentRoutineCard extends ConsumerWidget {
  final Routine routine;
  final String studentId;
  final AppLocalizations l10n;

  const _StudentRoutineCard({
    required this.routine,
    required this.studentId,
    required this.l10n,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteRoutineTitle),
        content: Text(l10n.deleteRoutineMessage(routine.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(routineServiceProvider).deleteRoutine(
          routine.id,
          forStudentId: studentId,
        );
    ref.invalidate(studentRoutinesProvider(studentId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscles = routine.targetMuscles.isEmpty
        ? '—'
        : routine.targetMuscles.map((m) => l10n.muscleLabel(m)).join(', ');

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: routine.isAiGenerated
              ? context.accentColor.withValues(alpha: 0.15)
              : AppColors.slate.withValues(alpha: 0.4),
          child: Icon(
            routine.isAiGenerated ? Icons.auto_awesome_outlined : Icons.list_alt,
            color: context.accentColor,
          ),
        ),
        title: Text(routine.name),
        subtitle: Text('${l10n.exercisesInRoutine(routine.exercises.length)} · $muscles'),
        trailing: PopupMenuButton<String>(
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
            PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
          ],
          onSelected: (value) async {
            if (value == 'edit') {
              context.push('/students/$studentId/routines/${routine.id}/edit');
            } else if (value == 'delete') {
              await _confirmDelete(context, ref);
            }
          },
        ),
        onTap: () => context.push('/students/$studentId/routines/${routine.id}/edit'),
      ),
    );
  }
}
