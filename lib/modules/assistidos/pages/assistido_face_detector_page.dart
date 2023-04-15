import 'package:flutter/material.dart';
import 'package:rx_notifier/rx_notifier.dart';
import '../models/assistido_models.dart';
import '../modelsView/assistido_face_detector_view.dart';

class AssistidoFaceDetectorPage extends StatelessWidget {
  final String title;
  final Assistido? assistido;
  final List<Assistido>? assistidos;
  final Function(Assistido pessoa)? chamadaFunc;
  final RxNotifier<bool>? isPhotoChanged;
  const AssistidoFaceDetectorPage({
    super.key,
    required this.title,
    this.assistido,
    this.assistidos,
    this.chamadaFunc,
    this.isPhotoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AssistidoFaceDetectorView(
          assistido: assistido,
          assistidos: assistidos,
          chamadaFunc: chamadaFunc,
          isPhotoChanged: isPhotoChanged,
          stackFit: StackFit.expand,
        ));
  }
}
