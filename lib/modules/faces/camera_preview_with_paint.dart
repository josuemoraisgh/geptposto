import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:rx_notifier/rx_notifier.dart';
import 'camera_controle_service.dart';

class CameraPreviewWithPaint extends StatefulWidget {
  final CameraService? cameraService;
  final Future<void> Function(CameraImage cameraImage)? onPaintLiveImageFunc;
  final Future<void> Function(Uint8List? uint8ListImage)? takeImageFunc;
  final dynamic Function()? switchLiveCameraFunc;
  final bool isRealTime;
  final StackFit? stackFit;
  final CustomPaint? customPaint;
  final RxNotifier<double>? threshold;
  const CameraPreviewWithPaint({
    super.key,
    required this.cameraService,
    this.customPaint,
    this.onPaintLiveImageFunc,
    this.takeImageFunc,
    this.switchLiveCameraFunc,
    this.stackFit,
    this.isRealTime = false,
    this.threshold,
  });
  @override
  State<CameraPreviewWithPaint> createState() => _CameraPreviewWithPaintState();
}

class _CameraPreviewWithPaintState extends State<CameraPreviewWithPaint> {
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;
  bool _changingCameraLens = false;
  //Orientation _orientation = Orientation.portrait;
  late CameraService _cameraService;
  late Future<bool> isStarted; //Não retirar muito importante

  Future<bool> init() async {
    _cameraService = widget.cameraService ?? CameraService();
    CameraLensDirection.back;
    await _startLiveFeed(_cameraService.camera!.lensDirection);
    return true;
  }

  @override
  void initState() {
    super.initState();
    isStarted = init();
  }

  @override
  void dispose() {
    _cameraService.stopCameraController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isStarted,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if ((snapshot.data != null) &&
            (_cameraService.cameraController != null)) {
          if ((_cameraService.camera != null) &&
              (snapshot.hasData) &&
              (_cameraService.cameraController!.value.isInitialized)) {
            //_orientation = MediaQuery.of(context).orientation;
            return Stack(
              fit: widget.stackFit ?? StackFit.passthrough,
              children: <Widget>[
                _changingCameraLens
                    ? const Center(
                        child: Text('Changing camera lens'),
                      )
                    : CameraPreview(_cameraService.cameraController!),
                if (widget.customPaint != null) widget.customPaint!,
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _floatingActionButton(),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Slider(
                      value: zoomLevel,
                      min: minZoomLevel,
                      max: maxZoomLevel,
                      onChanged: (newSliderValue) {
                        setState(() {
                          zoomLevel = newSliderValue;
                          _cameraService.cameraController!
                              .setZoomLevel(zoomLevel);
                        });
                      },
                      divisions: (maxZoomLevel - 1).toInt() < 1
                          ? null
                          : (maxZoomLevel - 1).toInt(),
                    ),
                  ),
                ),
                if (widget.threshold != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Slider(
                        value: widget.threshold!.value,
                        min: 0.1,
                        max: 2.0,
                        onChanged: (newSliderValue) {
                          setState(() {
                            widget.threshold!.value = newSliderValue;
                            _cameraTakeImage();
                          });
                        },
                        divisions: (maxZoomLevel - 1).toInt() < 1
                            ? null
                            : (maxZoomLevel - 1).toInt(),
                      ),
                    ),
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
            Align(
              alignment: Alignment.topCenter,
              child: ElevatedButton(
                onPressed: () {
                  _cameraTakeImage();
                },
                child: Icon(
                  (_cameraService.camera!.lensDirection ==
                          CameraLensDirection.back)
                      ? Icons.photo_camera_back
                      : Icons.photo_camera_front,
                  size: 40,
                ),
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
      ],
    );
  }

  Future<void> _startLiveFeed(CameraLensDirection cameraDirection) async {
    if (_cameraService.cameraController == null) {
      _cameraService.setupCameraController(
        cameraDirection: cameraDirection,
        initFunc: (_) async {
          if (!mounted) {
            return;
          }
          _cameraService.cameraController?.unlockCaptureOrientation();
          _cameraService.cameraController?.getMinZoomLevel().then((value) {
            zoomLevel = value;
            minZoomLevel = value;
          });
          _cameraService.cameraController?.getMaxZoomLevel().then((value) {
            maxZoomLevel = value;
          });
          if (widget.onPaintLiveImageFunc != null) {
            _cameraService.cameraController?.startImageStream((cameraImage) {
              widget.onPaintLiveImageFunc!(cameraImage);
            });
          }
          setState(() {});
        },
      );
    }
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    await _cameraService.stopCameraController();
    await _startLiveFeed(
        _cameraService.cameraDirection == CameraLensDirection.front
            ? CameraLensDirection.back
            : CameraLensDirection.front);
    if (widget.switchLiveCameraFunc != null) {
      await widget.switchLiveCameraFunc!();
    }
    setState(() => _changingCameraLens = false);
  }

  Future<void> _cameraTakeImage() async {
    if (_cameraService.isBusyCamera != true &&
        _cameraService.cameraController != null &&
        widget.takeImageFunc != null) {
      if (widget.isRealTime) {
        widget.takeImageFunc!(null);
      } else {
        final xfileImage = await _cameraService.takePicture();
        final uint8List = await xfileImage?.readAsBytes();
        if (uint8List != null) {
          await _startLiveFeed(_cameraService.cameraDirection!);
          widget.takeImageFunc!(uint8List);
        } else {
          await _startLiveFeed(_cameraService.cameraDirection!);
        }
      }
    }
  }
}
