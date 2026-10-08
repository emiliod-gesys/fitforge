import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/subscription/plan_upgrade.dart';
import '../../core/subscription/routine_limit_gate.dart';
import '../../core/subscription/subscription_features.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/workout/smart_routine_builder.dart';
import '../../core/workout/smart_routine_catalog.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';

class SmartRoutineScreen extends ConsumerStatefulWidget {
  const SmartRoutineScreen({super.key});

  @override
  ConsumerState<SmartRoutineScreen> createState() => _SmartRoutineScreenState();
}

class _SmartRoutineScreenState extends ConsumerState<SmartRoutineScreen> {
  final Set<String> _selected = {};
  bool _building = false;

  Future<void> _generate() async {
    final l10n = context.l10n;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.smartRoutineNeedSelection)),
      );
      return;
    }
    if (_building) return;
    final profile = ref.read(profileProvider).valueOrNull;
    if (!(profile?.subscriptionTier.hasSmartRoutine ?? false)) {
      PlanUpgrade.showLimitSnackBar(
        context,
        message: l10n.featureGymratPlansOnly,
        canUpgrade: PlanUpgrade.canOfferStoreUpgrade(profile),
      );
      return;
    }
    final canCreate = await ensureCanCreateRoutine(context, ref);
    if (!canCreate || !mounted) return;

    setState(() => _building = true);
    try {
      final lang = ref.read(preferredLanguageProvider);
      final catalog = await ref.read(exercisesProvider.future);
      final workouts = await ref.read(workoutsProvider.future);
      final byId = {
        for (final target in SmartRoutineCatalog.targets) target.id: target,
      };
      final targets = [
        for (final id in _selected)
          if (byId[id] != null) byId[id]!,
      ];
      final routine = SmartRoutineBuilder.build(
        targets: targets,
        catalog: catalog,
        recent: _recentExercises(workouts),
        languageCode: lang,
        namePrefix: l10n.smartRoutine,
      );
      if (!mounted) return;
      if (routine.exercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.smartRoutineNoExercises)),
        );
        return;
      }
      Navigator.of(context).pop(routine);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _building = false);
    }
  }

  List<RecentExerciseRef> _recentExercises(List<Workout> workouts) {
    final sorted = [...workouts]..sort((a, b) {
        final aDate = a.completedAt ?? a.startedAt;
        final bDate = b.completedAt ?? b.startedAt;
        return bDate.compareTo(aDate);
      });
    final seen = <String>{};
    final recent = <RecentExerciseRef>[];
    for (final workout in sorted) {
      if (workout.completedAt == null) continue;
      for (final exercise in workout.exercises) {
        if (!seen.add(exercise.exerciseId)) continue;
        recent.add(
          RecentExerciseRef(id: exercise.exerciseId, name: exercise.exerciseName),
        );
      }
    }
    return recent;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = ref.watch(preferredLanguageProvider);
    final groups = SmartRoutineCatalog.groupOrder(lang);

    return Scaffold(
      appBar: FitForgeAppBar(title: l10n.smartRoutine),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  l10n.smartRoutineHint,
                  style: const TextStyle(color: AppColors.textMuted, height: 1.35),
                ),
                const SizedBox(height: 20),
                for (final group in groups) ...[
                  Text(
                    group,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final target in SmartRoutineCatalog.inGroup(group, lang))
                        FilterChip(
                          label: Text(target.label(lang)),
                          selected: _selected.contains(target.id),
                          selectedColor: context.accentColor.withValues(alpha: 0.22),
                          checkmarkColor: context.accentColor,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selected.add(target.id);
                              } else {
                                _selected.remove(target.id);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                onPressed: _building ? null : _generate,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: context.accentColor,
                ),
                child: _building
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.smartRoutineGenerate),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
