import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:rx_notifier/rx_notifier.dart';
import 'interfaces/config_local_storage_interface.dart';
import 'stores/assistidos_store.dart';

class AssistidosController {
  final isInitedController = RxNotifier<bool>(false);
  final textEditing = RxNotifier<String>("");
  final countPresenteController = RxNotifier<int>(0);
  final focusNode = FocusNode();
  final presentCount = RxNotifier<int>(0);
  final dateSelectedController = RxNotifier<String>('12/03/2023');
  final itensListController = RxNotifier<List<String>>([
    '22/01/2023',
    '29/01/2023',
    '05/02/2023',
    '12/02/2023',
    '19/02/2023',
    '26/02/2023',
    '05/03/2023',
    '12/03/2023',
    '19/03/2023',
    '26/03/2023'
  ]);
  final whatWidget = RxNotifier<int>(0);
  late final AssistidosStore store;
  late final ConfigLocalStorageInterface configStore;

  AssistidosController(
      {AssistidosStore? store, ConfigLocalStorageInterface? configStore}) {
    this.store = store ?? Modular.get<AssistidosStore>();
    this.configStore =
        configStore ?? Modular.get<ConfigLocalStorageInterface>();
    store?.atualiza = () => isInitedController.value = true;
    store?.desatualiza = () => isInitedController.value = false;
  }

  Future<bool> init() async {
    await store.init();
    await configStore.init();
    var itens = await configStore.getConfig("itensList");
    if (itens != null) {
      if (itens.isNotEmpty) {
        itensListController.value = itens;
      }
    }
    var date = await configStore.getConfig("dateSelected");
    if (date != null) {
      if (date.isNotEmpty) {
        dateSelectedController.value = date.first;
      }
    }
    store.sync();
    return true;
  }

  int get countPresente => countPresenteController.value;
  set countPresente(int value) {
    Future.delayed(const Duration(seconds: 0),
        () => countPresenteController.value = value);
  }

  String get dateSelected => dateSelectedController.value;

  set dateSelected(String value) {
    configStore.addConfig("dateSelected", [value]);
    Future.delayed(
        const Duration(seconds: 0), () => dateSelectedController.value = value);
  }

  List<String> get itensList => itensListController.value;

  set itensList(List<String> value) {
    configStore.addConfig("itensList", value);
    Future.delayed(
        const Duration(seconds: 0), () => itensListController.value = value);
  }
}
