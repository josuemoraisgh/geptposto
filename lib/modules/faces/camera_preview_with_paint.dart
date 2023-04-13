import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewWithPaint extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Future<void> Function(CameraImage cameraImage, int sensorOrientation)?
      onPaintLiveImageFunc;
  final Future<void> Function(XFile? xfile)? takeImageFunc;
  final dynamic Function()? switchLiveCameraFunc;
  final CameraLensDirection initialDirection;
  final StackFit? stackFit;
  final CustomPaint? customPaint;
  const CameraPreviewWithPaint({
    Key? key,
    required this.cameras,
    this.customPaint,
    this.onPaintLiveImageFunc,
    this.takeImageFunc,
    this.switchLiveCameraFunc,
    this.stackFit,
    this.initialDirection = CameraLensDirection.back,
  }) : super(key: key);
  @override
  State<CameraPreviewWithPaint> createState() => _CameraPreviewWithPaintState();
}

class _CameraPreviewWithPaintState extends State<CameraPreviewWithPaint> {
  CameraController? _controller;
  int _cameraIndex = -1;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;
  bool _changingCameraLens = false;
  late Future<bool> isStarted; //Não retirar muito importante

  Future<bool> init() async {
    if (widget.cameras.any(
      (element) =>
          element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = widget.cameras.indexOf(
        widget.cameras.firstWhere((element) =>
            element.lensDirection == widget.initialDirection &&
            element.sensorOrientation == 90),
      );
    } else {
      for (var i = 0; i < widget.cameras.length; i++) {
        if (widget.cameras[i].lensDirection == widget.initialDirection) {
          _cameraIndex = i;
          break;
        }
      }
    }

    if (_cameraIndex != -1) {
      await _startLiveFeed(_cameraIndex);
      return true;
    } else {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    isStarted = init();
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isStarted,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if ((snapshot.data != null) && (_controller != null)) {
          if ((widget.cameras.isNotEmpty) &&
              (snapshot.hasData) &&
              (_controller!.value.isInitialized)) {
            return Stack(
              fit: widget.stackFit ?? StackFit.passthrough,
              children: <Widget>[
                _changingCameraLens
                    ? const Center(
                        child: Text('Changing camera lens'),
                      )
                    : CameraPreview(_controller!),
                if (widget.customPaint != null) widget.customPaint!,
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _floatingActionButton(),
                ),
              ],
            );
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _floatingActionButton() {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                _cameraTakeImage();
              },
              child: Icon(
                (widget.initialDirection == CameraLensDirection.back)
                    ? Icons.photo_camera_back
                    : Icons.photo_camera_front,
                size: 40,
              ),
            ),
            const SizedBox(width: 24.0),
            ElevatedButton(
              onPressed: () {
                _switchLiveCamera();
              },
              child: Icon(
                Platform.isIOS
                    ? Icons.flip_camera_ios_outlined
                    : Icons.flip_camera_android_outlined,
                size: 40,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24.0),
        Slider(
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
      ],
    );
  }

  Future<void> _startLiveFeed(int cameraIndex) async {
    if (_controller == null) {
      final camera = widget.cameras[cameraIndex];
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller?.initialize().then(
        (_) {
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
          if (widget.onPaintLiveImageFunc != null) {
            _controller?.startImageStream((cameraImage) {
              widget.onPaintLiveImageFunc!(
                  cameraImage, camera.sensorOrientation);
            });
          }
          setState(() {});
        },
      );
    }
  }

  Future _stopLiveFeed() async {
    if (_controller != null) {
      try {
        await _controller?.stopImageStream();
      } catch (_) {}
      await _controller?.dispose();
      _controller = null;
    }
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % widget.cameras.length;
    await _stopLiveFeed();
    await _startLiveFeed(_cameraIndex);
    if (widget.switchLiveCameraFunc != null) {
      await widget.switchLiveCameraFunc!();
    }
    setState(() => _changingCameraLens = false);
  }

  Future<void> _cameraTakeImage() async {
    if (_controller != null && widget.takeImageFunc != null) {
      await _controller?.stopImageStream();
      final XFile? xfileImage = await _controller?.takePicture();
      widget.takeImageFunc!(xfileImage);
    }
  }
}
