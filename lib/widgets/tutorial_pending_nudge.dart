import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_accent.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../l10n/l10n_extensions.dart';
import '../providers/tutorial_controller.dart';

enum _NudgeChoice { markAll, remindLater }

class TutorialPendingNudge extends ConsumerStatefulWidget {
  const TutorialPendingNudge({super.key});

  @override
  ConsumerState<TutorialPendingNudge> createState() =>
      _TutorialPendingNudgeState();
}

class _TutorialPendingNudgeState extends ConsumerState<TutorialPendingNudge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hop;
  double _dragDx = 0;

  @override
  void initState() {
    super.initState();
    _hop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_runHopLoop());
    });
  }

  Future<void> _runHopLoop() async {
    while (mounted) {
      await _hop.forward(from: 0);
      if (!mounted) return;
      _hop.value = 0;
      await Future<void>.delayed(const Duration(milliseconds: 2800));
    }
  }

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  void _openTutorials() {
    context.go('/profile?section=tutorials');
  }

  Future<bool> _confirmDismiss() async {
    final choice = await showModalBottomSheet<_NudgeChoice>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final l10n = ctx.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.tutorialPendingNudgeSheetTitle,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tutorialPendingNudgeSheetBody,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, _NudgeChoice.markAll),
                  child: Text(l10n.tutorialPendingNudgeMarkAll),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, _NudgeChoice.remindLater),
                  child: Text(l10n.tutorialPendingNudgeRemindLater),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || choice == null) return false;
    final controller = ref.read(tutorialControllerProvider.notifier);
    if (choice == _NudgeChoice.markAll) {
      await controller.completeAll();
    } else {
      await controller.snoozeNudgeUntilTomorrow();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final tutorial = ref.watch(tutorialControllerProvider);
    if (!tutorial.showPendingNudge) return const SizedBox.shrink();
    final l10n = context.l10n;
    final accent = context.accentColor;
    final onAccent =
        accent.computeLuminance() > 0.45 ? Colors.black : Colors.white;
    final count = tutorial.pendingCount;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openTutorials,
      onHorizontalDragStart: (_) {},
      onHorizontalDragUpdate: (details) {
        final next = (_dragDx + details.delta.dx).clamp(-120.0, 0.0);
        if (next != _dragDx) setState(() => _dragDx = next);
      },
      onHorizontalDragEnd: (details) async {
        final flung = (details.primaryVelocity ?? 0) < -280;
        if (_dragDx < -40 || flung) {
          await _confirmDismiss();
        }
        if (mounted) setState(() => _dragDx = 0);
      },
      onHorizontalDragCancel: () {
        if (mounted) setState(() => _dragDx = 0);
      },
      child: AnimatedBuilder(
        animation: _hop,
        builder: (context, child) {
          final t = _hop.value;
          final hop = t < 0.45
              ? math.sin((t / 0.45) * math.pi) * 6
              : t < 0.8
                  ? math.sin(((t - 0.45) / 0.35) * math.pi) * 3
                  : 0.0;
          return Transform.translate(
            offset: Offset(_dragDx, hop),
            child: child,
          );
        },
        child: Material(
          color: accent,
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined, size: 18, color: onAccent),
                const SizedBox(width: 8),
                Text(
                  l10n.tutorialPendingNudgeLabel(count),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
