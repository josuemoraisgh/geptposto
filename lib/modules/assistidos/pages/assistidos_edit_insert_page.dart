import 'package:flutter/material.dart';
import '../models/stream_assistido_model2.dart';
import '../modelsView/assistidos_insert_edit_view.dart';

class AssistidoEditInsertPage extends StatelessWidget {
  final StreamAssistido? assistido;
  const AssistidoEditInsertPage({super.key, this.assistido});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Insira/Edite o usuário!!")),
      body: AssistidosInsertEditView(assistido: assistido),
    );
  }
}
