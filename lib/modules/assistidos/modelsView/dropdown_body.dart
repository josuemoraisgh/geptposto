import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../assistidos_controller2.dart';

class DropdownBody extends StatefulWidget {
  final AssistidosController controller;
  const DropdownBody({super.key, required this.controller});

  @override
  State<DropdownBody> createState() => _DropdownBodyState();
}

class _DropdownBodyState extends State<DropdownBody> {
  BoxEvent dateSelected = BoxEvent("", ["01/01/2023"], false);
  BoxEvent itensList = BoxEvent("", ["01/01/2023"], false);

  @override
  void initState() {
    super.initState();
  }

  Future<bool> init() async {
    try {
      final List<String>? aux1 =
          await widget.controller.assistidoProviderSync.assistidoProviderStore.getConfig('dateSelected');
      final List<String>? aux2 =
          await widget.controller.assistidoProviderSync.assistidoProviderStore.getConfig('itensList');
      if ((aux1 != null) && (aux1.isNotEmpty)) {
        dateSelected = BoxEvent("", aux1, false);
      }
      if ((aux2 != null) && (aux2.isNotEmpty)) {
        itensList = BoxEvent("", aux2, false);
      }
    } catch (e) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: init(),
      builder: (BuildContext context, AsyncSnapshot<void> value) => value
              .hasData
          ? StreamBuilder(
              initialData: dateSelected,
              stream:
                  widget.controller.assistidoProviderSync.dateSelectedController,
              builder: (BuildContext context,
                      AsyncSnapshot<BoxEvent> dateSelected) =>
                  StreamBuilder(
                initialData: itensList,
                stream:
                    widget.controller.assistidoProviderSync.itensListController,
                builder:
                    (BuildContext context, AsyncSnapshot<BoxEvent> itensList) =>
                        DropdownButton<String>(
                  iconEnabledColor: Colors.white,
                  dropdownColor: Theme.of(context).colorScheme.background,
                  focusColor: Theme.of(context).colorScheme.background,
                  items: itensList.data!.value
                      .map((String dropDownStringItem) {
                        return DropdownMenuItem<String>(
                          value: dropDownStringItem,
                          child: Text(
                            dropDownStringItem,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                        );
                      })
                      .toList()
                      .cast<DropdownMenuItem<String>>(),
                  onChanged: (String? novoItemSelecionado) {
                    if (novoItemSelecionado != null) {
                      widget.controller.assistidoProviderSync.assistidoProviderStore
                          .setConfig("dateSelected", [novoItemSelecionado]);
                    }
                  },
                  value: dateSelected.data!.value[0],
                ),
              ),
            )
          : const CircularProgressIndicator(),
    );
  }
}
