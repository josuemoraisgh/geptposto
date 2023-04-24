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

  Future<StreamAssistido?> predict(CameraImage cameraImage,
      int sensorOrientation, List<StreamAssistido> assistidos) async {
    num distAux = 0, dist = 999;
    int i = 0, index = 0;

    imglib.Image? image = cameraImageToImage(cameraImage);
    InputImage? inputImage =
        convertCameraImageToInputImage(cameraImage, sensorOrientation);
    if (inputImage != null && image != null) {
      final predictedArray = await renderizarImage(inputImage, image);
      for (i = 0; i < assistidos.length; i++) {
        debugPrint(assistidos[i].nomeM1);
        if (assistidos[i].fotoPoints.isNotEmpty) {
          distAux = euclideanDistance(predictedArray, assistidos[i].fotoPoints);
          if (distAux < dist) {
            dist = distAux;
            index = i;
          }
        }
      }
      if (index != 0 && dist < 999) {
        debugPrint(assistidos[index].nomeM1);
        return assistidos[index];
      }
    }
    return null;
  }

  num euclideanDistance(List l1, List l2) {
    try {
      double sum = 0;
      for (int i = 0; i < l1.length; i++) {
        sum += pow((l1[i] - l2[i]), 2);
      }
      debugPrint(sum.toString());
      return pow(sum, 0.5);
    } catch (e) {
      return 999;
    }
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

      //interpreter = await Interpreter.fromAsset('mobilefacenet.tflite',
      //    options: interpreterOptions);
      interpreter = await Interpreter.fromAsset('mobile_face_net.tflite',
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
