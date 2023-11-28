import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../assistidos_controller.dart';
import '../../Styles/styles.dart';
import '../models/stream_assistido_model.dart';
import 'assistido_face_detector_view.dart';

class AssistidoListViewSilver extends StatelessWidget {
  final List<StreamAssistido> list;
  final AssistidosController controller;
  final AssistidoFaceDetectorView? faceDetectorView;
  final void Function({StreamAssistido? assistido}) functionEdit;
  final void Function(StreamAssistido pessoa) functionChamada;
  const AssistidoListViewSilver({
    super.key,
    required this.controller,
    required this.list,
    required this.functionEdit,
    required this.functionChamada,
    this.faceDetectorView,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BoxEvent>(
      stream: controller.assistidosStoreSync.dateSelectedController,
      builder: (BuildContext context, AsyncSnapshot<BoxEvent> dateSelected) {
        final data = dateSelected.data?.value[0];
        if (data != null && data != "") {
          int count = 0;
          for (var element in list) {
            if (element.chamada.toLowerCase().contains(data)) count++;
          }
          controller.countPresente = count;
        }
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            if (faceDetectorView != null)
              SizedBox(
                  height: 300,
                  width: MediaQuery.of(context).size.width,
                  child: faceDetectorView!),
            Expanded(
              child: CustomScrollView(
                semanticChildCount: list.length,
                slivers: <Widget>[
                  SliverSafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(top: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < list.length) {
                            return Column(
                              children: <Widget>[
                                row(list[index], data),
                                index == list.length - 1
                                    ? const Padding(
                                        padding: EdgeInsets.only(bottom: 50))
                                    : Padding(
                                        padding: const EdgeInsets.only(
                                          left: 100,
                                          right: 16,
                                        ),
                                        child: Container(
                                          height: 1,
                                          color: Styles.linhaProdutoDivisor,
                                        ),
                                      ),
                              ],
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget row(StreamAssistido pessoa, String? dateSelected) {
    return SafeArea(
      top: false,
      bottom: false,
      minimum: const EdgeInsets.only(
        left: 16,
        top: 8,
        bottom: 8,
        right: 8,
      ),
      child: Row(
        children: <Widget>[
          StreamBuilder<Uint8List>(
            initialData: pessoa.photoUint8List,
            stream: pessoa.photoStream,
            builder: (BuildContext context,
                    AsyncSnapshot<Uint8List> photoUint8List) =>
                ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: pessoa.photoUint8List.isEmpty
                  ? Image.asset(
                      "assets/images/semFoto.png",
                      fit: BoxFit.cover,
                      width: 76,
                      height: 76,
                    )
                  : Image.memory(
                      Uint8List.fromList(pessoa.photoUint8List),
                      fit: BoxFit.cover,
                      width: 76,
                      height: 76,
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pessoa.nomeM1,
                    style: Styles.linhaProdutoNomeDoItem,
                  ),
                  const Padding(padding: EdgeInsets.only(top: 8)),
                  Text(
                    pessoa.fone,
                    style: Styles.linhaProdutoPrecoDoItem,
                  )
                ],
              ),
            ),
          ),
          dateSelected == null || dateSelected == ""
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {},
                  child: const Icon(
                    CupertinoIcons.hand_thumbsdown,
                    color: Colors.grey,
                    semanticLabel: 'Ausente',
                  ))
              : StreamBuilder(
                  initialData: pessoa,
                  stream: pessoa.chamadaStream,
                  builder: (BuildContext context,
                      AsyncSnapshot<StreamAssistido> assistido) {
                    return CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => functionChamada(assistido.data!),
                      child: assistido.data!.chamada
                              .toLowerCase()
                              .contains(dateSelected)
                          ? const Icon(
                              CupertinoIcons.hand_thumbsup,
                              color: Colors.green,
                              size: 30.0,
                              semanticLabel: 'Presente',
                            )
                          : const Icon(
                              CupertinoIcons.hand_thumbsdown,
                              color: Colors.red,
                              semanticLabel: 'Ausente',
                            ),
                    );
                  },
                ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => functionEdit(assistido: pessoa),
            child: const Icon(
              Icons.edit,
              size: 30.0,
              color: Colors.blue,
              semanticLabel: 'Edit',
            ),
          ),
        ],
      ),
    );
  }
}
