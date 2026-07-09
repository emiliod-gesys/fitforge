import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/routine.dart';
import '../../providers/app_providers.dart';
import '../fitforge_loading_indicator.dart';
import '../shared_routine_preview.dart';
import '../../core/theme/app_accent.dart';

class FriendFavoriteRoutinesSection extends ConsumerWidget {
  final String userId;
  final AppLocalizations l10n;

  const FriendFavoriteRoutinesSection({
    super.key,
    required this.userId,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(friendFavoriteRoutinesProvider(userId));

    return routinesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: FitForgeLoadingIndicator(size: 28)),
      ),
      error: (e, _) => Text(
        l10n.errorGeneric('$e'),
        style: const TextStyle(color: AppColors.textMuted),
      ),
      data: (routines) {
        if (routines.isEmpty) {
          return Text(
            l10n.noFavoriteRoutinesFriend,
            style: const TextStyle(color: AppColors.textMuted),
          );
        }

        return Column(
          children: routines
              .map(
                (routine) => _FavoriteRoutineCard(
                  routine: routine,
                  l10n: l10n,
                  onPreview: () => SharedRoutinePreview.show(context, ref, routine),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _FavoriteRoutineCard extends StatelessWidget {
  final Routine routine;
  final AppLocalizations l10n;
  final VoidCallback onPreview;

  const _FavoriteRoutineCard({
    required this.routine,
    required this.l10n,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: context.accentColor.withValues(alpha: 0.15),
          child: Icon(Icons.star, color: context.accentColor, size: 20),
        ),
        title: Text(routine.name),
        subtitle: Text(
          '${l10n.exercisesInRoutine(routine.exercises.length)} · ${routine.targetMuscles.join(', ')}',
        ),
        trailing: IconButton(
          icon: Icon(Icons.visibility_outlined),
          tooltip: l10n.previewRoutine,
          color: context.accentColor,
          onPressed: onPreview,
        ),
        onTap: onPreview,
      ),
    );
  }
}
