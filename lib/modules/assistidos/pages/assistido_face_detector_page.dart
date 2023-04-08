import 'package:flutter/material.dart';
import '../models/assistido_models.dart';
import '../modelsView/assistido_face_detector_view.dart';

class AssistidoFaceDetectorPage extends StatefulWidget {
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
  State<AssistidoFaceDetectorPage> createState() =>
      _AssistidoFaceDetectorPageState();
}

class _AssistidoFaceDetectorPageState extends State<AssistidoFaceDetectorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: AssistidoFaceDetectorView(
          assistidos: widget.assistidos,
          chamadaFunc: widget.chamadaFunc,
          stackFit: StackFit.expand,
        ));
  }
}
