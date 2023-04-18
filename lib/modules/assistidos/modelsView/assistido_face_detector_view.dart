import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:geptposto/modules/faces/image_converter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../faces/camera_preview_with_paint.dart';
import '../models/stream_assistido_model.dart';
import '../services/assistido_ml_service.dart';
import '../../faces/painters/face_detector_painter.dart';
import '../stores/assistidos_store.dart';

class AssistidoFaceDetectorView extends StatefulWidget {
  final Function(StreamAssistido pessoa)? chamadaFunc;
  final StreamAssistido? assistido;
  final List<StreamAssistido>? assistidos;
  final StackFit? stackFit;
  const AssistidoFaceDetectorView(
      {super.key,
      this.assistidos,
      this.chamadaFunc,
      this.assistido,
      this.stackFit});

  @override
  State<AssistidoFaceDetectorView> createState() =>
      _AssistidoFaceDetectorViewState();
}

class _AssistidoFaceDetectorViewState extends State<AssistidoFaceDetectorView> {
  late Future<bool> isInited;
  bool _canProcess = true, _isBusy = false;
  final _assistidoMmlService = Modular.get<AssistidoMLService>();
  final _store = Modular.get<AssistidosStore>();
  List<CameraDescription>? _cameras;
  CustomPaint? _customPaint;

  Future<bool> init() async {
    _cameras = await Modular.get<Future<List<CameraDescription>>>();
    return true;
  }

  @override
  void initState() {
    super.initState();
    isInited = init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isInited,
      builder: (BuildContext context, AsyncSnapshot<bool> initCameras) {
        if (initCameras.data != null) {
          return CameraPreviewWithPaint(
            cameras: _cameras!,
            customPaint: _customPaint,
            onPaintLiveImageFunc: _processImage,
            takeImageFunc: _cameraTakeImage,
            stackFit: widget.stackFit,
            initialDirection: CameraLensDirection.back,
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<void> _cameraTakeImage(Uint8List uint8ListImage) async {
    if (widget.assistido != null) {
      _store.addSetPhoto(widget.assistido, uint8ListImage);
    }
    Modular.to.pop();
  }

  Future<void> _processImage(
      CameraImage cameraImage, int sensorOrientation) async {
    bool? isPresented;
    InputImage? inputImage =
        convertCameraImageToInputImage(cameraImage, sensorOrientation);
    if (inputImage == null || !_canProcess || _isBusy) return;
    _isBusy = true;
    final faces =
        await _assistidoMmlService.faceDetector.processImage(inputImage);
    if (widget.assistidos != null) {
      final assisitido = await _assistidoMmlService.predict(
          cameraImage, sensorOrientation, widget.assistidos!);
      if (assisitido != null && widget.chamadaFunc != null) {
        isPresented = true;
        widget.chamadaFunc!(assisitido);
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

  @override
  void dispose() {
    _canProcess = false;
    _assistidoMmlService.faceDetector.close();
    super.dispose();
  }
}
