import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../faces/image_converter.dart';
import '../models/stream_assistido_model.dart';

class AssistidoMLService {
  late Interpreter interpreter;
  List? predictedArray;
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableLandmarks: true,
        enableTracking: true),
  );

  Future<StreamAssistido?> predict(CameraImage cameraImage,
      int sensorOrientation, List<StreamAssistido> assistidos) async {
    const int minDist = 999;
    const double threshold = 1.5;
    num? dist;

    imglib.Image? image = cameraImageToImage(cameraImage);
    InputImage? inputImage =
        convertCameraImageToInputImage(cameraImage, sensorOrientation);

    if (inputImage != null && image != null) {
      final predictedArray = await renderizarImage(inputImage, image);
      for (var assistido in assistidos) {
        final userArray = assistido.fotoPoints ?? [];
        dist = euclideanDistance(predictedArray, userArray);
        if (dist != null) {
          if (dist <= threshold && dist < minDist) {
            return assistido;
          }
        }
      }
    }
    return null;
  }

  Future<List<dynamic>> renderizarImage(
      InputImage inputImage, imglib.Image image) async {
    List output = List.generate(1, (index) => List.filled(192, 0));
    final List<Face> faces = await faceDetector.processImage(inputImage);
    if (faces.isNotEmpty) {
      List input = _preProcessImage(image, faces[0]);
      input = input.reshape([1, 112, 112, 3]);
      await initializeInterpreter();
      interpreter.run(input, output);
      output = output.reshape([192]);
    }
    return List.from(output);
  }

  euclideanDistance(List l1, List l2) {
    double sum = 0;
    for (int i = 0; i < l1.length; i++) {
      sum += pow((l1[i] - l2[i]), 2);
    }

    return pow(sum, 0.5);
  }

  initializeInterpreter() async {
    Delegate? delegate;
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
    } catch (e) {
      debugPrint('Failed to load model.');
      debugPrint(e.toString());
    }
  }

  List _preProcessImage(imglib.Image image, Face faceDetected) {
    imglib.Image? croppedImage = cropFace(image, faceDetected);
    if (croppedImage != null) {
      imglib.Image img = imglib.copyResizeCropSquare(croppedImage, size: 112);
      final uint8List = Uint8List.fromList(imglib.encodePng(img));
      final img2 = imglib.decodeImage(uint8List);
      if (img2 != null) {
        Float32List imageAsList = imageToByteListFloat32(img2);
        return imageAsList;
      }
    }
    return [];
  }
}
