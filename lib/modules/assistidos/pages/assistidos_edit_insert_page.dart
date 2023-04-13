import 'package:flutter/material.dart';
import '../models/assistido_models.dart';
import '../modelsView/assistidos_insert_edit_view.dart';

class AssistidoEditInsertPage extends StatelessWidget {
  final Assistido? assistido;  
  const AssistidoEditInsertPage({Key? key, this.assistido})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Insira/Edite o usuário!!")),
      body: AssistidosInsertEditView(assistido: assistido),
    );
  }
}
