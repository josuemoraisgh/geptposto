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
import 'modelsView/custom_search_bar.dart';
import 'modelsView/dropdown_body.dart';
import 'modelsView/assistido_listview_silver.dart';

class AssistidosPage extends StatefulWidget {
  final Map<String, dynamic> dadosTela;
  const AssistidosPage({Key? key, required this.dadosTela}) : super(key: key);

  @override
  State<AssistidosPage> createState() => _AssistidosPageState();
}

class _AssistidosPageState extends State<AssistidosPage> {
  final AssistidosController controller = Modular.get<AssistidosController>();
  final DropdownBody assistidosDropdownButton =
      DropdownBody(controller: Modular.get<AssistidosController>());
  @override
  void initState() {
    super.initState();
    controller.init();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<StreamAssistido>>(
        initialData: const [],
        stream: controller.assistidosStoreList.stream,
        builder: (BuildContext context,
                AsyncSnapshot<List<StreamAssistido>> assistidoList) =>
            ValueListenableBuilder<bool>(
          valueListenable: controller.isInitedController,
          builder: (BuildContext context, bool isInited, _) =>
              ValueListenableBuilder(
            valueListenable: controller.textEditing,
            builder:
                (BuildContext context, TextEditingValue textEditingValue, _) {
              List<StreamAssistido> list = [];
              if (isInited && assistidoList.hasData) {
                list = controller.assistidosStoreList.search(
                  assistidoList.data!,
                  textEditingValue.text,
                  widget.dadosTela['title'] == 'Todos'
                      ? ''
                      : widget.dadosTela['title'] == 'Ativos'
                          ? 'ATIVO'
                          : 'INATIVO',
                );
                controller.countPresente = 0;
              }
              return Scaffold(
                appBar: customAppBar(isInited),
                body: isInited
                    ? customBody(context, list)
                    : const Center(child: CircularProgressIndicator()),
                floatingActionButton:
                    isInited ? customFloatingActionButton(context, list) : null,
              );
            },
          ),
        ),
      );

  AppBar customAppBar(bool isInited) => AppBar(
        title: bg.Badge(
          badgeStyle: const bg.BadgeStyle(badgeColor: Colors.green),
          position: bg.BadgePosition.topStart(top: 0),
          badgeContent: RxBuilder(
              builder: (BuildContext context) => Text(
                  '${controller.countPresente}',
                  style: const TextStyle(color: Colors.white, fontSize: 10.0))),
          child: RxBuilder(
            builder: (BuildContext context) => controller.whatWidget.value == 0
                ? (isInited)
                    ? Row(
                        children: [
                          const Text("Chamada: "),
                          assistidosDropdownButton,
                        ],
                      )
                    : const Text("Inicializando")
                : CustomSearchBar(
                    textController: controller.textEditing,
                    focusNode: controller.focusNode,
                  ),
          ),
        ),
        actions: <Widget>[
          RxBuilder(
            builder: (BuildContext context) => IconBadge(
              icon: const Icon(Icons.sync),
              itemCount: controller.assistidosStoreList.countSync.value,
              badgeColor: Colors.red,
              itemColor: Colors.white,
              maxCount: 99,
              hideZero: true,
              onTap: () async {
                controller.assistidosStoreList.sync();
              },
            ),
          ),
        ],
      );

  Widget customBody(
          BuildContext context, List<StreamAssistido> assistidoList) =>
      Container(
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
        child: AssistidoListViewSilver(
          controller: controller,
          list: assistidoList,
          functionChamada: chamadaToogleFunc,
          functionEdit: editAddFunc,
        ),
      );

  Widget customFloatingActionButton(
          BuildContext context, List<StreamAssistido> assistidoList) =>
      SpeedDial(
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
            /*onTap: () => chamadaTesteFunc(
                assistidos:
                    assistidoList), */
            onTap: () {
              Modular.to.pushNamed(
                "faces",
                arguments: {
                  "assistidos": assistidoList,
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

  void editAddFunc({StreamAssistido? assistido}) {
    Modular.to.pushNamed(
      "insert",
      arguments: {"assistido": assistido},
    );
  }

  Future chamadaFunc(StreamAssistido assistido) async {
    final dateSelected =
        await controller.assistidosStoreList.getConfig("dateSelected");
    if (assistido.insertChamadaFunc(dateSelected)) {
      controller.countPresente++;
    }
  }

  Future chamadaToogleFunc(StreamAssistido pessoa) async {
    final dateSelected =
        await controller.assistidosStoreList.getConfig("dateSelected");
    controller.countPresente += pessoa.chamadaToogleFunc(dateSelected);
  }

  Future _checkDate(BuildContext context) async {
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
                  onPressed: () async {
                    final dateSelected = (await controller.assistidosStoreList
                        .getConfig("dateSelected"))?[0];
                    final itensList = await controller.assistidosStoreList
                        .getConfig("itensList");
                    if (itensList!.length > 1 && dateSelected != null) {
                      var itensRemove = dateSelected;
                      if (itensList.last != itensRemove) {
                        controller.assistidosStoreList
                            .addConfig("dateSelected", [itensList.last]);
                      } else {
                        controller.assistidosStoreList.addConfig("dateSelected",
                            [itensList.elementAt(itensList.length - 2)]);
                      }
                      final itens = itensList
                          .where((element) => element != itensRemove)
                          .toList();
                      controller.assistidosStoreList
                          .addConfig("itensList", itens);
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
                  onPressed: () async {
                    final itensList = await controller.assistidosStoreList
                        .getConfig("itensList");
                    if (itensList != null) {
                      controller.assistidosStoreList
                          .addConfig("itensList", itensList + [value]);
                      controller.assistidosStoreList
                          .addConfig("dateSelected", [value]);
                      Modular.to.pop();
                    }
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
