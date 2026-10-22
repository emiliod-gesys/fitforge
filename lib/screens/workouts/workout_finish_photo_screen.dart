import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/center_aspect_crop.dart';
import '../../l10n/l10n_extensions.dart';

/// Foto al terminar un entreno. Devuelve el archivo o null si se omite.
class WorkoutFinishPhotoScreen extends StatefulWidget {
  const WorkoutFinishPhotoScreen({super.key});

  static Future<File?> show(BuildContext context) {
    return Navigator.of(context).push<File>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const WorkoutFinishPhotoScreen(),
      ),
    );
  }

  @override
  State<WorkoutFinishPhotoScreen> createState() => _WorkoutFinishPhotoScreenState();
}

class _WorkoutFinishPhotoScreenState extends State<WorkoutFinishPhotoScreen> {
  CameraController? _controller;
  CameraDescription? _front;
  CameraDescription? _back;
  CameraDescription? _active;
  int _mountGeneration = 0;
  bool _mirrorPreview = false;
  bool _opening = true;
  bool _capturing = false;
  bool _unavailable = false;

  bool get _canSwitch => _front != null && _back != null;

  @override
  void initState() {
    super.initState();
    _openCamera();
  }

  Future<void> _openCamera() async {
    try {
      final cameras = await availableCameras();
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front && _front == null) {
          _front = camera;
        } else if (camera.lensDirection == CameraLensDirection.back && _back == null) {
          _back = camera;
        }
      }
      final initial = _front ?? _back ?? (cameras.isEmpty ? null : cameras.first);
      if (initial == null) {
        if (mounted) {
          setState(() {
            _opening = false;
            _unavailable = true;
          });
        }
        return;
      }
      await _mountCamera(initial);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _opening = false;
        _unavailable = true;
      });
    }
  }

  Future<void> _toggleCamera() async {
    if (_capturing || _opening || !_canSwitch) return;
    final next = _active?.lensDirection == CameraLensDirection.front ? _back : _front;
    if (next == null) return;
    await _mountCamera(next);
  }

  Future<void> _mountCamera(CameraDescription description) async {
    final generation = ++_mountGeneration;
    final previous = _controller;
    _controller = null;
    if (mounted) setState(() => _opening = true);
    await previous?.dispose();
    if (!mounted || generation != _mountGeneration) return;

    try {
      final controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      try {
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } catch (_) {}
      if (!mounted || generation != _mountGeneration) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _active = description;
        _mirrorPreview = description.lensDirection == CameraLensDirection.front;
        _opening = false;
        _unavailable = false;
      });
    } catch (_) {
      if (!mounted || generation != _mountGeneration) return;
      setState(() {
        _opening = false;
        _unavailable = true;
      });
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) return;
    setState(() => _capturing = true);
    try {
      final shot = await controller.takePicture();
      final cropped = await compute(
        prepareWorkoutFinishPhoto,
        (await File(shot.path).readAsBytes(), _mirrorPreview),
      );
      final file = File('${shot.path}.jpg');
      await file.writeAsBytes(cropped, flush: true);
      if (!mounted) return;
      Navigator.of(context).pop(file);
    } catch (_) {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _skip() {
    if (_capturing) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized && !_unavailable;

    return PopScope(
      canPop: !_capturing,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _capturing ? null : _skip,
                  child: Text(
                    l10n.workoutFinishPhotoSkip,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ColoredBox(
                      color: AppColors.card,
                      child: _opening
                          ? const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : _unavailable || !ready
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      l10n.workoutFinishPhotoUnavailable,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white, height: 1.4),
                                    ),
                                  ),
                                )
                              : _CroppedCameraPreview(controller: controller),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 120,
                child: ready
                    ? Row(
                        children: [
                          const Expanded(child: SizedBox.shrink()),
                          Semantics(
                            button: true,
                            label: l10n.workoutFinishPhotoCapture,
                            child: GestureDetector(
                              onTap: _capturing ? null : _capture,
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                ),
                                alignment: Alignment.center,
                                child: _capturing
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _canSwitch
                                ? IconButton(
                                    onPressed: _capturing ? null : _toggleCamera,
                                    tooltip: l10n.workoutFinishPhotoSwitchCamera,
                                    icon: const Icon(
                                      Icons.cameraswitch_outlined,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CroppedCameraPreview extends StatelessWidget {
  const _CroppedCameraPreview({required this.controller});

  final CameraController controller;

  double get _displayedAspect {
    final raw = controller.value.aspectRatio;
    if (raw <= 0) return 3 / 4;
    final orientation = controller.value.previewPauseOrientation ??
        controller.value.lockedCaptureOrientation ??
        controller.value.deviceOrientation;
    final landscape = orientation == DeviceOrientation.landscapeLeft ||
        orientation == DeviceOrientation.landscapeRight;
    return landscape ? raw : 1 / raw;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final cameraAspect = _displayedAspect;
        final double frameW;
        final double frameH;
        if (maxW / maxH > cameraAspect) {
          frameH = maxH;
          frameW = frameH * cameraAspect;
        } else {
          frameW = maxW;
          frameH = frameW / cameraAspect;
        }
        final hole = centeredAspectRect(Size(frameW, frameH), workoutFinishPhotoAspectRatio);

        return Center(
          child: SizedBox(
            width: frameW,
            height: frameH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                CustomPaint(
                  painter: _CropWindowPainter(hole: hole),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CropWindowPainter extends CustomPainter {
  const _CropWindowPainter({required this.hole});

  final Rect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    final holePath = Path()..addRect(hole);
    canvas.drawPath(
      Path.combine(PathOperation.difference, overlay, holePath),
      Paint()..color = const Color(0xA6000000),
    );

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white;
    canvas.drawRect(hole.deflate(0.75), border);

    const length = 22.0;
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square
      ..color = Colors.white;
    canvas.drawLine(hole.topLeft, hole.topLeft + const Offset(length, 0), corner);
    canvas.drawLine(hole.topLeft, hole.topLeft + const Offset(0, length), corner);
    canvas.drawLine(hole.topRight, hole.topRight + const Offset(-length, 0), corner);
    canvas.drawLine(hole.topRight, hole.topRight + const Offset(0, length), corner);
    canvas.drawLine(hole.bottomLeft, hole.bottomLeft + const Offset(length, 0), corner);
    canvas.drawLine(hole.bottomLeft, hole.bottomLeft + const Offset(0, -length), corner);
    canvas.drawLine(hole.bottomRight, hole.bottomRight + const Offset(-length, 0), corner);
    canvas.drawLine(hole.bottomRight, hole.bottomRight + const Offset(0, -length), corner);
  }

  @override
  bool shouldRepaint(covariant _CropWindowPainter oldDelegate) => oldDelegate.hole != hole;
}
