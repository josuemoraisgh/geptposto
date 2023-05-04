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
  final List<StreamAssistido>? assistidoList;
  final StackFit? stackFit;
  const AssistidoFaceDetectorView(
      {super.key,
      this.assistidoList,
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
  final _assistidosStoreList = Modular.get<AssistidosStoreList>();
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
      _assistidosStoreList.addSetPhoto(widget.assistido, uint8ListImage,
          isUpload: true);
    }
    Modular.to.pop();
  }

  Future<void> _processImage(
      CameraImage cameraImage, int sensorOrientation) async {
    String? assistidoNome;
    InputImage? inputImage =
        convertCameraImageToInputImage(cameraImage, sensorOrientation);
    if (inputImage == null || !_canProcess || _isBusy) return;
    _isBusy = true;
    final faces =
        await _assistidoMmlService.faceDetector.processImage(inputImage);
    if (widget.assistidoList != null) {
      if (faces.isNotEmpty) {
        final assisitidoIndex = await _assistidoMmlService.predict(
            cameraImage, sensorOrientation, widget.assistidoList!);
        if (assisitidoIndex != null && widget.chamadaFunc != null) {
          var assist = widget.assistidoList!
              .firstWhere((element) => element.ident == assisitidoIndex);
          assistidoNome = assist.nomeM1;
          widget.chamadaFunc!(assist);
        } else {
          assistidoNome = "";
        }
      }
    }
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = FaceDetectorPainter(
          assistidoNome,
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
    super.dispose();
  }
}
