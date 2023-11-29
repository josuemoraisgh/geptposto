import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:rx_notifier/rx_notifier.dart';
import 'models/stream_assistido_model.dart';
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
  final isInitedController = RxNotifier<bool>(false);
  final textEditing = TextEditingController(text: "");
  final countPresenteController = RxNotifier<int>(0);
  final focusNode = FocusNode();
  final presentCount = RxNotifier<int>(0);
  final whatWidget = RxNotifier<int>(0);
  final assistidoProvavelList = RxNotifier<List<StreamAssistido>>([]);
  final faceDetector = RxNotifier<bool>(false);

  late final AssistidoProviderSync assistidosStoreSync;

  AssistidosController({AssistidoProviderSync? assistidosStoreSyncAux}) {
    assistidosStoreSync =
        assistidosStoreSyncAux ?? Modular.get<AssistidoProviderSync>();
    assistidosStoreSync.atualiza = () => isInitedController.value = true;
    assistidosStoreSync.desatualiza = () => isInitedController.value = false;
  }

  Future<bool> init() async {
    await assistidosStoreSync.init();
    assistidosStoreSync.sync();
    return true;
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
