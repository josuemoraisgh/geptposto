import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraService {
  bool? _isBusyCamera;
  bool? get isBusyCamera => _isBusyCamera;

  InputImageRotation? _cameraRotation;
  InputImageRotation? get cameraRotation => _cameraRotation;

  CameraDescription? _camera;
  CameraDescription? get camera => _camera;

  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;

  CameraLensDirection? _cameraDirection;
  CameraLensDirection? get cameraDirection => _cameraDirection;

  String? _imagePath;
  String? get imagePath => _imagePath;

  CameraService() {
    _isBusyCamera = false;
    _getCameraDescription();
  }

  Future _getCameraDescription({CameraLensDirection? cameraDirection}) async {
    List<CameraDescription> cameras = await availableCameras();
    _cameraDirection = cameraDirection ?? CameraLensDirection.front;
    _camera = cameras.firstWhere(
        (CameraDescription camera) => camera.lensDirection == _cameraDirection);
    _cameraRotation = rotationIntToImageRotation(_camera!.sensorOrientation);
  }

  Future stopCameraController() async {
    if (_cameraController != null) {
      if (_isBusyCamera != true) {
        await _cameraController?.stopImageStream();
        _isBusyCamera = false;
      }
      await _cameraController?.dispose();
      _cameraController = null;
    }
  }

  Future setupCameraController(
      {CameraLensDirection? cameraDirection,
      final Future<void> Function(void)? initFunc}) async {
    _isBusyCamera = false;
    await _getCameraDescription(cameraDirection: cameraDirection);
    _cameraController = CameraController(
      _camera!,
      ResolutionPreset.high,
      enableAudio: false,
    );
    if (initFunc != null) {
      await _cameraController?.initialize().then(initFunc);
    } else {
      await _cameraController?.initialize();
    }
  }

  InputImageRotation rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<XFile?> takePicture() async {
    assert(_cameraController != null, 'Camera controller not initialized');
    _isBusyCamera = true;
    await _cameraController?.stopImageStream();
    XFile? file = await _cameraController?.takePicture();
    _imagePath = file?.path;
    return file;
  }

  Size getImageSize() {
    assert(_cameraController != null, 'Camera controller not initialized');
    assert(
        _cameraController!.value.previewSize != null, 'Preview size is null');
    return Size(
      _cameraController!.value.previewSize!.height,
      _cameraController!.value.previewSize!.width,
    );
  }

  dispose() async {
    stopCameraController();
  }
}
