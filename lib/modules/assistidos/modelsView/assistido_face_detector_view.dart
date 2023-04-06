import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';
import '../models/assistido_models.dart';
import '../services/assistido_ml_service.dart';
import '../../faces/camera_preview_with_paint.dart';
import '../../faces/painters/face_detector_painter.dart';
import '../services/face_detector_service.dart';
import '../stores/assistidos_store.dart';

class AssistidoFaceDetectorView extends StatefulWidget {
  final Assistido? assistido;
  final List<Assistido>? assistidos;
  final Function(Assistido pessoa)? chamadaFunc;
  const AssistidoFaceDetectorView(
      {super.key, this.assistidos, this.chamadaFunc, this.assistido});

  @override
  State<AssistidoFaceDetectorView> createState() =>
      _AssistidoFaceDetectorViewState();
}

class _AssistidoFaceDetectorViewState extends State<AssistidoFaceDetectorView> {
  final _assistidoMmlService = Modular.get<AssistidoMLService>();
  final _faceDetectorService = Modular.get<FaceDetectorService>();
  final _store = Modular.get<AssistidosStore>();
  bool _isBusy = false;
  CustomPaint? _customPaint;

  @override
  void dispose() {
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
              if (widget.assistido != null) {
                return FutureBuilder<File?>(
                  future: _store.getImg(widget.assistido!),
                  builder:
                      (BuildContext context, AsyncSnapshot<File?> imageFile) {
                    if (imageFile.hasData) {
                      if (imageFile.data != null) {
                        return _imageCard(context, imageFile.data);
                      }
                    }
                    return CameraPreviewWithPaint(
                      title: 'Face Detector',
                      customPaint: _customPaint,
                      onImage: processImage,
                      cameras: cameras.data!,
                      takeImage: _cameraImage,
                      initialDirection: CameraLensDirection.back,
                    );
                  },
                );
              }
              return CameraPreviewWithPaint(
                title: 'Face Detector',
                customPaint: _customPaint,
                onImage: processImage,
                cameras: cameras.data!,
                takeImage: _cameraImage,
                initialDirection: CameraLensDirection.back,
              );
            }
          }
          return const Center(child: CircularProgressIndicator());
        });
  }

  Widget _imageCard(BuildContext context, File? imageFile) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Card(
            elevation: 4.0,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _image(context, imageFile),
            ),
          ),
          const SizedBox(height: 24.0),
          _menu(imageFile),
        ],
      ),
    );
  }

  Widget _image(BuildContext context, File? imageFile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    if (imageFile != null) {
      return FutureBuilder<bool>(
          future: imageFile.exists(),
          builder: (BuildContext context, AsyncSnapshot<bool> isExists) {
            if (isExists.hasData) {
              return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 0.8 * screenWidth,
                    maxHeight: 0.7 * screenHeight,
                  ),
                  child: Image.file(imageFile));
            }
            return const Center(child: CircularProgressIndicator());
          });
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _menu(File? imageFile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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

  Future<void> processImage(InputImage? inputImage) async {
    bool? isPresented;
    if (inputImage == null) return;
    if (_isBusy) return;
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

  Future<void> _cameraImage(XFile? pickedImage) async {
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

  void _clearImage() {
    if (widget.assistido != null) {
      setState(() {
        _store.deleteImage(widget.assistido!);
      });
    }
  }
}
