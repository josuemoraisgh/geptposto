import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../assistidos_controller.dart';
import '../../Styles/styles.dart';
import '../models/stream_assistido_model.dart';
import 'assistido_face_detector_view.dart';

class AssistidoListViewSilver extends StatelessWidget {
  final List<StreamAssistido> list;
  final AssistidosController controller;
  final AssistidoFaceDetectorView? faceDetectorView;
  const AssistidoListViewSilver({
    super.key,
    required this.controller,
    required this.list,
    this.faceDetectorView,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: controller.assistidosProviderStore.configStore
          .getConfig("dateSelected"),
      builder: (BuildContext context, AsyncSnapshot<List<String>?> value) =>
          value.hasData
              ? StreamBuilder<BoxEvent>(
                  initialData: BoxEvent("", value.data, false),
                  stream: controller.assistidosProviderStore.configStore
                      .watch("dateSelected")
                      .asBroadcastStream() as Stream<BoxEvent>,
                  builder: (BuildContext context,
                      AsyncSnapshot<BoxEvent> dateSelected) {
                    final data = dateSelected.data?.value[0];
                    if (data != null && data != "") {
                      int count = 0;
                      for (var element in list) {
                        if (element.chamada.toLowerCase().contains(data)) {
                          count++;
                        }
                      }
                      StreamAssistido.countPresente = count;
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
                                                    padding: EdgeInsets.only(
                                                        bottom: 50))
                                                : Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      left: 100,
                                                      right: 16,
                                                    ),
                                                    child: Container(
                                                      height: 1,
                                                      color: Styles
                                                          .linhaProdutoDivisor,
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
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
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
          FutureBuilder(
            future: pessoa.photoUint8List,
            builder: (BuildContext context, AsyncSnapshot photoUint8List) =>
                ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: photoUint8List.hasData
                  ? (photoUint8List.data as Uint8List).isEmpty
                      ? Image.asset(
                          "assets/images/semFoto.png",
                          fit: BoxFit.cover,
                          width: 76,
                          height: 76,
                        )
                      : Image.memory(
                          Uint8List.fromList(photoUint8List.data),
                          fit: BoxFit.cover,
                          width: 76,
                          height: 76,
                        )
                  : const Center(child: CircularProgressIndicator()),
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
                      onPressed: () =>
                          assistido.data!.chamadaToogleFunc(dateSelected),
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
            onPressed: () => Modular.to.pushNamed(
              "insert",
              arguments: {"assistido": pessoa},
            ),
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
