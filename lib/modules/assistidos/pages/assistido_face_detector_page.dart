import 'package:flutter/material.dart';
import '../models/assistido_models.dart';
import '../modelsView/assistido_face_detector_view.dart';


class AssistidoFaceDetectorPage extends StatelessWidget {
  final String title;
  final List<Assistido>? assistidos;
  final Function(Assistido pessoa) chamadaFunc;
  const AssistidoFaceDetectorPage({
    super.key,
    required this.title,
    this.assistidos,
    required this.chamadaFunc,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AssistidoFaceDetectorView(
          assistidos: assistidos,
          chamadaFunc: chamadaFunc,
          stackFit: StackFit.expand,
        ));
  }
}
