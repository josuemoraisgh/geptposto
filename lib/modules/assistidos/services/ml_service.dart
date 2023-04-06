import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/assistido_models.dart';
import 'face_detector_service.dart';

class MLService {
  final _faceDetector = FaceDetectorService();

  Future<Assistido?> predict(
      InputImage cameraImage, List<Assistido> assistidos) async {
    const int minDist = 999;
    const double threshold = 1.5;
    num? dist;
    final predictedArray = await _faceDetector.processImage(cameraImage);
    for (var assistido in assistidos) {
      final userArray = assistido.fotoPoints ?? [];
      dist = euclideanDistance(predictedArray, userArray);
      if (dist != null) {
        if (dist <= threshold && dist < minDist) {
          return assistido;
        }
      }
    }
    return null;
  }

  num? euclideanDistance(List<num> l1, List<num> l2) {
    if (l1.length == l2.length) {
      double sum = 0;
      for (int i = 0; i < l1.length; i++) {
        sum += pow((l1[i] - l2[i]), 2);
      }
      return pow(sum, 0.5);
    }
    return null;
  }
}
