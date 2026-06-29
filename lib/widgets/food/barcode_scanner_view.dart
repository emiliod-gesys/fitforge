import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/l10n_extensions.dart';

class FoodBarcodeScannerView extends StatefulWidget {
  final Future<void> Function(String code) onDetected;

  const FoodBarcodeScannerView({super.key, required this.onDetected});

  @override
  FoodBarcodeScannerViewState createState() => FoodBarcodeScannerViewState();
}

enum _ScannerPhase { checking, permissionDenied, ready, error }

class FoodBarcodeScannerViewState extends State<FoodBarcodeScannerView>
    with WidgetsBindingObserver {
  static const _foodBarcodeFormats = [
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.code128,
  ];

  final _picker = ImagePicker();

  MobileScannerController? _controller;
  _ScannerPhase _phase = _ScannerPhase.checking;
  String? _errorMessage;
  bool _locked = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepareLiveScanner();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || _phase != _ScannerPhase.ready) return;
    if (!controller.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_safeStart());
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_safeStop());
    }
  }

  void unlock() {
    if (!mounted) return;
    setState(() => _locked = false);
  }

  Future<void> retry() => _prepareLiveScanner();

  Future<void> ensureRunning() => _safeStart();

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
    final controller = MobileScannerController(formats: _foodBarcodeFormats);
    try {
      final capture = await controller.analyzeImage(path);
      if (capture == null) return null;
      for (final barcode in capture.barcodes) {
        final value = barcode.rawValue?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    } finally {
      await controller.dispose();
    }
  }

  Future<void> _prepareLiveScanner() async {
    setState(() {
      _phase = _ScannerPhase.checking;
      _errorMessage = null;
    });

    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;

    if (!status.isGranted) {
      await _controller?.dispose();
      _controller = null;
      setState(() => _phase = _ScannerPhase.permissionDenied);
      return;
    }

    await _controller?.dispose();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: _foodBarcodeFormats,
      autoStart: false,
    );

    if (!mounted) return;
    setState(() => _phase = _ScannerPhase.ready);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_safeStart());
    });
  }

  Future<void> _safeStart() async {
    final controller = _controller;
    if (controller == null || !mounted || _starting) return;
    if (controller.value.isRunning) return;

    _starting = true;
    try {
      await controller.start();
      if (!mounted) return;
      if (_phase == _ScannerPhase.error) {
        setState(() => _phase = _ScannerPhase.ready);
      }
    } on MobileScannerException catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = _ScannerPhase.error;
        _errorMessage = _messageForError(context, error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _ScannerPhase.error;
        _errorMessage = context.l10n.foodBarcodeGenericError;
      });
    } finally {
      _starting = false;
    }
  }

  Future<void> _safeStop() async {
    final controller = _controller;
    if (controller == null || !controller.value.isRunning) return;
    try {
      await controller.stop();
    } catch (_) {}
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
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
      await _safeStop();
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

  Widget _buildPermissionDenied(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 40),
          const SizedBox(height: 12),
          Text(
            l10n.foodBarcodeCameraDenied,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: retry,
            child: Text(l10n.foodBarcodeRetry),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: openAppSettings,
            child: Text(l10n.foodBarcodeOpenSettings),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerError(BuildContext context, {String? message}) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 40),
          const SizedBox(height: 12),
          Text(
            message ?? context.l10n.foodBarcodeGenericError,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: retry,
            child: Text(context.l10n.foodBarcodeRetry),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          switch (_phase) {
            _ScannerPhase.checking => const ColoredBox(
                color: Colors.black87,
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            _ScannerPhase.permissionDenied => _buildPermissionDenied(context),
            _ScannerPhase.error => _buildScannerError(context, message: _errorMessage),
            _ScannerPhase.ready => MobileScanner(
                controller: _controller!,
                fit: BoxFit.cover,
                onDetect: _handleCapture,
                errorBuilder: (context, error, child) =>
                    _buildScannerError(context, message: _messageForError(context, error)),
              ),
          },
          if (_phase == _ScannerPhase.ready)
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
