import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/ml_service.dart';
import '../../faces/camera_preview_with_paint.dart';
import '../../faces/painters/face_detector_painter.dart';

class AssistidoFaceDetectorPage extends StatefulWidget {
  final Map<String, dynamic> dadosTela;
  const AssistidoFaceDetectorPage({super.key, required this.dadosTela});

  @override
  State<AssistidoFaceDetectorPage> createState() => _AssistidoFaceDetectorPageState();
}

class _AssistidoFaceDetectorPageState extends State<AssistidoFaceDetectorPage> {
  final mlService = MLService();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableLandmarks: true,
        enableTracking: true),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.dadosTela['Title'])),
      body: CameraPreviewWithPaint(
        title: 'Face Detector',
        customPaint: _customPaint,
        onImage: processImage,
        initialDirection: CameraLensDirection.back, 
        cameras: widget.dadosTela['cameras'],
      ),
    );
  }

  Future<void> processImage(InputImage inputImage) async {
    bool? isPresented;
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    final faces = await _faceDetector.processImage(inputImage);
    if (widget.dadosTela["assistidos"] != null) {
      final assisitido =
          await mlService.predict(inputImage, widget.dadosTela["assistidos"]);
      if (assisitido != null) {
        isPresented = true;
        widget.dadosTela["chamadaFunc"](assisitido);
      } else {
        isPresented = false;
      }
    }
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = FaceDetectorPainter(
          isPresented,
          faces,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      _customPaint = CustomPaint(painter: painter);
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
