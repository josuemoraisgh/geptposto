import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/assistido_models.dart';
import '../services/assistido_ml_service.dart';
import '../../faces/camera_preview_with_paint.dart';
import '../../faces/painters/face_detector_painter.dart';
import '../services/face_detector_service.dart';

class AssistidoFaceDetectorView extends StatefulWidget {
  final List<Assistido>? assistidos;
  final Function(Assistido pessoa) chamadaFunc;
  const AssistidoFaceDetectorView(
      {super.key, required this.assistidos, required this.chamadaFunc});

  @override
  State<AssistidoFaceDetectorView> createState() =>
      _AssistidoFaceDetectorViewState();
}

class _AssistidoFaceDetectorViewState extends State<AssistidoFaceDetectorView> {
  final _assistidoMmlService = Modular.get<AssistidoMLService>();
  final _faceDetectorService = Modular.get<FaceDetectorService>();
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;

  @override
  void dispose() {
    _canProcess = false;
    _faceDetectorService.faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CameraDescription>>(
        future: Modular.get<Future<List<CameraDescription>>>(),
        builder: (BuildContext context,
            AsyncSnapshot<List<CameraDescription>> cameras) {
          if (cameras.hasData) {
            if (cameras.data != null) {
              return CameraPreviewWithPaint(
                title: 'Face Detector',
                customPaint: _customPaint,
                onImage: processImage,
                cameras: cameras.data!,
                initialDirection: CameraLensDirection.back,
              );
            }
          }
          return const Center(child: CircularProgressIndicator());
        });
  }

  Future<void> processImage(InputImage? inputImage) async {
    bool? isPresented;
    if (!_canProcess && inputImage == null) return;
    if (_isBusy) return;
    _isBusy = true;
    final faces =
        await _faceDetectorService.faceDetector.processImage(inputImage!);
    if (widget.assistidos != null) {
      final assisitido = await _assistidoMmlService.predict(
          _faceDetectorService, inputImage, widget.assistidos!);
      if (assisitido != null) {
        isPresented = true;
        widget.chamadaFunc(assisitido);
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
