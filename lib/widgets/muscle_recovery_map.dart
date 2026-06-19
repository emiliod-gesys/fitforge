import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../models/profile.dart';
import '../providers/app_providers.dart';
import 'body_mannequin/body_mannequin.dart';

/// Mapa con todos los grupos al 100 % (placeholder mientras carga).
Map<String, double> fullMuscleRecoveryMap() {
  return {
    for (final muscle in AppConstants.muscleGroups)
      if (muscle != 'Cardio') muscle: 100.0,
  };
}

class MuscleRecoveryMap extends ConsumerWidget {
  final Map<String, double> recovery;

  const MuscleRecoveryMap({super.key, required this.recovery});

  Color _barColor(double percent) {
    final fatigue = (100 - percent).clamp(0.0, 100.0);
    if (fatigue <= 12) return AppColors.slateLight;
    if (fatigue <= 40) return const Color(0xFF9E4A58);
    return const Color(0xFFE82E45);
  }

  Gender? _genderFromProfile(WidgetRef ref) {
    return ref.watch(profileProvider).value?.gender;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final gender = _genderFromProfile(ref);

    final sorted = recovery.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: AppColors.orange, size: 20),
                const SizedBox(width: 8),
                Text(l10n.muscleRecovery, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(l10n.recoveryHint, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 12),
            RepaintBoundary(
              child: BodyMannequin(recovery: recovery, gender: gender),
            ),
            const SizedBox(height: 16),
            ...sorted.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.muscleLabel(e.key), style: const TextStyle(fontSize: 13)),
                        Text(
                          '${e.value.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _barColor(e.value),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: e.value / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.cardElevated,
                        color: _barColor(e.value),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

