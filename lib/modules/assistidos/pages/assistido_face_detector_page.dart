import 'package:flutter/material.dart';
import 'package:rx_notifier/rx_notifier.dart';
import '../modelsView/assistido_face_detector_view.dart';
import '../models/stream_assistido_model2.dart';

class AssistidoFaceDetectorPage extends StatelessWidget {
  final String title;
  final StreamAssistido? assistido;
  final List<StreamAssistido>? assistidos;
  final RxNotifier<List<StreamAssistido>>? assistidoProvavel;
  final RxNotifier<bool>? isPhotoChanged;
  const AssistidoFaceDetectorPage({
    super.key,
    required this.title,
    this.assistido,
    this.assistidos,
    this.assistidoProvavel,
    this.isPhotoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AssistidoFaceDetectorView(
          assistido: assistido,
          assistidoList: assistidos,
          assistidoProvavel: assistidoProvavel,
          stackFit: StackFit.expand,
          isPhotoChanged: isPhotoChanged,
        ));
  }
}
