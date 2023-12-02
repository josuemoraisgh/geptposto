import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:rx_notifier/rx_notifier.dart';
import '../../faces/camera_controle_service.dart';
import '../../faces/camera_preview_with_paint.dart';
import '../../faces/image_converter.dart';
import '../provider/assistido_provider_store.dart';
import '../services/face_detection_service.dart';
import '../../faces/painters/face_detector_painter.dart';
import '../assistidos_controller.dart';
import '../models/stream_assistido_model.dart';

class AssistidoFaceDetectorView extends StatefulWidget {
  final RxNotifier<List<StreamAssistido>>? assistidoProvavel;
  final RxNotifier<bool>? isPhotoChanged;
  final StreamAssistido? assistido;
  final List<StreamAssistido>? assistidoList;
  final StackFit? stackFit;
  const AssistidoFaceDetectorView(
      {super.key,
      this.assistidoList,
      this.assistidoProvavel,
      this.assistido,
      this.stackFit,
      this.isPhotoChanged});

  @override
  State<AssistidoFaceDetectorView> createState() =>
      _AssistidoFaceDetectorViewState();
}

class _AssistidoFaceDetectorViewState extends State<AssistidoFaceDetectorView> {
  late Future<bool> isInited;
  late final AssistidosProviderStore assistidosProviderStore;
  late final FaceDetectionService faceDetectionService;
  bool _canProcess = true, _isBusy = false;

  CameraService? _cameraService = Modular.get<CameraService>();
  CameraImage? cameraImage;
  List<Face>? faces;

  CustomPaint? _customPaint;

  Future<bool> init() async {
    assistidosProviderStore =
        Modular.get<AssistidosController>().assistidosProviderStore;
    faceDetectionService = assistidosProviderStore.faceDetectionService;
    _cameraService = _cameraService ?? CameraService();
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
            cameraService: _cameraService,
            customPaint: _customPaint,
            onPaintLiveImageFunc: _processImage,
            takeImageFunc: _cameraTakeImage,
            isRealTime: widget.assistidoList != null,
            stackFit: widget.stackFit,
            initialDirection: CameraLensDirection.back,
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<void> _cameraTakeImage(Uint8List? uint8ListImage) async {
    if (widget.assistidoList?.isNotEmpty ?? false) {
      if ((faces?.isNotEmpty ?? false) &&
          (cameraImage != null) &&
          (_cameraService?.camera != null)) {
        if (faces!.length > 1) {
          debugPrint("duas faces");
        }
        await faceDetectionService.predict(
            cameraImage!,
            _cameraService!.camera!.sensorOrientation,
            widget.assistidoList!,
            widget.assistidoProvavel!);
      }
    } else {
      if ((widget.assistido != null) && (uint8ListImage != null)) {
        widget.assistido?.addSetPhoto(uint8ListImage,
            isUpload: true);
        if (widget.isPhotoChanged != null) {
          widget.isPhotoChanged!.value = !widget.isPhotoChanged!.value;
        }
      }
      Modular.to.pop();
    }
  }

  Future<void> _processImage(CameraImage cameraImage, int sensorOrientation,
      Orientation orientation) async {
    this.cameraImage = cameraImage;
    final rotation = getImageRotation(sensorOrientation, orientation);
    InputImage? inputImage =
        await convertCameraImageToInputImageWithRotate(cameraImage, rotation);

    if (inputImage == null || !_canProcess || _isBusy) return;
    _isBusy = true;
    faces = await faceDetectionService.faceDetector.processImage(inputImage);
    if (faces?.isEmpty ?? true) {
      _isBusy = false;
      return;
    }
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = FaceDetectorPainter(
          [], faces!, inputImage.metadata!.size, sensorOrientation, rotation);
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
