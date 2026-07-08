import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cardio_format.dart';
import '../../core/utils/muscle_inference.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../../models/exercise_logging.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../models/social.dart';
import '../../core/utils/milestones.dart';
import '../../core/utils/player_level.dart';
import '../../core/utils/workout_streak.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/localized_exercise_name.dart';
import '../../widgets/milestones_section.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/player_level_card.dart';
import '../../widgets/progress/progress_muscle_filter_bar.dart';
import '../../widgets/social/friend_favorite_routines_section.dart';
import '../../widgets/stat_card.dart';

class FriendProfileScreen extends ConsumerWidget {
  final String friendId;

  const FriendProfileScreen({super.key, required this.friendId});

  Friendship? _friendshipFor(List<Friendship> friendships, String? uid) {
    if (uid == null) return null;
    for (final f in friendships) {
      if (f.status != FriendshipStatus.accepted) continue;
      if (f.requesterId == friendId || f.addresseeId == friendId) return f;
    }
    return null;
  }

  void _confirmRemoveFriend(
    BuildContext context,
    WidgetRef ref,
    Friendship friendship,
    String name,
  ) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeFriendTitle),
        content: Text(l10n.removeFriendBody(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(socialServiceProvider).removeFriendship(friendship.id);
              ref.invalidate(friendshipsProvider);
              ref.invalidate(leaderboardProvider);
              ref.invalidate(friendFavoriteRoutinesProvider);
              ref.invalidate(friendProfileProvider(friendId));
              if (context.mounted) context.pop();
            },
            child: Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profileAsync = ref.watch(friendProfileProvider(friendId));
    final friendships = ref.watch(friendshipsProvider).valueOrNull ?? [];
    final mutedIds = ref.watch(mutedFriendsProvider).valueOrNull ?? const <String>{};
    final uid = ref.watch(authStateProvider).valueOrNull?.session?.user.id;
    final friendship = _friendshipFor(friendships, uid);
    final isMuted = mutedIds.contains(friendId);
    final unitSystem = ref.watch(unitSystemProvider);
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: FitForgeAppBar(
        title: l10n.profileTitle,
        actions: [
          if (friendship != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                final name = profileAsync.valueOrNull?.user.label ?? '';
                if (value == 'remove' && profileAsync.valueOrNull != null) {
                  _confirmRemoveFriend(context, ref, friendship, name);
                } else if (value == 'mute' || value == 'unmute') {
                  await ref.read(socialServiceProvider).setFriendMuted(
                        friendId,
                        value == 'mute',
                      );
                  ref.invalidate(mutedFriendsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value == 'mute' ? l10n.friendMuted(name) : l10n.friendUnmuted(name),
                        ),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: isMuted ? 'unmute' : 'mute',
                  child: Text(isMuted ? l10n.unmuteFriend : l10n.muteFriend),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    l10n.removeFriendTitle,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: FitForgeLoadingIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
        data: (view) {
          if (view == null) {
            return Center(
              child: Text(
                l10n.noProfileAccess,
                style: const TextStyle(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            );
          }

          final prs = view.personalRecords;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileHeader(
                user: view.user,
                profile: view.profile,
                weeklyStats: view.weeklyStats,
                l10n: l10n,
              ),
              const SizedBox(height: 24),
              MilestonesSection(
                totals: view.milestoneTotals,
                l10n: l10n,
                unitSystem: unitSystem,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.friendFavoriteRoutines,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              FriendFavoriteRoutinesSection(userId: friendId, l10n: l10n),
              const SizedBox(height: 24),
              _FriendPersonalRecordsSection(
                prs: prs,
                unitSystem: unitSystem,
                locale: locale,
                l10n: l10n,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FriendPersonalRecordsSection extends ConsumerStatefulWidget {
  final List<PersonalRecord> prs;
  final String unitSystem;
  final String locale;
  final AppLocalizations l10n;

  const _FriendPersonalRecordsSection({
    required this.prs,
    required this.unitSystem,
    required this.locale,
    required this.l10n,
  });

  @override
  ConsumerState<_FriendPersonalRecordsSection> createState() =>
      _FriendPersonalRecordsSectionState();
}

class _FriendPersonalRecordsSectionState
    extends ConsumerState<_FriendPersonalRecordsSection> {
  String? _muscleFilter;

  List<String> _categoriesFor(PersonalRecord pr, List<Exercise> catalog) {
    if (pr.isCardio) return const ['Cardio'];
    return MuscleInference.resolve(
      exerciseName: pr.exerciseName,
      exerciseId: pr.exerciseId,
      catalog: catalog,
    );
  }

  List<String> _availableMuscles(List<PersonalRecord> prs, List<Exercise> catalog) {
    final present = <String>{};
    for (final pr in prs) {
      present.addAll(_categoriesFor(pr, catalog));
    }
    return AppConstants.muscleGroups.where(present.contains).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final prs = widget.prs;
    final catalog = ref.watch(exercisesProvider).valueOrNull ?? const [];

    final header = Text(
      l10n.personalRecords,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );

    if (prs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 8),
          Text(l10n.noRecordsFriend, style: const TextStyle(color: AppColors.textMuted)),
        ],
      );
    }

    final available = _availableMuscles(prs, catalog);
    if (available.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 8),
          ...prs.map(_buildCard),
        ],
      );
    }

    final mostRecent = [...prs]..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
    final recentCats = _categoriesFor(mostRecent.first, catalog).where(available.contains);
    final defaultMuscle = recentCats.isNotEmpty ? recentCats.first : available.first;
    final selected = (_muscleFilter != null && available.contains(_muscleFilter))
        ? _muscleFilter!
        : defaultMuscle;

    final filtered = prs
        .where((pr) => _categoriesFor(pr, catalog).contains(selected))
        .toList()
      ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 12),
        ProgressMuscleFilterBar(
          selectedMuscle: selected,
          muscles: available,
          onChanged: (value) => setState(() => _muscleFilter = value),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Text(l10n.noRecordsForMuscle(l10n.muscleLabel(selected)))
        else
          ...filtered.map(_buildCard),
      ],
    );
  }

  Widget _buildCard(PersonalRecord pr) {
    final l10n = widget.l10n;
    final unitSystem = widget.unitSystem;
    if (pr.isCardio) {
      return Card(
        color: AppColors.card,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: LocalizedExerciseName(pr.exerciseName, exerciseId: pr.exerciseId),
          subtitle: Text(_friendCardioPrLine(pr, unitSystem, l10n)),
        ),
      );
    }
    final weight = UnitConverter.kgToDisplay(pr.weight ?? 0, unitSystem);
    final orm = UnitConverter.kgToDisplay(pr.oneRepMax ?? 0, unitSystem);
    final label = UnitConverter.massLabel(unitSystem);
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: LocalizedExerciseName(pr.exerciseName, exerciseId: pr.exerciseId),
        subtitle: Text(
          '${weight.toStringAsFixed(1)} $label × ${pr.reps} ${l10n.reps} · ${l10n.oneRm} ~${orm.toStringAsFixed(1)} $label',
        ),
        trailing: Text(
          DateFormat('d MMM', widget.locale).format(pr.achievedAt),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ),
    );
  }
}

String _friendCardioPrLine(PersonalRecord pr, String unitSystem, AppLocalizations l10n) {
  switch (pr.recordType) {
    case PersonalRecordType.cardioDistance:
      return '${l10n.cardioPrDistance}: ${CardioFormat.distance(pr.distanceMeters, unitSystem)}';
    case PersonalRecordType.cardioDuration:
      return '${l10n.cardioPrDuration}: ${CardioFormat.duration(pr.durationSeconds)}';
    case PersonalRecordType.cardioSteps:
      return '${l10n.cardioPrSteps}: ${CardioFormat.steps(pr.steps)}';
    case PersonalRecordType.cardioIncline:
      return '${l10n.cardioPrIncline}: ${CardioFormat.incline(pr.inclinePercent)}';
    case PersonalRecordType.cardioDifficulty:
      return '${l10n.cardioPrDifficulty}: ${CardioFormat.difficulty(pr.inclinePercent)}';
    case PersonalRecordType.strength:
      return '';
  }
}

class _ProfileHeader extends StatelessWidget {
  final FriendUser user;
  final UserProfile profile;
  final WorkoutWeeklyStats weeklyStats;
  final AppLocalizations l10n;

  const _ProfileHeader({
    required this.user,
    required this.profile,
    required this.weeklyStats,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ProfileAvatar(
              avatarUrl: user.avatarUrl,
              radius: 40,
              fallbackLetter: user.label,
            ),
            const SizedBox(height: 12),
            Text(
              user.label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            PlayerLevelCard(
              progress: PlayerLevelCalculator.fromTotalXp(profile.totalXp),
              l10n: l10n,
            ),
            if (profile.fitnessGoal != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.goalLabel(profile.fitnessGoal),
                  style: const TextStyle(color: AppColors.orange),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.local_fire_department,
                    label: l10n.streakWeekly,
                    value: l10n.streakWeeksLabel(weeklyStats.streakWeeks),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.fitness_center,
                    label: l10n.thisWeek,
                    value: weeklyStats.weekProgressLabel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
