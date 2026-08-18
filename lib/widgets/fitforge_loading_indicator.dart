import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../core/theme/app_accent.dart';
import '../core/theme/app_colors.dart';
import 'fitforge_logo.dart';

/// Indicador de carga: anillos del acento + isotipo.
class FitForgeLoadingIndicator extends StatelessWidget {
  /// Escala del anillo respecto al [size] base (anillos más grandes).
  static const spinnerScale = 1.65;

  /// Escala del isotipo respecto al [size] base (crece poco vs. el spinner).
  static const logoScale = 0.42;

  final double size;
  final String? message;

  const FitForgeLoadingIndicator({
    super.key,
    this.size = 140,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.fitForgeAccent;
    final spinnerSize = size * spinnerScale;
    final logoSize = size * logoScale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: spinnerSize,
          height: spinnerSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _AccentRings(
                size: spinnerSize,
                color: accent.accentColor,
                darkColor: accent.accentDark,
              ),
              FitForgeLogo.icon(height: logoSize),
            ],
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _AccentRings extends StatefulWidget {
  final double size;
  final Color color;
  final Color darkColor;

  const _AccentRings({
    required this.size,
    required this.color,
    required this.darkColor,
  });

  @override
  State<_AccentRings> createState() => _AccentRingsState();
}

class _AccentRingsState extends State<_AccentRings> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _AccentRingsPainter(
            turn: _controller.value,
            color: widget.color,
            darkColor: widget.darkColor,
          ),
        );
      },
    );
  }
}

class _AccentRingsPainter extends CustomPainter {
  final double turn;
  final Color color;
  final Color darkColor;

  const _AccentRingsPainter({
    required this.turn,
    required this.color,
    required this.darkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * (14 / 200);
    final center = size.center(Offset.zero);
    final outerRadius = size.shortestSide * (70 / 200) - stroke / 2;
    final innerRadius = size.shortestSide * (45 / 200) - stroke / 2;

    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final innerPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      turn * math.pi * 2 - math.pi / 2,
      0.65 * math.pi * 2,
      false,
      outerPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      -turn * math.pi * 2 - math.pi / 2,
      0.55 * math.pi * 2,
      false,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AccentRingsPainter oldDelegate) {
    return oldDelegate.turn != turn ||
        oldDelegate.color != color ||
        oldDelegate.darkColor != darkColor;
  }
}

/// Centra la animación de carga en pantallas completas o secciones.
class FitForgeLoadingScreen extends StatelessWidget {
  final String? message;

  const FitForgeLoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: FitForgeLoadingIndicator(message: message));
  }
}

/// Overlay modal de carga compatible con GoRouter (cierra el diálogo correcto).
abstract final class FitForgeLoadingOverlay {
  static Future<T> run<T>(
    BuildContext context, {
    required Future<T> Function() task,
    String? message,
  }) async {
    if (!context.mounted) {
      throw StateError('Context is not mounted');
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(48),
          child: FitForgeLoadingIndicator(message: message),
        ),
      ),
    );

    try {
      return await task();
    } finally {
      _dismissNavigator(navigator);
    }
  }

  static void dismiss(BuildContext context) {
    if (!context.mounted) return;
    _dismissNavigator(Navigator.of(context, rootNavigator: true));
  }

  static void _dismissNavigator(NavigatorState navigator) {
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}
