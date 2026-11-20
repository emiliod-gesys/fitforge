import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/center_aspect_crop.dart';
import '../core/utils/cardio_format.dart';
import '../core/utils/quantity_format.dart';
import '../core/utils/unit_converter.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';
import '../models/workout.dart';
import '../models/workout_summary.dart';
import '../services/feed_media_service.dart';
import 'fitforge_logo.dart';
import 'runner_surface_picker.dart';

/// Lienzo lógico 9:16. Con [workoutShareStoryPixelRatio] la captura es 1080×1920.
const workoutShareStoryWidth = 360.0;
const workoutShareStoryHeight = 640.0;
const workoutShareStoryPixelRatio = 3.0;

class WorkoutShareCard extends StatelessWidget {
  final WorkoutSummaryData summary;
  final String unitSystem;
  final AppLocalizations l10n;

  const WorkoutShareCard({
    super.key,
    required this.summary,
    required this.unitSystem,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: workoutShareStoryWidth / workoutShareStoryHeight,
      child: FittedBox(
        fit: BoxFit.contain,
        child: WorkoutShareStory(summary: summary, unitSystem: unitSystem, l10n: l10n),
      ),
    );
  }
}

/// Lienzo fijo 360×640. La vista lo escala; la captura usa este tamaño.
class WorkoutShareStory extends StatelessWidget {
  final WorkoutSummaryData summary;
  final String unitSystem;
  final AppLocalizations l10n;

  const WorkoutShareStory({
    super.key,
    required this.summary,
    required this.unitSystem,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox(
        width: workoutShareStoryWidth,
        height: workoutShareStoryHeight,
        child: _StoryCanvas(summary: summary, unitSystem: unitSystem, l10n: l10n),
      ),
    );
  }
}

class _StoryCanvas extends StatelessWidget {
  final WorkoutSummaryData summary;
  final String unitSystem;
  final AppLocalizations l10n;

  const _StoryCanvas({
    required this.summary,
    required this.unitSystem,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final when = (summary.workout.completedAt ?? summary.workout.startedAt).toLocal();
    final dateLabel = DateFormat('d MMM', l10n.localeName).format(when);
    final mode = _modeLabel(summary, l10n);
    final stats = _storyStats(summary, unitSystem, l10n);
    final highlight = _storyHighlight(summary, unitSystem, l10n);
    final calories = _calorieLine(summary, stats);
    final subtitle = _subtitle(summary, l10n);
    final hasPhoto = summary.hasFinishPhoto;

    return ClipRect(
      child: ColoredBox(
        color: AppColors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!hasPhoto) const _StoryScrim(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const FitForgeLogo.icon(height: 26),
                      const SizedBox(width: 8),
                      const Text(
                        'FORGEN',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (mode != null) ...[
                    const SizedBox(height: 12),
                    _ModeChip(label: mode),
                  ],
                  if (hasPhoto) ...[
                    const SizedBox(height: 14),
                    Flexible(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: ColoredBox(
                          color: AppColors.card,
                          child: AspectRatio(
                            aspectRatio: workoutFinishPhotoAspectRatio,
                            child: _StoryFinishPhoto(summary: summary),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  const SizedBox(height: 16),
                  Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.cobalt,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.workoutDisplayName(summary.workout.name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _StatRow(
                    stats: stats,
                    calories: calories,
                    calorieLabel: calories == null ? null : l10n.caloriesBurned,
                  ),
                  if (highlight != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      highlight.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: highlight.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (!hasPhoto) const Spacer(),
                  const SizedBox(height: 14),
                  const Text(
                    'forgen.app',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;

  const _ModeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cobalt.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.55)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.cobalt,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final List<_StoryStat> stats;
  final String? calories;
  final String? calorieLabel;

  const _StatRow({required this.stats, this.calories, this.calorieLabel});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0)
                    const SizedBox(
                      width: 1,
                      height: 36,
                      child: ColoredBox(color: AppColors.border),
                    ),
                  Expanded(child: _StatCell(stat: stats[i])),
                ],
              ],
            ),
            if (calories != null) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Divider(height: 1, thickness: 1, color: AppColors.border),
              ),
              Text(
                calorieLabel ?? '',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                calories!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final _StoryStat stat;

  const _StatCell({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              stat.value,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _StoryScrim extends StatelessWidget {
  const _StoryScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 0.95,
          colors: [Color(0x474A9EFF), Color(0x00000000)],
        ),
      ),
    );
  }
}

class _StoryFinishPhoto extends StatefulWidget {
  final WorkoutSummaryData summary;

  const _StoryFinishPhoto({required this.summary});

  @override
  State<_StoryFinishPhoto> createState() => _StoryFinishPhotoState();
}

class _StoryFinishPhotoState extends State<_StoryFinishPhoto> {
  String? _url;

  @override
  void initState() {
    super.initState();
    final local = widget.summary.finishPhotoLocalPath;
    if (local != null && local.isNotEmpty) return;
    final storage = widget.summary.finishPhotoStoragePath;
    if (storage == null || storage.isEmpty) return;
    FeedMediaService().signedUrlForPath(storage).then((url) {
      if (mounted) setState(() => _url = url);
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.summary.finishPhotoLocalPath;
    final Widget image;
    if (local != null && local.isNotEmpty) {
      image = Image.file(
        File(local),
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } else if (_url != null) {
      image = CachedNetworkImage(
        imageUrl: _url!,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
      );
    } else {
      image = const SizedBox.shrink();
    }

    return SizedBox.expand(
      child: ColoredBox(
        color: AppColors.black,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            return const RadialGradient(
              radius: 0.95,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: [0.72, 0.84, 1],
            ).createShader(bounds);
          },
          child: image,
        ),
      ),
    );
  }
}

enum _StoryStatKind { calories }

class _StoryStat {
  final String label;
  final String value;
  final _StoryStatKind? kind;

  const _StoryStat(this.label, this.value, {this.kind});
}

class _StoryHighlight {
  final String text;
  final Color color;

  const _StoryHighlight(this.text, this.color);
}

String? _modeLabel(WorkoutSummaryData summary, AppLocalizations l10n) {
  if (summary.hasHyroxSplits) return l10n.hyroxSystemBadge;
  if (summary.isRunner) return l10n.runnerSystemBadge;
  return null;
}

String? _subtitle(WorkoutSummaryData summary, AppLocalizations l10n) {
  if (summary.isRunner && !summary.hasHyroxSplits) {
    final surface = summary.workout.runnerSurface;
    if (surface != null) return runnerSurfaceLabel(l10n, surface);
    return null;
  }
  final count = summary.exercises.length;
  if (count <= 0) return null;
  return l10n.shareStoryExerciseCount(count);
}

String? _calorieLine(WorkoutSummaryData summary, List<_StoryStat> stats) {
  if (!summary.hasCalorieEstimate) return null;
  if (stats.any((stat) => stat.kind == _StoryStatKind.calories)) return null;
  return QuantityFormat.kcal(summary.calorieEstimate.caloriesKcal!);
}

WorkoutSet? _cardioSet(WorkoutSummaryData summary) {
  for (final ex in summary.workout.exercises) {
    for (final set in ex.sets) {
      if (set.completed && set.isCardio) return set;
    }
  }
  return null;
}

String _clock(WorkoutSummaryData summary, {int? seconds}) {
  final value = seconds ?? (_cardioSet(summary)?.durationSeconds);
  if (value != null && value > 0) return CardioFormat.duration(value);
  if (summary.durationMinutes > 0) {
    return CardioFormat.duration(summary.durationMinutes * 60);
  }
  return '—';
}

List<_StoryStat> _storyStats(
  WorkoutSummaryData summary,
  String unitSystem,
  AppLocalizations l10n,
) {
  if (summary.hasHyroxSplits) {
    return [
      _StoryStat(l10n.runnerTime, _clock(summary, seconds: summary.hyroxTotalSeconds)),
      _StoryStat(l10n.shareStoryStations, '${summary.hyroxSplits.length}'),
      if (summary.hasCalorieEstimate)
        _StoryStat(
          l10n.caloriesBurned,
          QuantityFormat.integer(summary.calorieEstimate.caloriesKcal!),
          kind: _StoryStatKind.calories,
        )
      else
        _StoryStat(l10n.minutes, '${summary.durationMinutes}'),
    ];
  }

  if (summary.isRunner) {
    final cardio = _cardioSet(summary);
    return [
      _StoryStat(
        l10n.runnerDistance,
        CardioFormat.distance(cardio?.distanceMeters, unitSystem),
      ),
      _StoryStat(
        l10n.runnerAvgPace,
        CardioFormat.pace(summary.workout.runnerAvgPaceSecPerKm, unitSystem),
      ),
      _StoryStat(l10n.runnerTime, _clock(summary)),
    ];
  }

  final maxWeight = summary.maxWeightKg;
  final third = maxWeight != null && maxWeight > 0
      ? _StoryStat(l10n.maxWeight, UnitConverter.formatGymMass(maxWeight, unitSystem))
      : _StoryStat(l10n.reps, QuantityFormat.integer(summary.totalReps));

  return [
    _StoryStat(l10n.minutes, '${summary.durationMinutes}'),
    _StoryStat(l10n.volume, UnitConverter.formatVolume(summary.totalVolumeKg, unitSystem)),
    third,
  ];
}

_StoryHighlight? _storyHighlight(
  WorkoutSummaryData summary,
  String unitSystem,
  AppLocalizations l10n,
) {
  final gym = !summary.isRunner && !summary.hasHyroxSplits;

  if (gym) {
    final percent = summary.volumeImprovementPercent;
    if (percent != null && percent >= 1) {
      return _StoryHighlight(
        l10n.summaryVolumeUp(percent.toStringAsFixed(0)),
        AppColors.cobalt,
      );
    }
  }

  if (summary.hasNewPersonalRecords) {
    return _StoryHighlight(
      l10n.shareStoryNewRecords(summary.newPersonalRecords.length),
      AppColors.prHighlight,
    );
  }

  if (summary.isRunner && !summary.hasHyroxSplits) {
    final gain = summary.workout.runnerElevationGainMeters;
    final outdoor = summary.workout.runnerRoute.length >= 2;
    if (outdoor && gain != null && gain > 0) {
      return _StoryHighlight(
        '${l10n.runnerElevationGain} · ${CardioFormat.elevation(gain, unitSystem)}',
        AppColors.cobalt,
      );
    }
  }

  return null;
}
