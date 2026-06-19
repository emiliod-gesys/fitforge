import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cardio_format.dart';
import '../../core/utils/muscle_inference.dart';
import '../../core/utils/player_level.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/exercise_logging.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/localized_exercise_name.dart';
import '../../widgets/milestones_section.dart';
import '../../widgets/player_level_card.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String? _muscleFilter;

  bool _matchesMuscleFilter(PersonalRecord pr) {
    if (_muscleFilter == null) return true;
    return MuscleInference.resolve(exerciseName: pr.exerciseName).contains(_muscleFilter);
  }

  String _prSubtitle(PersonalRecord pr, String unitSystem, dynamic l10n) {
    switch (pr.recordType) {
      case PersonalRecordType.strength:
        return UnitConverter.formatSetLine(pr.weight ?? 0, pr.reps, unitSystem);
      case PersonalRecordType.cardioDistance:
        return l10n.cardioPrDistance;
      case PersonalRecordType.cardioDuration:
        return l10n.cardioPrDuration;
      case PersonalRecordType.cardioSteps:
        return l10n.cardioPrSteps;
      case PersonalRecordType.cardioIncline:
        return l10n.cardioPrIncline;
      case PersonalRecordType.cardioDifficulty:
        return l10n.cardioPrDifficulty;
    }
  }

  String _prTrailing(PersonalRecord pr, String unitSystem, dynamic l10n) {
    switch (pr.recordType) {
      case PersonalRecordType.strength:
        return '${l10n.oneRm}: ${UnitConverter.formatMass(pr.oneRepMax ?? 0, unitSystem)}';
      case PersonalRecordType.cardioDistance:
        return CardioFormat.distance(pr.distanceMeters, unitSystem);
      case PersonalRecordType.cardioDuration:
        return CardioFormat.duration(pr.durationSeconds);
      case PersonalRecordType.cardioSteps:
        return CardioFormat.steps(pr.steps);
      case PersonalRecordType.cardioIncline:
        return CardioFormat.incline(pr.inclinePercent);
      case PersonalRecordType.cardioDifficulty:
        return CardioFormat.difficulty(pr.inclinePercent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prsAsync = ref.watch(personalRecordsProvider);
    final milestoneTotalsAsync = ref.watch(milestoneTotalsProvider);
    final profileAsync = ref.watch(profileProvider);
    final unitSystem = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: FitForgeAppBar(title: l10n.progressTitle),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(personalRecordsProvider);
          ref.invalidate(milestoneTotalsProvider);
          ref.invalidate(profileProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            profileAsync.when(
              data: (profile) {
                if (profile == null) return const SizedBox.shrink();
                final progress = PlayerLevelCalculator.fromTotalXp(profile.totalXp);
                return Column(
                  children: [
                    PlayerLevelCard(progress: progress, l10n: l10n),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: FitForgeLoadingIndicator(size: 48),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            milestoneTotalsAsync.when(
              data: (totals) => Column(
                children: [
                  MilestonesSection(
                    totals: totals,
                    l10n: l10n,
                    unitSystem: unitSystem,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: FitForgeLoadingIndicator(size: 48),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            Text(l10n.personalRecords, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l10n.all),
                      selected: _muscleFilter == null,
                      onSelected: (_) => setState(() => _muscleFilter = null),
                    ),
                  ),
                  ...AppConstants.muscleGroups
                      .where((m) => m != 'Cardio')
                      .map(
                        (muscle) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(l10n.muscleLabel(muscle)),
                            selected: _muscleFilter == muscle,
                            onSelected: (selected) => setState(
                              () => _muscleFilter = selected ? muscle : null,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            prsAsync.when(
              data: (prs) {
                final filtered = prs.where(_matchesMuscleFilter).toList();
                if (filtered.isEmpty) {
                  return Text(
                    _muscleFilter == null
                        ? l10n.noRecordsYet
                        : l10n.noRecordsForMuscle(l10n.muscleLabel(_muscleFilter!)),
                  );
                }
                return Column(
                  children: filtered.map((pr) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.emoji_events, color: Colors.amber),
                        title: LocalizedExerciseName(
                          pr.exerciseName,
                          exerciseId: pr.exerciseId,
                        ),
                        subtitle: Text(_prSubtitle(pr, unitSystem, l10n)),
                        trailing: Text(
                          _prTrailing(pr, unitSystem, l10n),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const FitForgeLoadingIndicator(size: 80),
              error: (e, _) => Text(l10n.errorGeneric(e.toString())),
            ),
          ],
        ),
      ),
    );
  }
}
