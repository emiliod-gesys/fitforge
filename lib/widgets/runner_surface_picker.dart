import 'package:flutter/material.dart';

import '../core/runner/runner_standards.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';

Future<RunningSurface?> showRunnerSurfacePicker(BuildContext context) {
  final l10n = context.l10n;
  return showDialog<RunningSurface>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(l10n.runnerSurfaceTitle),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(
            l10n.runnerSurfaceHint,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, RunningSurface.asphalt),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.runnerSurfaceAsphalt, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(l10n.runnerSurfaceAsphaltDesc, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, RunningSurface.track),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.runnerSurfaceTrack, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(l10n.runnerSurfaceTrackDesc, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, RunningSurface.trail),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.runnerSurfaceTrail, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(l10n.runnerSurfaceTrailDesc, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    ),
  );
}

String runnerSurfaceLabel(AppLocalizations l10n, RunningSurface surface) {
  return switch (surface) {
    RunningSurface.asphalt => l10n.runnerSurfaceAsphalt,
    RunningSurface.track => l10n.runnerSurfaceTrack,
    RunningSurface.trail => l10n.runnerSurfaceTrail,
  };
}
