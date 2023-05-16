import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:rx_notifier/rx_notifier.dart';
import 'stores/assistidos_store.dart';

class AssistidosController {
  final isInitedController = RxNotifier<bool>(false);
  final textEditing = TextEditingController(text: "");
  final countPresenteController = RxNotifier<int>(0);
  final focusNode = FocusNode();
  final presentCount = RxNotifier<int>(0);
  final whatWidget = RxNotifier<int>(0);
  late final AssistidosStoreList assistidosStoreList;

  AssistidosController({AssistidosStoreList? assistidosStoreList}) {
    this.assistidosStoreList =
        assistidosStoreList ?? Modular.get<AssistidosStoreList>();
    assistidosStoreList?.atualiza = () => isInitedController.value = true;
    assistidosStoreList?.desatualiza = () => isInitedController.value = false;
  }

  Future<bool> init() async {
    await assistidosStoreList.init();
    assistidosStoreList.sync();
    return true;
  }

  int get countPresente => countPresenteController.value;
  set countPresente(int value) {
    Future.delayed(const Duration(seconds: 0),
        () => countPresenteController.value = value);
  }
}
