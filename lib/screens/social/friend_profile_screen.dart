import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/unit_converter.dart';
import '../../models/profile.dart';
import '../../models/social.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';

class FriendProfileScreen extends ConsumerWidget {
  final String friendId;

  const FriendProfileScreen({super.key, required this.friendId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(friendProfileProvider(friendId));
    final unitSystem = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: const FitForgeAppBar(title: 'Perfil'),
      body: profileAsync.when(
        loading: () => const Center(child: FitForgeLoadingIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (view) {
          if (view == null) {
            return const Center(
              child: Text(
                'No tienes acceso a este perfil o no sois amigos.',
                style: TextStyle(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            );
          }

          final prs = view.personalRecords;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileHeader(user: view.user, profile: view.profile),
              const SizedBox(height: 24),
              const Text(
                'Records personales',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (prs.isEmpty)
                const Text(
                  'Aún no tiene records registrados.',
                  style: TextStyle(color: AppColors.textMuted),
                )
              else
                ...prs.map((pr) {
                  final weight = UnitConverter.kgToDisplay(pr.weight, unitSystem);
                  final orm = UnitConverter.kgToDisplay(pr.oneRepMax, unitSystem);
                  final label = UnitConverter.massLabel(unitSystem);
                  return Card(
                    color: AppColors.card,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(pr.exerciseName),
                      subtitle: Text(
                        '${weight.toStringAsFixed(1)} $label × ${pr.reps} reps · 1RM ~${orm.toStringAsFixed(1)} $label',
                      ),
                      trailing: Text(
                        DateFormat('d MMM', 'es').format(pr.achievedAt),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final FriendUser user;
  final UserProfile profile;

  const _ProfileHeader({required this.user, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.label[0].toUpperCase(),
                      style: const TextStyle(fontSize: 28),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user.label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (profile.experienceLevel != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Nivel: ${profile.experienceLevel}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            if (profile.fitnessGoal != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  profile.fitnessGoal!,
                  style: const TextStyle(color: AppColors.orange),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
