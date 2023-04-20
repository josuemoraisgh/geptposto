import 'package:badges/badges.dart' as bg;
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:icon_badge/icon_badge.dart';
import 'package:rx_notifier/rx_notifier.dart';
import 'assistidos_controller.dart';
import 'models/stream_assistido_model.dart';
import 'modelsView/dropdown_body.dart';
import 'modelsView/assistido_listview_silver.dart';
import 'modelsView/search_bar.dart';

class AssistidosPage extends StatefulWidget {
  final Map<String, dynamic> dadosTela;
  const AssistidosPage({Key? key, required this.dadosTela}) : super(key: key);

  @override
  State<AssistidosPage> createState() => _AssistidosPageState();
}

class _AssistidosPageState extends State<AssistidosPage> {
  List<StreamAssistido>? _list;
  final AssistidosController controller = Modular.get<AssistidosController>();
  final DropdownBody assistidosDropdownButton = DropdownBody(
    dateSelectedController:
        Modular.get<AssistidosController>().dateSelectedController,
    itensListController:
        Modular.get<AssistidosController>().itensListController,
  );

  @override
  void initState() {
    super.initState();
    controller.init();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
      valueListenable: controller.isInitedController,
      builder: (BuildContext context, dynamic isInited, _) => Scaffold(
          appBar: customAppBar(isInited),
          body: customBody(context, isInited),
          floatingActionButton: customFloatingActionButton(context)));

  AppBar customAppBar(bool isInited) => AppBar(
        title: bg.Badge(
          badgeStyle: const bg.BadgeStyle(
            badgeColor: Colors.green,
          ),
          position: bg.BadgePosition.topStart(top: 0),
          badgeContent: RxBuilder(
              builder: (BuildContext context) => Text(
                  '${controller.countPresente}',
                  style: const TextStyle(color: Colors.white, fontSize: 10.0))),
          child: RxBuilder(
            builder: (BuildContext context) => controller.whatWidget.value == 0
                ? Row(children: [
                    const Text("Chamada: "),
                    if (isInited) assistidosDropdownButton,
                  ])
                : SearchBar(
                    textController: controller.textEditing,
                    focusNode: controller.focusNode,
                  ),
          ),
        ),
        actions: <Widget>[
          RxBuilder(
              builder: (BuildContext context) => IconBadge(
                    icon: const Icon(Icons.sync),
                    itemCount: controller.store.countSync.value,
                    badgeColor: Colors.red,
                    itemColor: Colors.white,
                    maxCount: 99,
                    hideZero: true,
                    onTap: () async {
                      controller.store.sync();
                    },
                  )),
        ],
      );

  Widget customBody(BuildContext context, bool isInited) => Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            colorFilter: const ColorFilter.mode(
                Color.fromRGBO(240, 240, 240, 0.1), BlendMode.modulate),
            image: AssetImage(widget.dadosTela['img']),
            fit: BoxFit.cover,
          ),
        ),
        child: (isInited)
            ? RxBuilder(
                builder: (BuildContext context) =>
                    FutureBuilder<List<StreamAssistido>?>(
                  future: controller.store
                      .search(controller.textEditing.value, "ATIVO"),
                  builder: (_, list) {
                    if ((list.hasData) && (list.data != null)) {
                      _list = list.data;
                      return AssistidoListViewSilver(
                        controller: controller,
                        list: list.data!,
                        functionChamada: chamadaToogleFunc,
                        functionEdit: editAddFunc,
                      );
                    } else if (list.hasError) {
                      return _buildError();
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      );

  Widget customFloatingActionButton(BuildContext context) => SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: const IconThemeData(size: 22.0),
        visible: true,
        closeManually: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        tooltip: 'Opções',
        heroTag: 'Seleciona Opções Diversas',
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 8.0,
        shape: const CircleBorder(),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.collections),
            backgroundColor: Colors.red,
            label: 'Chamada por Image',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              Modular.to.pushNamed(
                "faces",
                arguments: {
                  "assistidos": _list,
                  "chamadaFunc": chamadaFunc,
                  "Title": "Tire sua Foto",
                },
              );
            },
          ),
          SpeedDialChild(
              child: const Icon(Icons.add_box),
              backgroundColor: Colors.blue,
              label: 'Alterar Chamada',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () {
                controller.whatWidget.value = 0;
                _checkDate(context);
              }),
          SpeedDialChild(
            child: const Icon(Icons.assignment_returned),
            backgroundColor: Colors.green,
            label: 'Inserir Usuário',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: editAddFunc,
          ),
          SpeedDialChild(
            child: const Icon(
              Icons.search,
            ),
            backgroundColor: Colors.yellow,
            label: 'Procurar',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              controller.whatWidget.value = 1;
            },
          ),
        ],
      );

  Widget _buildError() {
    return const Center(
      child: Text("Error"),
    );
  }

  void editAddFunc({StreamAssistido? assistido}) {
    Modular.to.pushNamed(
      "insert",
      arguments: {"assistido": assistido},
    );
  }

  void chamadaFunc(StreamAssistido pessoa) {
    if (pessoa.insertChamadaFunc(controller.dateSelected)) {
      controller.countPresente++;
      controller.store.add(pessoa);
    }
  }

  void chamadaToogleFunc(StreamAssistido pessoa) {
    controller.countPresente +=
        pessoa.chamadaToogleFunc(controller.dateSelected);
  }

  void _checkDate(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.background,
            title: const Text("Escolha a data da chamada"),
            titleTextStyle: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
            actionsOverflowButtonSpacing: 20,
            actions: [
              ElevatedButton(
                  onPressed: () {
                    if (controller.itensList.length > 1) {
                      var itensRemove = controller.dateSelected;
                      if (controller.itensList.first != itensRemove) {
                        controller.dateSelected = controller.itensList.first;
                      } else {
                        controller.dateSelected = controller.itensList.last;
                      }
                      var itens = controller.itensList;
                      itens.removeWhere((element) => element == itensRemove);
                      controller.itensList = itens;
                    } else {
                      //Fazer uma mensagem de erro informando que não pode remover todos os elementos.
                    }
                  },
                  child:
                      const Icon(Icons.remove, color: Colors.white, size: 24)),
              ElevatedButton(
                  onPressed: () {
                    _insertData(context);
                  },
                  child: const Icon(Icons.add, color: Colors.white, size: 24)),
              ElevatedButton(
                  onPressed: () {
                    //Navigator.of(context, rootNavigator: true).pop();
                    Modular.to.pop();
                  },
                  child: const Text("Close")),
            ],
            content: assistidosDropdownButton,
          );
        });
  }

  void _insertData(BuildContext context) {
    String value = '';
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.background,
            title: const Text("Escolha a data da chamada"),
            titleTextStyle: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
            actionsOverflowButtonSpacing: 20,
            actions: [
              ElevatedButton(
                  onPressed: () {
                    //Navigator.of(context, rootNavigator: true).pop();
                    Modular.to.pop();
                  },
                  child: const Text("Cancelar")),
              ElevatedButton(
                  onPressed: () {
                    controller.itensList = controller.itensList + [value];
                    controller.dateSelected = value;
                    Modular.to.pop();
                  },
                  child: const Text("Salvar")),
            ],
            content: TextField(
                decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    icon: Icon(Icons.date_range),
                    labelText: 'Informe a data'),
                keyboardType: TextInputType.datetime,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  DataInputFormatter(),
                ],
                onChanged: (v) {
                  value = v;
                }),
          );
        });
  }
}
