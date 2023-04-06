import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableLandmarks: true,
        enableTracking: true),
  );

  Iterable<num> getPoints(Face face, FaceContourType type) {
    try {
      List<num> points = [];
      final faceContour = face.contours[type];
      if (faceContour?.points != null) {
        for (final Point point in faceContour!.points) {
          points.add(point.x);
          points.add(point.y);
        }
      }
      return points;
    } catch (e) {
      return [];
    }
  }

  Future<List<num>> getPointsFileImage(String fileName) async {
    final inputImage = InputImage.fromFilePath(fileName);
    return (getPointsImage(inputImage));
  }

  Future<List<num>> getPointsImage(InputImage inputImage) async {
    List<num> facePoint = [];
    final faces = await faceDetector.processImage(inputImage);
    for (final Face face in faces) {
      facePoint.addAll(getPoints(face, FaceContourType.leftEyebrowTop));
      facePoint.addAll(getPoints(face, FaceContourType.leftEyebrowBottom));
      facePoint.addAll(getPoints(face, FaceContourType.rightEyebrowTop));
      facePoint.addAll(getPoints(face, FaceContourType.rightEyebrowBottom));
      facePoint.addAll(getPoints(face, FaceContourType.leftEye));
      facePoint.addAll(getPoints(face, FaceContourType.rightEye));
      facePoint.addAll(getPoints(face, FaceContourType.upperLipTop));
      facePoint.addAll(getPoints(face, FaceContourType.upperLipBottom));
      facePoint.addAll(getPoints(face, FaceContourType.lowerLipTop));
      facePoint.addAll(getPoints(face, FaceContourType.lowerLipBottom));
      facePoint.addAll(getPoints(face, FaceContourType.noseBridge));
      facePoint.addAll(getPoints(face, FaceContourType.noseBottom));
      facePoint.addAll(getPoints(face, FaceContourType.leftCheek));
      facePoint.addAll(getPoints(face, FaceContourType.rightCheek));
    }
    return facePoint;
  }
}
