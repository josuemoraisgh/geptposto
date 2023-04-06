import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'coordinates_translator.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(
      this.isPresented, this.faces, this.absoluteImageSize, this.rotation);
  final bool? isPresented;
  final List<Face> faces;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = isPresented != null
          ? isPresented!
              ? Colors.green
              : Colors.red
          : Colors.yellow; //Colors.red;

    for (final Face face in faces) {
      /*if ((face.contours[FaceContourType.face]?.points != null) &&
          (face.contours[FaceContourType.leftEyebrowTop]?.points != null) &&
          (face.contours[FaceContourType.leftEyebrowBottom]?.points != null) &&
          (face.contours[FaceContourType.rightEyebrowTop]?.points != null) &&
          (face.contours[FaceContourType.rightEyebrowBottom]?.points != null) &&
          (face.contours[FaceContourType.leftEye]?.points != null) &&
          (face.contours[FaceContourType.rightEye]?.points != null) &&
          (face.contours[FaceContourType.upperLipTop]?.points != null) &&
          (face.contours[FaceContourType.upperLipBottom]?.points != null) &&
          (face.contours[FaceContourType.lowerLipTop]?.points != null) &&
          (face.contours[FaceContourType.lowerLipBottom]?.points != null) &&
          (face.contours[FaceContourType.noseBridge]?.points != null) &&
          (face.contours[FaceContourType.noseBottom]?.points != null) &&
          (face.contours[FaceContourType.leftCheek]?.points != null) &&
          (face.contours[FaceContourType.rightCheek]?.points != null)) {
        paint.color = Colors.green;
      }*/
      canvas.drawRect(
        Rect.fromLTRB(
          translateX(face.boundingBox.left, rotation, size, absoluteImageSize),
          translateY(face.boundingBox.top, rotation, size, absoluteImageSize),
          translateX(face.boundingBox.right, rotation, size, absoluteImageSize),
          translateY(
              face.boundingBox.bottom, rotation, size, absoluteImageSize),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.faces != faces;
  }
}
