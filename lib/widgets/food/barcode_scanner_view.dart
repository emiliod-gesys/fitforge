import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/l10n_extensions.dart';

class FoodBarcodeScannerView extends StatefulWidget {
  final Future<void> Function(String code) onDetected;
  final bool isActive;

  const FoodBarcodeScannerView({
    super.key,
    required this.onDetected,
    this.isActive = true,
  });

  @override
  FoodBarcodeScannerViewState createState() => FoodBarcodeScannerViewState();
}

class FoodBarcodeScannerViewState extends State<FoodBarcodeScannerView> {
  static const _foodBarcodeFormats = [
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.code128,
  ];

  final _picker = ImagePicker();
  late final MobileScannerController _controller;
  bool _locked = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: _foodBarcodeFormats,
      autoStart: false,
    );
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_startIfNeeded()));
    }
  }

  @override
  void didUpdateWidget(FoodBarcodeScannerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      unawaited(_startIfNeeded());
    } else if (!widget.isActive && oldWidget.isActive) {
      unawaited(_stopIfNeeded());
    }
  }

  void unlock() {
    if (!mounted) return;
    setState(() => _locked = false);
  }

  Future<void> retry() => _startIfNeeded();

  Future<void> ensureRunning() => _startIfNeeded();

  Future<void> scanFromPhoto({ImageSource source = ImageSource.camera}) async {
    if (_locked) return;

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (image == null || !mounted) return;

    setState(() => _locked = true);
    try {
      final code = await _decodeBarcodeFromImagePath(image.path);
      if (!mounted) return;

      if (code != null && code.isNotEmpty) {
        await widget.onDetected(code);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.foodBarcodeNotDetectedInPhoto)),
        );
      }
    } finally {
      if (mounted) setState(() => _locked = false);
    }
  }

  Future<String?> _decodeBarcodeFromImagePath(String path) async {
    final capture = await _controller.analyzeImage(path);
    if (capture == null) return null;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  Future<void> _startIfNeeded() async {
    if (!mounted || !widget.isActive || _starting) return;
    if (_controller.value.isRunning || _controller.value.isStarting) return;

    _starting = true;
    try {
      await _controller.start();
    } on MobileScannerException catch (_) {
      // errorBuilder shows the UI; nothing else to do here.
    } catch (_) {
      // errorBuilder shows the UI; nothing else to do here.
    } finally {
      _starting = false;
    }
  }

  Future<void> _stopIfNeeded() async {
    if (!_controller.value.isRunning) return;
    try {
      await _controller.stop();
    } catch (_) {}
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_locked || !widget.isActive) return;

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
      await _stopIfNeeded();
      await widget.onDetected(code);
    } finally {
      if (mounted) setState(() => _locked = false);
    }
  }

  String _messageForError(BuildContext context, MobileScannerException error) {
    final l10n = context.l10n;
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied => l10n.foodBarcodeCameraDenied,
      MobileScannerErrorCode.unsupported => l10n.foodBarcodeUnsupported,
      _ => l10n.foodBarcodeGenericError,
    };
  }

  Widget _buildScannerError(BuildContext context, MobileScannerException error) {
    final l10n = context.l10n;
    final isPermission = error.errorCode == MobileScannerErrorCode.permissionDenied;

    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 40),
          const SizedBox(height: 12),
          Text(
            _messageForError(context, error),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: retry,
            child: Text(l10n.foodBarcodeRetry),
          ),
          if (isPermission) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: openAppSettings,
              child: Text(l10n.foodBarcodeOpenSettings),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            onDetect: _handleCapture,
            errorBuilder: _buildScannerError,
            placeholderBuilder: (_) => const ColoredBox(
              color: Colors.black87,
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Icon(Icons.qr_code_scanner, color: Colors.white70),
            ),
          ),
          if (_locked)
            const ColoredBox(
              color: Colors.black45,
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
