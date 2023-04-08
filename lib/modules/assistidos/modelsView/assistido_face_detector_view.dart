import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';
import '../../faces/camera_preview_with_paint.dart';
import '../models/assistido_models.dart';
import '../services/assistido_ml_service.dart';
import '../../faces/painters/face_detector_painter.dart';
import '../services/face_detector_service.dart';
import '../stores/assistidos_store.dart';

class AssistidoFaceDetectorView extends StatefulWidget {
  final Function(Assistido pessoa)? chamadaFunc;
  final Assistido? assistido;
  final List<Assistido>? assistidos;
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
  bool _canProcess = true, _isBusy = false;
  late Future<bool> _isInitedCameras;
  final _assistidoMmlService = Modular.get<AssistidoMLService>();
  final _faceDetectorService = Modular.get<FaceDetectorService>();
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
    _isInitedCameras = init();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth,
          maxHeight: screenHeight,
        ),
        child: FutureBuilder<File?>(
          future: (widget.assistido != null)
              ? _store.getImg(widget.assistido!)
              : null,
          builder: (BuildContext context, AsyncSnapshot<File?> imageFile) {
            if (imageFile.data != null) {
              return FutureBuilder<bool>(
                future: imageFile.data!.exists(),
                builder: (BuildContext context, AsyncSnapshot<bool> isExists) {
                  if (isExists.hasData) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.file(imageFile.data!),
                        const SizedBox(height: 4.0),
                        FloatingActionButton(
                          onPressed: () {
                            _clearImage();
                          },
                          backgroundColor: Colors.redAccent,
                          tooltip: 'Delete',
                          child: const Icon(Icons.delete),
                        ),
                      ],
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              );
            } else {
              return FutureBuilder<bool>(
                future: _isInitedCameras,
                builder:
                    (BuildContext context, AsyncSnapshot<bool> initCameras) {
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
          },
        ),
      ),
    );
  }

  Future<void> _cameraTakeImage(XFile? pickedImage) async {
    if (widget.assistido != null && pickedImage != null) {
      final now = DateTime.now();
      final DateFormat formatter = DateFormat('yyyy-MM-dd_H-m-s');
      if (widget.assistido!.photoName == "") {
        widget.assistido!.photoName =
            '${widget.assistido!.nomeM1.replaceAll(RegExp(r"\s+"), "")}_${formatter.format(now)}.jpg';
      }
      await _store.setImage(widget.assistido!, await pickedImage.readAsBytes());
      setState(() {});
    }
  }

  Future<void> _processImage(InputImage? inputImage) async {
    bool? isPresented;
    if (inputImage == null || !_canProcess || _isBusy) return;
    _isBusy = true;
    final faces =
        await _faceDetectorService.faceDetector.processImage(inputImage);
    if (widget.assistidos != null) {
      final assisitido = await _assistidoMmlService.predict(
          _faceDetectorService, inputImage, widget.assistidos!);
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

  void _clearImage() {
    if (widget.assistido != null) {
      setState(() {
        _store.deleteImage(widget.assistido!);
      });
    }
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetectorService.faceDetector.close();
    super.dispose();
  }
}
