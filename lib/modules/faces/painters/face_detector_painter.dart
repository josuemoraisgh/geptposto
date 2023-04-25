import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'coordinates_translator.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(
      this.descName, this.faces, this.absoluteImageSize, this.rotation);
  final String? descName;
  final List<Face> faces;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = descName != null
          ? descName!.isNotEmpty
              ? Colors.green
              : Colors.red
          : Colors.yellow; //Colors.red;

    for (final Face face in faces) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: descName,
          style: TextStyle(
            color: descName != null
                ? descName!.isNotEmpty
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
