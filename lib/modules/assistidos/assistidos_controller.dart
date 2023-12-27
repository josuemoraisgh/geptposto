import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:rx_notifier/rx_notifier.dart';
import '../styles/styles.dart';
import 'models/assistido_models.dart';
import 'models/stream_assistido_model.dart';
import 'provider/assistido_provider_store.dart';

class AssistidosController {
  final textEditing = TextEditingController(text: "");
  final isInitedController = RxNotifier<bool>(false);
  final focusNode = FocusNode();
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
      await sync();
      isInitedController.value = true;
    } else {
      sync();
    }
  }

  List<StreamAssistido> search(
      List<StreamAssistido> assistidoList,String termosDeBusca, String condicao) {
    return assistidoList
        .where((assistido) =>
            // ignore: prefer_interpolation_to_compose_strings
            assistido.condicao.contains(RegExp(r"^(" + condicao + ")")))
        .where((assistido) => assistido.nomeM1
            .toLowerCase()
            .replaceAllMapped(
                RegExp(r'[\W\[\] ]'),
                (Match a) =>
                    caracterMap.containsKey(a[0]) ? caracterMap[a[0]]! : a[0]!)
            .contains(termosDeBusca.toLowerCase()))
        .toList()
      ..sort((a, b) {
        // Primeiro, comparar pelo campo nome
        int comparacao = a.nomeM1.compareTo(b.nomeM1);
        if (comparacao == 0) {
          return a.ident < b.ident ? -1 : 1;
        }
        return comparacao;
      });
  }

  Future<void> sync() async {
    if (await InternetConnectionChecker().hasConnection) {
      dynamic status;
      if (isRunningSync.value == false) {
        isRunningSync.value = true;
        countSync.value = await assistidosProviderStore.syncStore.length();
        while (countSync.value > 0) {
          status = null;
          var sync = await (assistidosProviderStore.syncStore.getSync(0)
            ..whenComplete(() => assistidosProviderStore.syncStore.delSync(0)));
          if (sync != null) {
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
            if (status == null) {
              await assistidosProviderStore.syncStore
                  .addSync(sync.synckey, sync.syncValue);
              break;
            }
          }
          countSync.value = await assistidosProviderStore.syncStore.length();
        }
        var remoteConfigChanges = await assistidosProviderStore.remoteStore
            .getChanges(table: "Config");
        if (remoteConfigChanges != null && remoteConfigChanges.isNotEmpty) {
          for (List e in remoteConfigChanges) {
            e.removeWhere((element) => element == "");
            final listString = e.sublist(1).cast<String>()[0];
            await assistidosProviderStore.configStore.addConfig(
              e[0],
              listString.substring(listString.length - 1) == ";" &&
                      listString.substring(listString.length - 2) != ";"
                  ? listString.substring(0, listString.length - 1).split(";")
                  : listString.split(";"),
            );
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
}
