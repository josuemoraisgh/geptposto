import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:ml_linalg/vector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../faces/image_converter.dart';
import '../models/stream_assistido_model.dart';

class AssistidoMLService extends Disposable {
  late Interpreter interpreter;
  late FaceDetector faceDetector;
  static const double threshold = 30;

  Future<void> init() async {
    await initializeInterpreter();
    interpreter.allocateTensors();
    faceDetector = FaceDetector(
      options: FaceDetectorOptions(enableContours: true),
    );
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

      interpreter = await Interpreter.fromAsset('mobilefacenet3.tflite',
          options: interpreterOptions);
    } catch (e) {
      debugPrint('Failed to load model.');
      debugPrint(e.toString());
    }
  }

  Future<int?> predict1(CameraImage cameraImage, int sensorOrientation,
      List<StreamAssistido> assistidos) async {
    double minDist = 999;
    double currDist = 999;
    int i = 0;
    int? index;
    var uint8ListImage = cameraImage.planes.first.bytes;
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/aux.jpg')
      ..writeAsBytesSync(List<int>.from(uint8ListImage),
          mode: FileMode.writeOnly, flush: true);
    //Processando a imagem para o reconhecimento futuro
    imglib.Image? image = imglib.decodeJpg(uint8ListImage);
    if (image != null) {
      final inputImage = InputImage.fromFile(file);
      final faceDetected = await faceDetector.processImage(inputImage);
      if (faceDetected.isNotEmpty) {
        image = cropFace(image, faceDetected[0], step: 80) ?? image;
        var classificatorArray = (await classificatorImage(image));
        for (i = 0; i < assistidos.length; i++) {
          if (assistidos[i].fotoPoints.isNotEmpty) {
            currDist =
                euclideanDistance(classificatorArray, assistidos[i].fotoPoints);
            if (classificatorArray.length != assistidos[i].fotoPoints.length) {
              debugPrint(assistidos[i].nomeM1);
            }
            debugPrint(currDist.toString());
            if (currDist <= threshold && currDist < minDist) {
              minDist = currDist;
              index = assistidos[i].ident;
            }
          }
        }
        return index;
      }
    }
    return null;
  }

  Future<int?> predict(CameraImage cameraImage, int sensorOrientation,
      List<StreamAssistido> assistidos) async {
    double minDist = 999;
    double currDist = 999;
    int i = 0;
    int? index;
    imglib.Image? image = cameraImageToImage(cameraImage);
    InputImage? inputImage =
        convertCameraImageToInputImage(cameraImage, sensorOrientation);
    if (inputImage != null && image != null) {
      final classificatorArray = await classificatorImage(image);
      for (i = 0; i < assistidos.length; i++) {
        if (assistidos[i].fotoPoints.isNotEmpty) {
          currDist =
              euclideanDistance(classificatorArray, assistidos[i].fotoPoints);
          if (classificatorArray.length != assistidos[i].fotoPoints.length) {
            debugPrint(assistidos[i].nomeM1);
          }
          debugPrint(currDist.toString());
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

  double norma2(List? e1) {
    if (e1 == null) throw Exception("Null argument in norma2");
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i]), 2);
    }
    return sqrt(sum);
  }

  double euclideanDistance(List? e1, List? e2) {
    if (e1 == null || e2 == null) {
      throw Exception("Null argument in euclidean Distance");
    }
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }

  Future<List<dynamic>> classificatorImage(imglib.Image image) async {
    List output = List.generate(1, (index) => List.filled(512, 0));
    List input = _preProcessImage(image);
    interpreter.run(input, output);
    output = List.from(output.reshape([512]));
    final n2 = norma2(output);
    final resp = output.map((e) => e / n2).toList();
    return resp;
  }

  Float32List preProcessImage1(imglib.Image image, Face faceDetected) {
    imglib.Image? croppedImage = cropFace(image, faceDetected);
    if (croppedImage != null) {
      imglib.copyResize(image, width: 120);
      imglib.Image imageResized = imglib.copyResizeCropSquare(croppedImage,
          size: 112, interpolation: imglib.Interpolation.linear);
      //final uint8List = Uint8List.fromList(imglib.encodeJpg(imageResized));
      //final img2 = imglib.decodeJpg(uint8List);
      //if (img2 != null) {
      Float32List imageAsList = imageByteToFloat32Normal(imageResized);
      return imageAsList;
      //}
    }
    return [] as Float32List;
  }

  List _preProcessImage(imglib.Image img,
      {int newWidth = 112, int newHeight = 112}) {
    Vector a, b, c, d;
    int yi, xi, x1, x2, y1, y2;
    double x,
        y,
        dx,
        dy,
        xOrigCenter,
        yOrigCenter,
        xScaledCenter,
        yScaledCenter,
        scaleX,
        scaleY;

    List newImage = List.generate(
        newHeight, (index) => List.filled(newWidth, [0.0, 0.0, 0.0]));

    final int origHeight = img.height, origWidth = img.width;

    List originalImg =
        img.data?.getBytes().toList().reshape([origHeight, origWidth, 3]) ?? [];
    if (originalImg.isNotEmpty) {
      // Compute center column and center row
      xOrigCenter = (origWidth - 1) / 2;
      yOrigCenter = (origHeight - 1) / 2;

      // Compute center of resized image
      xScaledCenter = (newWidth - 1) / 2;
      yScaledCenter = (newHeight - 1) / 2;

      // Compute the scale in both axes
      scaleX = origWidth / newWidth;
      scaleY = origHeight / newHeight;

      for (yi = 0; yi < newHeight; yi++) {
        for (xi = 0; xi < newWidth; xi++) {
          x = (xi - xScaledCenter) * scaleX + xOrigCenter;
          y = (yi - yScaledCenter) * scaleY + yOrigCenter;

          x1 = max<int>(min<int>(x.floor(), origWidth - 1), 0);
          y1 = max<int>(min<int>(y.floor(), origHeight - 1), 0);
          x2 = max<int>(min<int>(x.ceil(), origWidth - 1), 0);
          y2 = max<int>(min<int>(y.ceil(), origHeight - 1), 0);

          a = Vector.fromList(originalImg[y1][x1].cast<int>());
          b = Vector.fromList(originalImg[y2][x1].cast<int>());
          c = Vector.fromList(originalImg[y1][x2].cast<int>());
          d = Vector.fromList(originalImg[y2][x2].cast<int>());

          dx = x - x1;
          dy = y - y1;

          newImage[yi][xi] = ((a * (1 - dx) * (1 - dy) +
                      b * dy * (1 - dx) +
                      c * dx * (1 - dy) +
                      d * dx * dy) /
                  255)
              .toList();
        }
      }
    }
    return [newImage];
  }

  @override
  void dispose() {
    interpreter.close();
    faceDetector.close();
  }
}
