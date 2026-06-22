import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/l10n_extensions.dart';

class FoodBarcodeScannerView extends StatefulWidget {
  final Future<void> Function(String code) onDetected;

  const FoodBarcodeScannerView({super.key, required this.onDetected});

  @override
  FoodBarcodeScannerViewState createState() => FoodBarcodeScannerViewState();
}

class FoodBarcodeScannerViewState extends State<FoodBarcodeScannerView> {
  MobileScannerController? _controller;
  bool _locked = false;
  bool _starting = true;
  MobileScannerException? _startupError;

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  Future<void> _initScanner() async {
    setState(() {
      _starting = true;
      _startupError = null;
    });

    await _controller?.dispose();
    _controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );

    try {
      await _controller!.start();
      if (mounted) {
        setState(() {
          _starting = false;
          _startupError = null;
        });
      }
    } on MobileScannerException catch (error) {
      await _controller?.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _starting = false;
          _startupError = error;
        });
      }
    } catch (_) {
      await _controller?.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _starting = false;
          _startupError = const MobileScannerException(
            errorCode: MobileScannerErrorCode.genericError,
          );
        });
      }
    }
  }

  void unlock() {
    if (!mounted) return;
    setState(() => _locked = false);
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_locked) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _locked = true;
    try {
      await widget.onDetected(code);
    } finally {
      if (mounted) _locked = false;
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

  Widget _buildError(BuildContext context, MobileScannerException error) {
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
            onPressed: _initScanner,
            child: Text(context.l10n.foodBarcodeRetry),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_starting) {
      return Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_startupError != null) {
      return _buildError(context, _startupError!);
    }

    final controller = _controller;
    if (controller == null) {
      return _buildError(
        context,
        const MobileScannerException(errorCode: MobileScannerErrorCode.genericError),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: controller,
              onDetect: _handleCapture,
              errorBuilder: (context, error, child) => _buildError(context, error),
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
          ],
        ),
      ),
    );
  }
}

extension _BarcodeListExtension on List<Barcode> {
  Barcode? get firstOrNull => isEmpty ? null : first;
}
