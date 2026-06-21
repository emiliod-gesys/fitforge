import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class FoodBarcodeScannerView extends StatefulWidget {
  final ValueChanged<String> onDetected;

  const FoodBarcodeScannerView({super.key, required this.onDetected});

  @override
  State<FoodBarcodeScannerView> createState() => _FoodBarcodeScannerViewState();
}

class _FoodBarcodeScannerViewState extends State<FoodBarcodeScannerView> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _locked = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleCapture(BarcodeCapture capture) {
    if (_locked) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _locked = true;
    widget.onDetected(code);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _handleCapture,
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
