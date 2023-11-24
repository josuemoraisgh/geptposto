import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../assistidos_controller.dart';

class DropdownBody extends StatelessWidget {
  final AssistidosController controller; //Lista com os items
  const DropdownBody({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: BoxEvent("", ["01/01/2023"], false),
      stream: controller.assistidosStoreList.dateSelectedController,
      builder: (BuildContext context, AsyncSnapshot<BoxEvent> dateSelected) =>
          StreamBuilder(
        initialData: BoxEvent("", ["01/01/2023"], false),
        stream: controller.assistidosStoreList.itensListController,
        builder: (BuildContext context, AsyncSnapshot<BoxEvent> itensList) =>
            DropdownButton<String>(
          dropdownColor: Theme.of(context).colorScheme.background,
          style: const TextStyle(
              fontSize: 18, color: Colors.white, decorationColor: Colors.black),
          items: itensList.data!.value
              .map((String dropDownStringItem) {
                return DropdownMenuItem<String>(
                  value: dropDownStringItem,
                  child: Text(dropDownStringItem),
                );
              })
              .toList()
              .cast<DropdownMenuItem<String>>(),
          onChanged: (String? novoItemSelecionado) {
            if (novoItemSelecionado != null) {
              controller.assistidosStoreList
                  .addConfig("dateSelected", [novoItemSelecionado]);
            }
          },
          value: dateSelected.data!.value[0],
        ),
      ),
    );
  }
}
