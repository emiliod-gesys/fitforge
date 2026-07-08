import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../core/theme/app_colors.dart';

/// Indicador de carga con animación Lottie (fondo transparente).
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
              Lottie.asset(
                'assets/animations/loading_spinner.json',
                width: spinnerSize,
                height: spinnerSize,
                fit: BoxFit.contain,
                repeat: true,
                frameRate: FrameRate.max,
                errorBuilder: (_, __, ___) => SizedBox(
                  width: spinnerSize,
                  height: spinnerSize,
                  child: const CircularProgressIndicator(color: AppColors.gold),
                ),
              ),
              Image.asset(
                'assets/images/logo_icon.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ],
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
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
