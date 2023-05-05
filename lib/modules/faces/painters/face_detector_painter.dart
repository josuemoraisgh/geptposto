import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'coordinates_translator.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(
      this.descNameList, this.faces, this.absoluteImageSize, this.rotation);
  final List<String?> descNameList;
  final List<Face> faces;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i=0;i<faces.length;i++) {
      var paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = descNameList[i] != null
            ? descNameList[i]!.isNotEmpty
                ? Colors.green
                : Colors.red
            : Colors.yellow; //Colors.red;
      final textPainter = TextPainter(
        text: TextSpan(
          text: descNameList[i],
          style: TextStyle(
            color: descNameList[i] != null
                ? descNameList[i]!.isNotEmpty
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
          translateX(faces[i].boundingBox.left, rotation, size, absoluteImageSize);
      final top =
          translateY(faces[i].boundingBox.top, rotation, size, absoluteImageSize);
      final right =
          translateX(faces[i].boundingBox.right, rotation, size, absoluteImageSize);
      final bottom = translateY(
          faces[i].boundingBox.bottom, rotation, size, absoluteImageSize);
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
