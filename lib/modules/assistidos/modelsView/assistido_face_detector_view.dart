import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../faces/camera_controle_service.dart';
import '../../faces/camera_preview_with_paint.dart';
import '../../faces/image_converter.dart';
import '../assistidos_controller.dart';
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
  late final AssistidosStoreList assistidosStoreList;
  late final AssistidoMLService assistidoMmlService;
  bool _canProcess = true, _isBusy = false;

  CameraService? _cameraService = Modular.get<CameraService>();
  List<StreamAssistido?> assistidoPresent = [];
  CustomPaint? _customPaint;

  Future<bool> init() async {
    assistidosStoreList =
        Modular.get<AssistidosController>().assistidosStoreList;
    assistidoMmlService = assistidosStoreList.assistidoMmlService;
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

  Future<void> _cameraTakeImage(Uint8List uint8ListImage) async {
    if ((widget.assistidoList?.isNotEmpty ?? false) &&
        (widget.chamadaFunc != null)) {
      for (var assistidoPres in assistidoPresent) {
        widget.chamadaFunc!(assistidoPres!);
      }
    } else {
      if (widget.assistido != null) {
        assistidosStoreList.addSetPhoto(widget.assistido, uint8ListImage,
            isUpload: true);
      }
      Modular.to.pop();
    }
  }

  Future<void> _processImage(CameraImage cameraImage, int sensorOrientation,
      Orientation orientation) async {
    List<String?> assistidoNomeList = [];
    StreamAssistido? aux;
    final rotation = getImageRotation(sensorOrientation, orientation);
    InputImage? inputImage =
        await convertCameraImageToInputImageWithRotate(cameraImage, rotation);

    if (inputImage == null || !_canProcess || _isBusy) return;
    _isBusy = true;
    final faces =
        await assistidoMmlService.faceDetector.processImage(inputImage);
    if (widget.assistidoList != null) {
      if (faces.isNotEmpty) {
        if (faces.length > 1) {
          debugPrint("duas faces");
        }
        final assistidosIdentList = await assistidoMmlService.predict(
            cameraImage, rotation, widget.assistidoList!);
        if (assistidosIdentList.isNotEmpty && widget.chamadaFunc != null) {
          for (var assistidosIdent in assistidosIdentList) {
            if (assistidosIdent != null && assistidosIdent != 999) {
              aux = widget.assistidoList!.firstWhere(
                  (element) => element.ident == assistidosIdent,
                  orElse: () => StreamAssistido.vazio());
              if (aux.nomeM1 != "Nome") {
                assistidoPresent.add(aux);
                assistidoNomeList.add(aux.nomeM1);
              } else {
                assistidoNomeList.add(null);
              }
            } else {
              assistidoNomeList.add(null);
            }
          }
        }
      }
    }
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = FaceDetectorPainter(assistidoNomeList, faces,
          inputImage.metadata!.size, sensorOrientation, rotation);
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
