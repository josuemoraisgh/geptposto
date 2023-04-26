import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../faces/image_converter.dart';
import '../models/stream_assistido_model.dart';

class AssistidoMLService extends Disposable {
  late Interpreter interpreter;
  late FaceDetector faceDetector;
  static const double threshold = 1.4;

  Future<void> init() async {
    await initializeInterpreter();
    faceDetector = FaceDetector(
      options: FaceDetectorOptions(
          enableContours: true,
          enableClassification: true,
          enableLandmarks: true,
          enableTracking: true),
    );
  }

  Future<int?> predict(CameraImage cameraImage,
      int sensorOrientation, List<StreamAssistido> assistidos) async {
    double minDist = 999;
    double currDist = 999;
    int i = 0;
    int? index;

    imglib.Image? image = cameraImageToImage(cameraImage);
    InputImage? inputImage =
        convertCameraImageToInputImage(cameraImage, sensorOrientation);
    if (inputImage != null && image != null) {
      final predictedArray = await renderizarImage(inputImage, image);
      for (i = 0; i < assistidos.length; i++) {
        if (assistidos[i].fotoPoints.isNotEmpty) {
          currDist = euclideanDistance(predictedArray, assistidos[i].fotoPoints);
          if (currDist <= threshold && currDist < minDist) {
              minDist = currDist;
              index = i;
          }
        }
      }
      return index;
    }
    return null;
  }

  double euclideanDistance(List? e1, List? e2) {
    if (e1 == null || e2 == null) throw Exception("Null argument");
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }

  Future<List<dynamic>> renderizarImage(
      InputImage inputImage, imglib.Image image) async {
    List output = List.generate(1, (index) => List.filled(192, 0));
    final List<Face> faces = await faceDetector.processImage(inputImage);
    if (faces.isNotEmpty) {
      List input = _preProcessImage(image, faces[0]);
      input = input.reshape([1, 112, 112, 3]);
      interpreter.run(input, output);
      output = output.reshape([192]);
    }
    return List.from(output);
  }

  Future initializeInterpreter() async {
    late Delegate? delegate;
    try {
      if (Platform.isAndroid) {
        delegate = GpuDelegateV2(
            options: GpuDelegateOptionsV2(
          isPrecisionLossAllowed: false,
          inferencePreference: TfLiteGpuInferenceUsage.fastSingleAnswer,
          inferencePriority1: TfLiteGpuInferencePriority.minLatency,
          inferencePriority2: TfLiteGpuInferencePriority.auto,
          inferencePriority3: TfLiteGpuInferencePriority.auto,
        ));
      } else if (Platform.isIOS) {
        delegate = GpuDelegate(
          options: GpuDelegateOptions(
              allowPrecisionLoss: true,
              waitType: TFLGpuDelegateWaitType.active),
        );
      }
      var interpreterOptions = InterpreterOptions()..addDelegate(delegate!);

      interpreter = await Interpreter.fromAsset('mobilefacenet.tflite',
          options: interpreterOptions);
      //interpreter = await Interpreter.fromAsset('mobile_face_net.tflite',
      //    options: interpreterOptions);
    } catch (e) {
      debugPrint('Failed to load model.');
      debugPrint(e.toString());
    }
  }

  List _preProcessImage(imglib.Image image, Face faceDetected) {
    imglib.Image? croppedImage = cropFace(image, faceDetected);
    if (croppedImage != null) {
      imglib.Image img = imglib.copyResizeCropSquare(croppedImage, size: 112);
      final uint8List = Uint8List.fromList(imglib.encodeJpg(img));
      final img2 = imglib.decodeJpg(uint8List);
      if (img2 != null) {
        Float32List imageAsList = imageToByteListFloat32(img2);
        return imageAsList;
      }
    }
    return [];
  }

  @override
  void dispose() {
    interpreter.close();
    faceDetector.close();
  }
}
