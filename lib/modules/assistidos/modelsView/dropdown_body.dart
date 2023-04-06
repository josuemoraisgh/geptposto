import 'package:flutter/material.dart';
import 'package:rx_notifier/rx_notifier.dart';

class DropdownBody extends StatelessWidget {
  final RxNotifier<List<String>> itensListController; //Lista com os items
  final RxNotifier<String> dateSelectedController;
  const DropdownBody({
    Key? key,
    required this.itensListController,
    required this.dateSelectedController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RxBuilder(
        builder: (BuildContext context) => DropdownButton<String>(
            dropdownColor: Theme.of(context).colorScheme.background,
            style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                decorationColor: Colors.black),
            items: itensListController.value.map((String dropDownStringItem) {
              return DropdownMenuItem<String>(
                value: dropDownStringItem,
                child: Text(dropDownStringItem),
              );
            }).toList(),
            onChanged: (String? novoItemSelecionado) {
              if (novoItemSelecionado != null) {
                dateSelectedController.value = novoItemSelecionado;
              }
            },
            value: dateSelectedController.value));
  }
}
