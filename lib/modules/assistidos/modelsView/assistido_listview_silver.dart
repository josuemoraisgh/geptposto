import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rx_notifier/rx_notifier.dart';
import '../assistidos_controller.dart';
import '../../Styles/styles.dart';
import '../models/stream_assistido_model.dart';

class AssistidoListViewSilver extends StatelessWidget {
  final List<StreamAssistido> list;
  final AssistidosController controller;
  final void Function({StreamAssistido? assistido}) functionEdit;
  final void Function(StreamAssistido pessoa) functionChamada;
  const AssistidoListViewSilver({
    Key? key,
    required this.controller,
    required this.list,
    required this.functionEdit,
    required this.functionChamada,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RxBuilder(builder: (BuildContext context) {
      final data = controller.dateSelectedController.value;
      int count = 0;
      for (int i = 0; i < list.length; i++) {
        if (list[i].assistido.chamada.toLowerCase().contains(data)) {
          count++;
        }
      }
      controller.countPresente = count;
      return CustomScrollView(
        semanticChildCount: list.length,
        slivers: <Widget>[
          SliverSafeArea(
            top: false,
            minimum: const EdgeInsets.only(top: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < list.length) {
                    return index == list.length - 1
                        ? row(list[index])
                        : Column(
                            children: <Widget>[
                              row(list[index]),
                              Padding(
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
      );
    });
  }

  Widget row(StreamAssistido pessoa) {
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
          StreamBuilder(
            initialData: pessoa.ident,
            stream: pessoa.photoStream,
            builder: (BuildContext context, AsyncSnapshot<int> ident) {
              if (pessoa.photoName.isNotEmpty &&
                  pessoa.photoUint8List.isEmpty) {
                controller.store.addJustLocal(pessoa);
              }
              return ClipRRect(
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
              );
            },
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
          RxBuilder(
            builder: (BuildContext context) =>
                controller.dateSelectedController.value == ""
                    ? CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                        child: const Icon(
                          CupertinoIcons.hand_thumbsdown,
                          color: Colors.grey,
                          semanticLabel: 'Ausente',
                        ))
                    : StreamBuilder(
                        initialData: pessoa.ident,
                        stream: pessoa.chamadaStream,
                        builder: (BuildContext context,
                            AsyncSnapshot<int> chamada) {
                          return CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => functionChamada(pessoa),
                            child: pessoa.chamada
                                    .toLowerCase()
                                    .contains(controller.dateSelected)
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
