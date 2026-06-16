import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../core/theme/app_colors.dart';

/// Indicador de carga con animación Lottie (fondo transparente).
class FitForgeLoadingIndicator extends StatelessWidget {
  final double size;
  final String? message;

  const FitForgeLoadingIndicator({
    super.key,
    this.size = 120,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Lottie.asset(
            'assets/animations/loading_spinner.json',
            width: size,
            height: size,
            fit: BoxFit.contain,
            repeat: true,
            frameRate: FrameRate.max,
            errorBuilder: (_, __, ___) => const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
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

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      barrierColor: Colors.black54,
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
      dismiss(context);
    }
  }

  static void dismiss(BuildContext context) {
    if (!context.mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}
