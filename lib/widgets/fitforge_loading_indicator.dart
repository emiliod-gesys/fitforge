import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/theme/app_colors.dart';

/// Animación de carga en bucle usando el video de marca FitForge.
class FitForgeLoadingIndicator extends StatefulWidget {
  final double size;
  final String? message;

  const FitForgeLoadingIndicator({
    super.key,
    this.size = 140,
    this.message,
  });

  @override
  State<FitForgeLoadingIndicator> createState() => _FitForgeLoadingIndicatorState();
}

class _FitForgeLoadingIndicatorState extends State<FitForgeLoadingIndicator> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/animations/loading.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        _controller
          ..setLooping(true)
          ..setVolume(0)
          ..play();
        setState(() => _ready = true);
      }).catchError((_) {
        if (mounted) setState(() => _failed = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: _failed
              ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
              : _ready
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller.value.size.width,
                          height: _controller.value.size.height,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2),
                    ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.message!,
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
