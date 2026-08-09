import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_glass.dart';
import '../../core/theme/app_tokens.dart';

/// Superficie glass sutil.
///
/// - Listas / cards: [blur] = false (solo tint + highlight + borde).
/// - Chrome (nav / sheets): [blur] = true con sigma bajo.
class FfGlass extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool blur;
  final double blurSigma;
  final double fillOpacity;
  final bool showTopHighlight;
  final bool showBorder;
  final bool showShadow;

  const FfGlass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppTokens.radiusLg)),
    this.padding,
    this.blur = false,
    this.blurSigma = AppGlass.blurSigma,
    this.fillOpacity = 0.62,
    this.showTopHighlight = true,
    this.showBorder = true,
    this.showShadow = true,
  });

  /// Barra inferior / chrome a ancho completo.
  const FfGlass.bar({
    super.key,
    required this.child,
    this.padding,
    this.blur = true,
    this.blurSigma = AppGlass.blurSigma,
    this.fillOpacity = 0.78,
    this.showTopHighlight = true,
    this.showBorder = true,
    this.showShadow = true,
  }) : borderRadius = BorderRadius.zero;

  /// Bottom sheet con radios superiores.
  const FfGlass.sheet({
    super.key,
    required this.child,
    this.padding,
    this.blur = true,
    this.blurSigma = AppGlass.blurSigma,
    this.fillOpacity = 0.86,
    this.showTopHighlight = true,
    this.showBorder = true,
    this.showShadow = false,
  }) : borderRadius = const BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusXl),
        );

  @override
  Widget build(BuildContext context) {
    final useBlur = blur && blurSigma > 0;

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    final layered = Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: ColoredBox(color: AppGlass.fill(fillOpacity)),
        ),
        if (showTopHighlight)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppGlass.tintHighlight(0.11),
                      AppGlass.tintHighlight(0.03),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.2, 0.5],
                  ),
                ),
              ),
            ),
          ),
        content,
      ],
    );

    final clipped = ClipRRect(
      borderRadius: borderRadius,
      child: useBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: layered,
            )
          : layered,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: showBorder
            ? Border.all(
                color: AppGlass.border(),
                width: AppTokens.borderHairline,
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: clipped,
    );
  }
}

/// Envuelve el contenido de un bottom sheet con glass.
class FfGlassSheetScaffold extends StatelessWidget {
  final Widget child;

  const FfGlassSheetScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FfGlass.sheet(
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}
