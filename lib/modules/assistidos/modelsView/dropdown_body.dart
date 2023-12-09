import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../assistidos_controller.dart';

class DropdownBody extends StatefulWidget {
  final AssistidosController controller;
  const DropdownBody({super.key, required this.controller});

  @override
  State<DropdownBody> createState() => _DropdownBodyState();
}

class _DropdownBodyState extends State<DropdownBody> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          widget.controller.assistidosProviderStore.getConfig('dateSelected'),
      builder: (BuildContext context, AsyncSnapshot<List<String>?> dateSel) =>
          FutureBuilder(
        future:
            widget.controller.assistidosProviderStore.getConfig('itensList'),
        builder: (BuildContext context,
                AsyncSnapshot<List<String>?> itensLis) =>
            dateSel.hasData
                ? StreamBuilder(
                    initialData: BoxEvent("", dateSel.data, false),
                    stream: widget
                        .controller.assistidosProviderStore.configStore
                        .watch("dateSelected")
                        .asBroadcastStream() as Stream<BoxEvent>,
                    builder: (BuildContext context,
                            AsyncSnapshot<BoxEvent> dateSelected) =>
                        itensLis.hasData
                            ? StreamBuilder(
                                initialData: BoxEvent("", itensLis.data, false),
                                stream: widget.controller
                                    .assistidosProviderStore.configStore
                                    .watch("itensList")
                                    .asBroadcastStream() as Stream<BoxEvent>,
                                builder: (BuildContext context,
                                        AsyncSnapshot<BoxEvent> itensList) =>
                                    SizedBox(
                                  height: 25,
                                  child: DropdownButton<String>(
                                    value: dateSelected.data!.value[0],
                                    onChanged: (String? novoItemSelecionado) {
                                      if (novoItemSelecionado != null) {
                                        widget
                                            .controller.assistidosProviderStore
                                            .setConfig("dateSelected",
                                                [novoItemSelecionado]);
                                      }
                                    },
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ),
                                    underline: Container(),
                                    iconEnabledColor: Colors.white,
                                    dropdownColor: Theme.of(context)
                                        .colorScheme
                                        .background,
                                    focusColor: Theme.of(context)
                                        .colorScheme
                                        .background,
                                    selectedItemBuilder:
                                        (BuildContext context) {
                                      return (itensList.data!.value
                                              as List<String>)
                                          .map((String value) {
                                            return Text(
                                              value,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                            );
                                          })
                                          .toList()
                                          .cast<Widget>();
                                    },
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
                                  ),
                                ),
                              )
                            : const Center(child: CircularProgressIndicator()),
                  )
                : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
