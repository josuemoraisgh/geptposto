import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive/hive.dart';
import 'package:rx_notifier/rx_notifier.dart';
import 'models/assistido_models.dart';
import 'models/stream_assistido_model.dart';
import 'provider/assistido_provider_store.dart';

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
  final isRunningSync = RxNotifier<bool>(false);
  final countSync = RxNotifier<int>(0);

  late final ValueListenable<Box<Assistido>> listenableAssistido;
  late final AssistidosProviderStore assistidosProviderStore;

  AssistidosController({AssistidosProviderStore? assistidosProviderStore}) {
    this.assistidosProviderStore =
        assistidosProviderStore ?? Modular.get<AssistidosProviderStore>();
  }

  Future<void> init() async {
    if (isInitedController.value == false) {
      await assistidosProviderStore.init();      
      listenableAssistido =
          (await assistidosProviderStore.localStore.listenable());
      (await assistidosProviderStore.syncStore.listenable())
          .addListener(() => sync());
      isInitedController.value = true;          
    }
    sync();
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

  Future<void> sync() async {
    dynamic status;
    if (isRunningSync.value == false) {
      isRunningSync.value = true;
      countSync.value = await assistidosProviderStore.syncStore.length();
      while ((await assistidosProviderStore.syncStore.length()) > 0) {
        status = null;
        var sync = await assistidosProviderStore.syncStore.getSync(0);
        await assistidosProviderStore.syncStore.delSync(0);
        if (sync != null) {
          if (sync.synckey == 'add') {
            status = await assistidosProviderStore.remoteStore
                .addData((sync.syncValue as Assistido).toList());
          }
          if (sync.synckey == 'set') {
            status = await assistidosProviderStore.remoteStore.setData(
                (sync.syncValue as Assistido).ident.toString(),
                (sync.syncValue as Assistido).toList());
          }
          if (sync.synckey == 'del') {
            status = await assistidosProviderStore.remoteStore
                .deleteData((sync.syncValue as String));
          }
          if (sync.synckey == 'addImage') {
            status = await assistidosProviderStore.remoteStore.addFile(
                'BDados_Images',
                (sync.syncValue[0] as String),
                (sync.syncValue[1] as Uint8List));
          }
          if (sync.synckey == 'setImage') {
            status = await assistidosProviderStore.remoteStore.setFile(
                'BDados_Images',
                (sync.syncValue[0] as String),
                (sync.syncValue[1] as Uint8List));
          }
          if (sync.synckey == 'delImage') {
            status = await assistidosProviderStore.remoteStore
                .deleteFile('BDados_Images', sync.syncValue);
          }
          if (sync.synckey == 'setConfig') {
            status = await assistidosProviderStore.remoteStore.setData(
                (sync.syncValue as List<String>)[0].toString(),
                (sync.syncValue as List<String>).sublist(1).toList(),
                table: 'Config');
          }
          if (status != null) {
            countSync.value = await assistidosProviderStore.syncStore.length();
          } else {
            await assistidosProviderStore.syncStore
                .addSync(sync.synckey, sync.syncValue);
            break;
          }
        }
      }
      var remoteConfigChanges =
          await assistidosProviderStore.remoteStore.getChanges(table: "Config");
      if (remoteConfigChanges != null && remoteConfigChanges.isNotEmpty) {
        for (List e in remoteConfigChanges) {
          e.removeWhere((element) => element == "");
          await assistidosProviderStore.configStore
              .addConfig(e[0], e.sublist(1).cast<String>());
        }
      }
      var remoteDataChanges =
          await assistidosProviderStore.remoteStore.getChanges();
      if (remoteDataChanges != null) {
        for (var e in remoteDataChanges) {
          final stAssist =
              StreamAssistido(Assistido.fromList(e), assistidosProviderStore);
          assistidosProviderStore.localStore.setRow(stAssist);
        }
      }
      isRunningSync.value = false;
    } else {
      await Future.delayed(
          const Duration(milliseconds: 500)); //so faz 10 requisições por vez.
      sync();
    }
  }
}
