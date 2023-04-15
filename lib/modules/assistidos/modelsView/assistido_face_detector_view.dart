import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:geptposto/modules/faces/image_converter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';
import 'package:rx_notifier/rx_notifier.dart';
import '../../faces/camera_preview_with_paint.dart';
import '../models/assistido_models.dart';
import '../services/assistido_ml_service.dart';
import '../../faces/painters/face_detector_painter.dart';
import '../stores/assistidos_store.dart';
import 'package:image/image.dart' as imglib;

class AssistidoFaceDetectorView extends StatefulWidget {
  final Function(Assistido pessoa)? chamadaFunc;
  final Assistido? assistido;
  final List<Assistido>? assistidos;
  final RxNotifier<bool>? isPhotoChanged;
  final StackFit? stackFit;
  const AssistidoFaceDetectorView(
      {super.key,
      this.assistidos,
      this.chamadaFunc,
      this.assistido,
      this.isPhotoChanged,
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

  Future<void> _cameraTakeImage(XFile? xFileImage) async {
    if (widget.assistido != null && xFileImage != null) {
      widget.isPhotoChanged?.value = false;
      final now = DateTime.now();
      final DateFormat formatter = DateFormat('yyyy-MM-dd_H-m-s');
      if (widget.assistido!.photoName == "") {
        widget.assistido!.photoName =
            '${widget.assistido!.nomeM1.replaceAll(RegExp(r"\s+"), "")}_${formatter.format(now)}.jpg';
      }
      final Uint8List data = await xFileImage.readAsBytes();
      final imglib.Image? image = imglib.decodeJpg(data);
      final inputImage = InputImage.fromFilePath(xFileImage.path);
      final faceDetected =
          await _assistidoMmlService.faceDetector.processImage(inputImage);
      if (image != null) {
        if (faceDetected.isEmpty) {
          _store
              .setImage(widget.assistido!, imglib.encodeJpg(image))
              .then((_) => widget.isPhotoChanged?.value = true);
          _store.setRow(widget.assistido!);
        } else {
          final image2 = cropFace(image, faceDetected[0], step: 80);
          if (image2 != null) {
            _store
                .setImage(widget.assistido!, imglib.encodeJpg(image2))
                .then((_) => widget.isPhotoChanged?.value = true);
            _assistidoMmlService
                .renderizarImage(inputImage, image2)
                .then((fotoPoints) {
              widget.assistido!.fotoPoints = fotoPoints.cast<num>();
              _store.setRow(widget.assistido!);
            });
          }
        }
      }
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
