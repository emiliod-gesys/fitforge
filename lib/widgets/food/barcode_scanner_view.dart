import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';

/// Full-screen barcode scan. Returns the raw code, or null if cancelled.
class FoodBarcodeScanPage extends StatefulWidget {
  const FoodBarcodeScanPage({super.key});

  static Future<String?> open(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const FoodBarcodeScanPage(),
      ),
    );
  }

  @override
  State<FoodBarcodeScanPage> createState() => _FoodBarcodeScanPageState();
}

class _FoodBarcodeScanPageState extends State<FoodBarcodeScanPage> {
  final _picker = ImagePicker();
  /// Owned by MobileScanner for live preview (autoStart).
  final _liveController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _locked = false;
  int _scannerKey = 0;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_locked) return;
    String? code;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        code = value;
        break;
      }
    }
    if (code == null) return;

    setState(() => _locked = true);
    try {
      await _liveController.stop();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop(code);
  }

  Future<void> _scanFromPhoto(ImageSource source) async {
    if (_locked) return;

    final status = await Permission.camera.request();
    if (!status.isGranted && source == ImageSource.camera) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.foodBarcodeCameraDenied)),
      );
      return;
    }

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 100,
      maxWidth: 3000,
      maxHeight: 3000,
    );
    if (image == null || !mounted) return;

    setState(() => _locked = true);

    // Use a dedicated controller for still-image analysis (works even if live preview fails).
    final analyzer = MobileScannerController(autoStart: false);
    try {
      final capture = await analyzer.analyzeImage(image.path);
      String? code;
      if (capture != null) {
        for (final barcode in capture.barcodes) {
          final value = barcode.rawValue?.trim();
          if (value != null && value.isNotEmpty) {
            code = value;
            break;
          }
        }
      }
      if (!mounted) return;
      if (code == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.foodBarcodeNotDetectedInPhoto)),
        );
        setState(() => _locked = false);
        return;
      }
      Navigator.of(context).pop(code);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.foodBarcodeGenericError)),
      );
      setState(() => _locked = false);
    } finally {
      await analyzer.dispose();
    }
  }

  Future<void> _retryLive() async {
    try {
      await _liveController.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _scannerKey++);
    try {
      await _liveController.start();
    } catch (_) {}
  }

  @override
  void dispose() {
    unawaited(_liveController.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.foodModeBarcode),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              l10n.foodBarcodeHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  key: ValueKey(_scannerKey),
                  controller: _liveController,
                  fit: BoxFit.cover,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) {
                    final detail = error.errorDetails?.message;
                    return ColoredBox(
                      color: Colors.black87,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              switch (error.errorCode) {
                                MobileScannerErrorCode.permissionDenied =>
                                  l10n.foodBarcodeCameraDenied,
                                MobileScannerErrorCode.unsupported =>
                                  l10n.foodBarcodeUnsupported,
                                _ => l10n.foodBarcodeGenericError,
                              },
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                            if (detail != null && detail.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                detail,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _locked ? null : () => _scanFromPhoto(ImageSource.camera),
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: Text(l10n.foodBarcodePhotoAction),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _locked ? null : () => _scanFromPhoto(ImageSource.gallery),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                              ),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(l10n.foodBarcodeGalleryAction),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => unawaited(_retryLive()),
                              child: Text(l10n.foodBarcodeRetry),
                            ),
                            if (error.errorCode == MobileScannerErrorCode.permissionDenied)
                              TextButton(
                                onPressed: openAppSettings,
                                child: Text(l10n.foodBarcodeOpenSettings),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_locked)
                  const ColoredBox(
                    color: Colors.black45,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Text(
                    l10n.foodBarcodePhotoFallback,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _locked ? null : () => _scanFromPhoto(ImageSource.camera),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                          ),
                          icon: const Icon(Icons.photo_camera_outlined, size: 18),
                          label: Text(l10n.foodBarcodePhotoAction),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _locked ? null : () => _scanFromPhoto(ImageSource.gallery),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                          ),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: Text(l10n.foodBarcodeGalleryAction),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Entry point inside the food-add "Código" tab: opens a dedicated scan screen.
class FoodBarcodeScannerView extends StatelessWidget {
  final Future<void> Function(String code) onDetected;

  const FoodBarcodeScannerView({
    super.key,
    required this.onDetected,
  });

  Future<void> _open(BuildContext context) async {
    final code = await FoodBarcodeScanPage.open(context);
    if (code == null || code.isEmpty) return;
    await onDetected(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = context.accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.foodBarcodeHint,
          style: const TextStyle(color: AppColors.textMuted, height: 1.35),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, size: 64, color: accent),
                const SizedBox(height: 16),
                Text(
                  l10n.foodBarcodePhotoFallback,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, height: 1.35),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => unawaited(_open(context)),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(l10n.foodModeBarcode),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
