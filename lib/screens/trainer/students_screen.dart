import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/social.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/social/friend_tile.dart';
import '../../widgets/social/pending_request_tile.dart';
import '../../widgets/social/social_section_header.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isTrainer = ref.watch(isTrainerProvider);

    if (!isTrainer) {
      return Scaffold(
        appBar: FitForgeAppBar(title: l10n.navStudents),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.trainerModeRequired,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    final studentsAsync = ref.watch(trainerStudentsProvider);
    final addableAsync = ref.watch(trainerAddableFriendsProvider);

    return Scaffold(
      appBar: FitForgeAppBar(title: l10n.navStudents),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trainerStudentsProvider);
          ref.invalidate(trainerAddableFriendsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.studentsScreenHint,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SocialSectionHeader(
              title: l10n.studentsCount(
                studentsAsync.valueOrNull?.where((s) => s.isAccepted).length ?? 0,
              ),
            ),
            studentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: FitForgeLoadingIndicator(size: 40)),
              ),
              error: (e, _) => Text(l10n.errorGeneric('$e'), style: const TextStyle(color: AppColors.error)),
              data: (students) {
                final accepted = students.where((s) => s.isAccepted).toList();
                final pending = students.where((s) => s.isPending).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (accepted.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(l10n.studentsEmpty, style: const TextStyle(color: AppColors.textMuted)),
                      )
                    else
                      ...accepted.map((entry) {
                        final student = entry.student ?? FriendUser(id: entry.studentId);
                        return FriendTile(
                          friend: student,
                          onTap: () => context.push('/students/${entry.studentId}'),
                          onLongPress: () => _confirmRemove(context, ref, student.label, entry.studentId),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
                            tooltip: l10n.removeStudentAction,
                            onPressed: () => _confirmRemove(context, ref, student.label, entry.studentId),
                          ),
                        );
                      }),
                    if (pending.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      SocialSectionHeader(title: l10n.studentRequestsSentSection),
                      ...pending.map((entry) {
                        final student = entry.student ?? FriendUser(id: entry.studentId);
                        return PendingRequestTile(
                          friend: student,
                          subtitle: l10n.studentRequestPendingLabel,
                          incoming: false,
                          onDecline: () => _cancelRequest(context, ref, entry.studentId),
                        );
                      }),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            SocialSectionHeader(title: l10n.addStudentFromFriends),
            addableAsync.when(
              loading: () => const _AddableSkeleton(),
              error: (e, _) => Text(l10n.errorGeneric('$e')),
              data: (friends) {
                if (friends.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(l10n.addStudentEmpty, style: const TextStyle(color: AppColors.textMuted)),
                  );
                }
                return Column(
                  children: friends
                      .map(
                        (friend) => FriendTile(
                          friend: friend,
                          trailing: IconButton(
                            icon: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.orange),
                            tooltip: l10n.sendStudentRequestAction,
                            onPressed: () => _addStudent(context, ref, friend.id),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addStudent(BuildContext context, WidgetRef ref, String studentId) async {
    final l10n = context.l10n;
    try {
      await ref.read(trainerServiceProvider).addStudent(studentId);
      ref.invalidate(trainerStudentsProvider);
      ref.invalidate(trainerAddableFriendsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.studentRequestSent)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addStudentFailed('$e'))),
        );
      }
    }
  }

  Future<void> _cancelRequest(BuildContext context, WidgetRef ref, String studentId) async {
    final l10n = context.l10n;
    try {
      await ref.read(trainerServiceProvider).removeStudent(studentId);
      ref.invalidate(trainerStudentsProvider);
      ref.invalidate(trainerAddableFriendsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.studentRequestCanceled)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric('$e'))),
        );
      }
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    String name,
    String studentId,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeStudentTitle),
        content: Text(l10n.removeStudentMessage(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(trainerServiceProvider).removeStudent(studentId);
      ref.invalidate(trainerStudentsProvider);
      ref.invalidate(trainerAddableFriendsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric('$e'))),
        );
      }
    }
  }
}

class _AddableSkeleton extends StatelessWidget {
  const _AddableSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardElevated,
      highlightColor: AppColors.card,
      child: Column(
        children: List.generate(
          2,
          (_) => Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
