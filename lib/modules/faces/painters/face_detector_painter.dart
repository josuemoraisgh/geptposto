import 'dart:ui';

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

      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Josué Silva de Morais',
          style: TextStyle(
            color: isPresented != null
                ? isPresented!
                    ? Colors.green
                    : Colors.red
                : Colors.yellow,
            fontSize: 20,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(
          minWidth: 0,
          maxWidth: size.width,
        );
      final left =
          translateX(face.boundingBox.left, rotation, size, absoluteImageSize);
      final top =
          translateY(face.boundingBox.top, rotation, size, absoluteImageSize);
      final right =
          translateX(face.boundingBox.right, rotation, size, absoluteImageSize);
      final bottom = translateY(
          face.boundingBox.bottom, rotation, size, absoluteImageSize);
      final xCenter = (left + right - textPainter.width) / 2;
      final offset = Offset(xCenter, bottom);
      textPainter.paint(canvas, offset);
      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.faces != faces;
  }
}
