import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:rx_notifier/rx_notifier.dart';
import 'models/stream_assistido_model2.dart';
import 'provider/assistido_provider_sync.dart';

Map<String, String> _caracterMap = {
  "â": "a",
  "à": "a",
  "á": "a",
  "ã": "a",
  "ê": "e",
  "è": "e",
  "é": "e",
  "î": "i",
  "ì": "i",
  "í": "i",
  "õ": "o",
  "ô": "o",
  "ò": "o",
  "ó": "o",
  "ü": "u",
  "û": "u",
  "ú": "u",
  "ù": "u",
  "ç": "c"
};

class AssistidosController {
  final textEditing = TextEditingController(text: "");
  final countPresenteController = RxNotifier<int>(0);
  final isInitedController = RxNotifier<bool>(false);
  final focusNode = FocusNode();
  final presentCount = RxNotifier<int>(0);
  final whatWidget = RxNotifier<int>(0);
  final assistidoProvavelList = RxNotifier<List<StreamAssistido>>([]);
  final faceDetector = RxNotifier<bool>(false);

  late final AssistidoProviderSync assistidoProviderSync;

  AssistidosController({AssistidoProviderSync? assistidoProviderSync}) {
    this.assistidoProviderSync =
        assistidoProviderSync ?? Modular.get<AssistidoProviderSync>();
  }

  Future<void> init() async {
    if (isInitedController.value == false) {
      isInitedController.value = true;
      await assistidoProviderSync.init();
    }
    assistidoProviderSync.sync();
  }

  int get countPresente => countPresenteController.value;
  set countPresente(int value) {
    Future.delayed(const Duration(seconds: 0),
        () => countPresenteController.value = value);
  }

  List<StreamAssistido> search(
      List<StreamAssistido> assistidoList, termosDeBusca, String condicao) {
    return assistidoList
        .where((assistido) =>
            // ignore: prefer_interpolation_to_compose_strings
            assistido.condicao.contains(RegExp(r"^(" + condicao + ")")))
        .where((assistido) => assistido.nomeM1
            .toLowerCase()
            .replaceAllMapped(
                RegExp(r'[\W\[\] ]'),
                (Match a) => _caracterMap.containsKey(a[0])
                    ? _caracterMap[a[0]]!
                    : a[0]!)
            .contains(termosDeBusca.toLowerCase()))
        .toList();
  }
}
