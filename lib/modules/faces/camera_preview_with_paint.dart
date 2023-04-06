import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

List<CameraDescription> cameras = [];

enum ScreenMode { liveFeed, gallery }

class CameraPreviewWithPaint extends StatefulWidget {
  const CameraPreviewWithPaint(
      {Key? key,
      required this.title,
      required this.customPaint,
      required this.onImage,
      this.initialDirection = CameraLensDirection.back,
      required this.cameras})
      : super(key: key);

  final String title;
  final CustomPaint? customPaint;
  final Function(InputImage inputImage) onImage;
  final CameraLensDirection initialDirection;
  final List<CameraDescription> cameras;

  @override
  State<CameraPreviewWithPaint> createState() => _CameraPreviewWithPaintState();
}

class _CameraPreviewWithPaintState extends State<CameraPreviewWithPaint> {
  late Future<bool> isInicialized;
  CameraController? _controller;
  int _cameraIndex = -1;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;
  bool _changingCameraLens = false;

  Future<bool> init() async {
    if (cameras.any(
      (element) =>
          element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere((element) =>
            element.lensDirection == widget.initialDirection &&
            element.sensorOrientation == 90),
      );
    } else {
      for (var i = 0; i < cameras.length; i++) {
        if (cameras[i].lensDirection == widget.initialDirection) {
          _cameraIndex = i;
          break;
        }
      }
    }

    if (_cameraIndex != -1) {
      await _startLiveFeed();
      return true;
    } else {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    isInicialized = init();
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
      future: isInicialized,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) => Scaffold(
            body: _liveFeedBody(snapshot),
            floatingActionButton: _floatingActionButton(snapshot),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          ));

  Widget? _floatingActionButton(AsyncSnapshot<bool> snapshot) {
    if (snapshot.data != null) {
      if ((cameras.length != 1) && (snapshot.hasData)) {
        return SizedBox(
            height: 70.0,
            width: 70.0,
            child: FloatingActionButton(
              onPressed: _switchLiveCamera,
              child: Icon(
                Platform.isIOS
                    ? Icons.flip_camera_ios_outlined
                    : Icons.flip_camera_android_outlined,
                size: 40,
              ),
            ));
      }
    }
    return null;
  }

  Widget _liveFeedBody(AsyncSnapshot<bool> snapshot) {
    if ((snapshot.data != null) && (_controller != null)) {
      if ((cameras.length != 1) &&
          (snapshot.hasData) &&
          (_controller!.value.isInitialized)) {
        final size = MediaQuery.of(context).size;
        // calculate scale depending on screen and camera ratios
        // this is actually size.aspectRatio / (1 / camera.aspectRatio)
        // because camera preview size is received as landscape
        // but we're calculating for portrait orientation
        var scale = size.aspectRatio * _controller!.value.aspectRatio;

        // to prevent scaling down, invert the value
        if (scale < 1) scale = 1 / scale;

        return Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Transform.scale(
                scale: scale,
                child: Center(
                  child: _changingCameraLens
                      ? const Center(
                          child: Text('Changing camera lens'),
                        )
                      : CameraPreview(_controller!),
                ),
              ),
              if (widget.customPaint != null) widget.customPaint!,
              Positioned(
                bottom: 100,
                left: 50,
                right: 50,
                child: Slider(
                  value: zoomLevel,
                  min: minZoomLevel,
                  max: maxZoomLevel,
                  onChanged: (newSliderValue) {
                    setState(() {
                      zoomLevel = newSliderValue;
                      _controller!.setZoomLevel(zoomLevel);
                    });
                  },
                  divisions: (maxZoomLevel - 1).toInt() < 1
                      ? null
                      : (maxZoomLevel - 1).toInt(),
                ),
              )
            ],
          ),
        );
      }
    }
    return const Center(child: CircularProgressIndicator());
  }

  Future<void> _startLiveFeed() async {
    if (_controller == null) {
      final camera = cameras[_cameraIndex];
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller?.initialize().then((_) {
        if (!mounted) {
          return;
        }
        _controller?.getMinZoomLevel().then((value) {
          zoomLevel = value;
          minZoomLevel = value;
        });
        _controller?.getMaxZoomLevel().then((value) {
          maxZoomLevel = value;
        });
        _controller?.startImageStream(_processCameraImage);
        setState(() {});
      });
    }
  }

  Future _stopLiveFeed() async {
    if (_controller != null) {
      await _controller?.stopImageStream();
      await _controller?.dispose();
      _controller = null;
    }
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % cameras.length;
    await _stopLiveFeed();
    await _startLiveFeed();
    setState(() => _changingCameraLens = false);
  }

  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final camera = cameras[_cameraIndex];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
    widget.onImage(inputImage);
  }
}
