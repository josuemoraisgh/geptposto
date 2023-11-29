import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive/hive.dart';
import 'package:rx_notifier/rx_notifier.dart';
import '../models/assistido_models.dart';
import '../models/stream_assistido_model2.dart';
import 'assistido_provider_store.dart';

class AssistidoProviderSync {
  late final AssistidosProviderStore assistidoProviderStore;

  final StreamController<List<StreamAssistido>> _assistidoChangeStream =
      StreamController<List<StreamAssistido>>.broadcast();
  Stream<List<StreamAssistido>> get stream => _assistidoChangeStream.stream;

  final isRunningSync = RxNotifier<bool>(false);
  final countSync = RxNotifier<int>(0);

  late final Stream<BoxEvent> dateSelectedController;
  late final Stream<BoxEvent> itensListController;

  static int _countConnection = 0;

  AssistidoProviderSync({AssistidosProviderStore? assistidoProviderStore}) {
    this.assistidoProviderStore =
        assistidoProviderStore ?? Modular.get<AssistidosProviderStore>();
  }

  Future<void> init() async {
    assistidoProviderStore.init();

    dateSelectedController = assistidoProviderStore.configStore
        .watch("dateSelected")
        .asBroadcastStream() as Stream<BoxEvent>;

    itensListController = assistidoProviderStore.configStore
        .watch("itensList")
        .asBroadcastStream() as Stream<BoxEvent>;

    (await assistidoProviderStore.localStore.listenable()).addListener(() => sinkAdd());
    (await assistidoProviderStore.syncStore.listenable()).addListener(() => sync());

    sinkAdd();
    sync();
  }

  Future<void> sinkAdd() async {
    final tst = (await assistidoProviderStore.localStore.getAll())
        .map((element) => StreamAssistido(element, assistidoProviderStore))
        .toList();
    _assistidoChangeStream.sink.add(tst);
  }

  Future<void> sync() async {
    dynamic status;    
    if (isRunningSync.value == false) {
      isRunningSync.value = true;
      countSync.value = await assistidoProviderStore.syncStore.length();
      while ((await assistidoProviderStore.syncStore.length()) > 0) {
        while (_countConnection >= 10) {
          await Future.delayed(const Duration(
              milliseconds: 500)); //so faz 10 requisições por vez.
        }
        _countConnection++;
        status = null;
        var sync = await assistidoProviderStore.syncStore.getSync(0);
        await assistidoProviderStore.syncStore.delSync(0);
        if (sync != null) {
          if (sync.synckey == 'add') {
            status = await assistidoProviderStore.remoteStore
                .addData((sync.syncValue as Assistido).toList());
          }
          if (sync.synckey == 'set') {
            status = await assistidoProviderStore.remoteStore.setData(
                (sync.syncValue as Assistido).ident.toString(),
                (sync.syncValue as Assistido).toList());
          }
          if (sync.synckey == 'del') {
            status = await assistidoProviderStore.remoteStore
                .deleteData((sync.syncValue as String));
          }
          if (sync.synckey == 'addImage') {
            status = await assistidoProviderStore.remoteStore.addFile(
                'BDados_Images',
                (sync.syncValue[0] as String),
                (sync.syncValue[1] as Uint8List));
          }
          if (sync.synckey == 'setImage') {
            status = await assistidoProviderStore.remoteStore.setFile(
                'BDados_Images',
                (sync.syncValue[0] as String),
                (sync.syncValue[1] as Uint8List));
          }
          if (sync.synckey == 'delImage') {
            status = await assistidoProviderStore.remoteStore
                .deleteFile('BDados_Images', sync.syncValue);
          }
          if (sync.synckey == 'setConfig') {
            status = await assistidoProviderStore.remoteStore.setData(
                (sync.syncValue as List<String>)[0].toString(),
                (sync.syncValue as List<String>).sublist(1).toList(),
                table: 'Config');
          }
          if (sync.synckey == 'getPhoto') {
            var stAssist = (sync.syncValue as StreamAssistido);
            if (stAssist.photoName.isNotEmpty) {
              if (stAssist.photoUint8List.isEmpty) {
                var remoteImage = await assistidoProviderStore.remoteStore
                    .getFile('BDados_Images', stAssist.photoName);
                if (remoteImage != null) {
                  if (remoteImage.isNotEmpty) {
                    status = (await stAssist.addSetPhoto(base64Decode(remoteImage),
                        isUpload: false)) == true ? true : null;
                  }
                }
              }
            }
          }
          if (status != null) {
            countSync.value = await assistidoProviderStore.syncStore.length();
            _countConnection--;
          } else {
            await assistidoProviderStore.syncStore
                .addSync(sync.synckey, sync.syncValue);
            break;
          }
        }
      }
      var remoteConfigChanges =
          await assistidoProviderStore.remoteStore.getChanges(table: "Config");
      if (remoteConfigChanges != null && remoteConfigChanges.isNotEmpty) {
        for (List e in remoteConfigChanges) {
          e.removeWhere((element) => element == "");
          await assistidoProviderStore.configStore
              .addConfig(e[0], e.sublist(1).cast<String>());
        }
      }
      var remoteDataChanges =
          await assistidoProviderStore.remoteStore.getChanges();
      if (remoteDataChanges != null) {
        for (var e in remoteDataChanges) {
          final stAssist =
              StreamAssistido(Assistido.fromList(e), assistidoProviderStore);
          assistidoProviderStore.localStore.setRow(stAssist).then((value) =>
              assistidoProviderStore.syncStore.addSync('getPhoto', stAssist));
        }
      }
      isRunningSync.value = false;
    }
  }
}
