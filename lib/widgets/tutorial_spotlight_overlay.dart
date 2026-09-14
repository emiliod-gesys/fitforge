import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_accent.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../core/tutorials/tutorial_navigation.dart';
import '../core/tutorials/tutorial_targets.dart';
import '../l10n/l10n_extensions.dart';
import '../providers/tutorial_controller.dart';

class TutorialSpotlightOverlay extends ConsumerStatefulWidget {
  const TutorialSpotlightOverlay({super.key});

  @override
  ConsumerState<TutorialSpotlightOverlay> createState() =>
      _TutorialSpotlightOverlayState();
}

class _TutorialSpotlightOverlayState extends ConsumerState<TutorialSpotlightOverlay> {
  Rect? _hole;
  int _misses = 0;
  String? _measuringToken;

  @override
  Widget build(BuildContext context) {
    final tutorial = ref.watch(tutorialControllerProvider);
    final step = tutorial.activeStep;
    final tour = tutorial.activeTour;
    if (step == null || tour == null) {
      return const SizedBox.shrink();
    }

    final token = '${tutorial.activeTourId}:${tutorial.stepIndex}';
    if (_measuringToken != token) {
      _measuringToken = token;
      _misses = 0;
      _hole = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure(token));
    }

    final l10n = context.l10n;
    final accent = context.accentColor;
    final size = MediaQuery.sizeOf(context);
    final stepLabel = l10n.onboardingStepOf(tutorial.stepIndex + 1, tour.steps.length);
    final isLast = tutorial.stepIndex >= tour.steps.length - 1;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(
                hole: _hole,
                accent: accent,
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
            ),
          ),
          if (_hole != null)
            _TooltipCard(
              hole: _hole!,
              screenSize: size,
              accent: accent,
              stepLabel: stepLabel,
              title: step.title(l10n),
              body: step.body(l10n),
              nextLabel: isLast ? l10n.tutorialFinish : l10n.next,
              skipLabel: l10n.skip,
              onNext: () => ref.read(tutorialControllerProvider.notifier).next(),
              onSkip: () => ref.read(tutorialControllerProvider.notifier).skip(),
            ),
        ],
      ),
    );
  }

  Future<void> _measure(String token) async {
    if (!mounted || _measuringToken != token) return;
    final tutorial = ref.read(tutorialControllerProvider);
    final step = tutorial.activeStep;
    if (step == null) return;

    if (step.route != null) {
      TutorialNavigation.ensureStep(ref, step);
      var waited = 0;
      while (mounted &&
          _measuringToken == token &&
          waited < 40 &&
          !TutorialNavigation.matches(ref, step.route!)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        waited += 1;
      }
      if (!mounted || _measuringToken != token) return;
    }

    final key = TutorialTargets.keyFor(step.targetId);
    final ctx = key?.currentContext;
    if (ctx == null) {
      _misses += 1;
      final limit = step.optional ? 10 : 50;
      if (_misses >= limit) {
        ref.read(tutorialControllerProvider.notifier).next();
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (mounted && _measuringToken == token) {
        await _measure(token);
      }
      return;
    }

    if (!ctx.mounted) return;
    await Scrollable.ensureVisible(
      ctx,
      alignment: 0.35,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!mounted || !ctx.mounted || _measuringToken != token) return;

    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      _misses += 1;
      final limit = step.optional ? 10 : 50;
      if (_misses >= limit) {
        ref.read(tutorialControllerProvider.notifier).next();
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _measure(token);
      });
      return;
    }

    final origin = box.localToGlobal(Offset.zero);
    final rect = origin & box.size;
    if (!mounted || _measuringToken != token) return;
    setState(() => _hole = rect.inflate(8));
  }
}

class _TooltipCard extends StatelessWidget {
  final Rect hole;
  final Size screenSize;
  final Color accent;
  final String stepLabel;
  final String title;
  final String body;
  final String nextLabel;
  final String skipLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TooltipCard({
    required this.hole,
    required this.screenSize,
    required this.accent,
    required this.stepLabel,
    required this.title,
    required this.body,
    required this.nextLabel,
    required this.skipLabel,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = (screenSize.width - 32).clamp(240.0, 360.0);
    final spaceBelow = screenSize.height - hole.bottom;
    final placeBelow = spaceBelow > 200 || spaceBelow >= hole.top;

    final card = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cardElevated,
          borderRadius: AppTokens.borderRadiusMd,
          border: Border.all(color: accent.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stepLabel,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: onSkip,
                    child: Text(skipLabel),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: onNext,
                    child: Text(nextLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (placeBelow) {
      return Positioned(
        left: 16,
        right: 16,
        top: (hole.bottom + 16).clamp(16, screenSize.height - 180),
        child: Align(alignment: Alignment.topCenter, child: card),
      );
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: (screenSize.height - hole.top + 16).clamp(16, screenSize.height - 180),
      child: Align(alignment: Alignment.bottomCenter, child: card),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final Color accent;

  _SpotlightPainter({required this.hole, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    Path cut = overlay;
    if (hole != null) {
      final rounded = Path()
        ..addRRect(
          RRect.fromRectAndRadius(hole!, const Radius.circular(AppTokens.radiusMd)),
        );
      cut = Path.combine(PathOperation.difference, overlay, rounded);
    }
    canvas.drawPath(
      cut,
      Paint()..color = Colors.black.withValues(alpha: 0.72),
    );
    if (hole != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(hole!, const Radius.circular(AppTokens.radiusMd)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.hole != hole || oldDelegate.accent != accent;
  }
}
