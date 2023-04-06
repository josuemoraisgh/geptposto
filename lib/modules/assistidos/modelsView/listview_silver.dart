import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rx_notifier/rx_notifier.dart';
import '../assistidos_controller.dart';
import '../models/assistido_models.dart';
import '../../Styles/styles.dart';

class ListViewSilver extends StatelessWidget {
  final List<Assistido> list;
  final AssistidosController controller;
  final Future<File?> Function(Assistido pessoa) functionGetImg;
  final void Function(Assistido pessoa) functionEdit;
  final void Function(Assistido pessoa) functionChamada;
  const ListViewSilver({
    Key? key,
    required this.controller,
    required this.list,
    required this.functionGetImg,
    required this.functionEdit,
    required this.functionChamada,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RxBuilder(builder: (BuildContext context) {
      var data = controller.dateSelectedController.value;
      var count = 0;
      for (int i = 0; i < list.length; i++) {
        if (list[i].chamada.toLowerCase().contains(data)) {
          count++;
        }
        controller.countPresente = count;
      }
      return CustomScrollView(
        semanticChildCount: list.length,
        slivers: <Widget>[
          SliverSafeArea(
            top: false,
            minimum: const EdgeInsets.only(top: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index < list.length) {
                  return FutureBuilder(
                      initialData: null,
                      future: functionGetImg(list[index]),
                      builder: (context, AsyncSnapshot<File?> foto) {
                        return index == list.length - 1
                            ? row(foto.data, list[index])
                            : Column(
                                children: <Widget>[
                                  row(foto.data, list[index]),
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
                      });
                }
                return null;
              }),
            ),
          ),
        ],
      );
    });
  }

  Widget row(File? foto, Assistido pessoa) {
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
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: foto == null
                ? Image.asset(
                    "assets/images/semFoto.png",
                    fit: BoxFit.cover,
                    width: 76,
                    height: 76,
                  )
                : FutureBuilder<bool>(
                    future: foto.exists(),
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> isExists) {
                      if (isExists.hasData) {
                        return isExists.data != true
                            ? Image.asset(
                                "assets/images/semFoto.png",
                                fit: BoxFit.cover,
                                width: 76,
                                height: 76,
                              )
                            : Image.file(
                                foto,
                                fit: BoxFit.cover,
                                width: 76,
                                height: 76,
                              );
                      }
                      return const Center(child: CircularProgressIndicator());
                    }),
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
                        stream: pessoa.chamadaStream,
                        initialData: pessoa.chamada,
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          return CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              functionChamada(pessoa);
                            },
                            child: (pessoa.chamada
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
                                  )),
                          );
                        },
                      ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              functionEdit(pessoa);
            },
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
