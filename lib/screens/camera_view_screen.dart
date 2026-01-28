import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/gemini_service.dart';
import 'scan_result_screen.dart';

class CameraViewScreen extends StatefulWidget {
  const CameraViewScreen({super.key});

  @override
  State<CameraViewScreen> createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  final MobileScannerController _controller =
  MobileScannerController(returnImage: true);

  final GeminiService _geminiService = GeminiService();

  bool _isAnalyzing = false;
  Uint8List? _image;

  final List<String> _userAllergies = ['peanut', 'milk', 'soy', 'egg'];

  Future<void> _analyze() async {
    if (_image == null || _isAnalyzing) return;

    setState(() => _isAnalyzing = true);

    try {
      final result = await _geminiService.analyzeFoodImage(
        imageBytes: _image!,
        userAllergies: _userAllergies,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(result: result),
        ),
      );
    } catch (e) {
      debugPrint('Gemini error: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (capture.image != null && !_isAnalyzing) {
                _image = capture.image;
              }
            },
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(18),
                  shape: const CircleBorder(),
                ),
                onPressed: _analyze,
                child: _isAnalyzing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.camera, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
