import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';

/// Indicador de carga con el logo FitForge (fondo transparente sobre UI oscura).
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
    final logoSize = size * 0.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.orange,
                  backgroundColor: AppColors.slate.withValues(alpha: 0.35),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // BlendMode.lighten oculta el negro del PNG y deja solo el logo.
              ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.lighten),
                child: Image.asset(
                  'assets/images/logo_icon.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.86, 0.86),
                    end: const Offset(1, 1),
                    duration: 950.ms,
                    curve: Curves.easeInOut,
                  )
                  .fade(begin: 0.65, end: 1, duration: 950.ms),
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
