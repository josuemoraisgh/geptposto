import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:ml_linalg/distance.dart';
import 'package:ml_linalg/vector.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;
import '../../faces/image_converter.dart';
import '../models/stream_assistido_model.dart';

class AssistidoMLService extends Disposable {
  late Interpreter interpreter;
  late IsolateInterpreter isolateInterpreter;
  late FaceDetector faceDetector;
  //late SensorOrientationDetector orientation;
  static const double threshold = 1.0;

  Future<void> init() async {
    await initializeInterpreter();
    //interpreter.allocateTensors();
    faceDetector = FaceDetector(
      options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate, enableContours: true),
    );
    //orientation = SensorOrientationDetector();
    //await orientation.init();
  }

  Future initializeInterpreter() async {
    interpreter = await Interpreter.fromAsset('mobilefacenet3.tflite');
    isolateInterpreter =
        await IsolateInterpreter.create(address: interpreter.address);
  }

  Future<List<int?>> predict(CameraImage cameraImage, int rotation,
      List<StreamAssistido> assistidos) async {
    List<int?> assistidosIdentList = [];
    List<List> inputs = [];
    Map<int, List<List<double>>> outputs = {};
    List<double> minDist = [];
    List<double> currDist = [];
    int i = 0, j = 0, k = 0;
    imglib.Image image =
        convertCameraImageToImageWithRotate(cameraImage, rotation);
    InputImage? inputImage =
        await convertCameraImageToInputImageWithRotate(cameraImage, rotation);
    if (inputImage != null) {
      final List<Face> facesDetected =
          await faceDetector.processImage(inputImage);
      if (facesDetected.isNotEmpty) {
        k = 0;
        for (var faceDetected in facesDetected) {
          assistidosIdentList.add(0);
          minDist.add(999);
          currDist.add(999);
          outputs.addAll({
            k++: [List.filled(512, 0)]
          });
          var imageAux = cropFace(image, faceDetected, step: 80) ?? image;
          inputs.add([_preProcessImage(imageAux)]);
        }
        isolateInterpreter.runForMultipleInputs(inputs, outputs);
        for (i = 0; i < assistidos.length; i++) {
          for (j = 0; j < minDist.length; j++) {
            if (assistidos[i].fotoPoints.isNotEmpty) {
              var vector1 = Vector.fromList(assistidos[i].fotoPoints);
              final vectorOut = Vector.fromList(outputs[0]![j]);
              final n2 = vectorOut.norm();
              final aux = vector1.distanceTo(vectorOut / n2,
                  distance: Distance.euclidean);
              //debugPrint(aux.toString());
              currDist[j] = aux;
              if (currDist[j] <= threshold && currDist[j] < minDist[j]) {
                minDist[j] = currDist[j];
                assistidosIdentList[j] = assistidos[i].ident;
              }
            }
          }
        }
      }
    }
    return assistidosIdentList;
  }

  Future<List<double>> classificatorImage(imglib.Image image) async {
    List<List<double>> output =
        List.generate(1, (index) => List.filled(512, 0));
    List input = [_preProcessImage(image)];
    isolateInterpreter.run(input, output);
    final n2 = Vector.fromList(output[0]).norm();
    final resp = output[0].map((e) => e / n2).toList();
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
    return newImage;
  }

  @override
  void dispose() {
    interpreter.close();
    faceDetector.close();
  }
}
