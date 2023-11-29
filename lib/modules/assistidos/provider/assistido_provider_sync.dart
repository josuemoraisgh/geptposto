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

  void Function()? atualiza;
  void Function()? desatualiza;

  bool isRunningSync = false;
  final countSync = RxNotifier<int>(0);

  late final Stream<BoxEvent> dateSelectedController;
  late final Stream<BoxEvent> itensListController;

  int _countConnection = 0;

  AssistidoProviderSync({AssistidosProviderStore? assistidoProviderStoreAux}) {
    assistidoProviderStore =
        assistidoProviderStoreAux ?? Modular.get<AssistidosProviderStore>();
  }

  Future<void> init() async {
    dateSelectedController = assistidoProviderStore.configStore
        .watch("dateSelected")
        .asBroadcastStream() as Stream<BoxEvent>;
    itensListController = assistidoProviderStore.configStore
        .watch("itensList")
        .asBroadcastStream() as Stream<BoxEvent>;
    assistidoProviderStore.syncStore.addListener(sync);
    sync();
    assistidoProviderStore.localStore.addListener(sinkAdd);
    sinkAdd();
  }

  Future<void> sinkAdd() async {
    _assistidoChangeStream.sink.add(
      (await assistidoProviderStore.localStore.getAll())
          .map((element) => StreamAssistido(element, assistidoProviderStore))
          .toList(),
    );
  }

  Future<void> sync() async {
    if (isRunningSync == false) {
      isRunningSync = true;
      countSync.value = await assistidoProviderStore.syncStore.length();
      while ((await assistidoProviderStore.syncStore.length()) > 0) {
        while (_countConnection >= 10) {
          await Future.delayed(const Duration(
              milliseconds: 500)); //so faz 10 requisições por vez.
        }
        _countConnection++;
        dynamic status;
        var sync = await assistidoProviderStore.syncStore.getSync(0);
        await assistidoProviderStore.syncStore.delSync(0);
        if (sync != null) {
          if (sync.synckey == 'add') {
            status = await assistidoProviderStore.remoteStore
                .addData((sync.syncValue as StreamAssistido).toList());
          }
          if (sync.synckey == 'set') {
            status = await assistidoProviderStore.remoteStore.setData(
                (sync.syncValue as StreamAssistido).ident.toString(),
                (sync.syncValue as StreamAssistido).toList());
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
          assistidoProviderStore.localStore.setRow(stAssist).then(
            (value) async {
              getPhoto(stAssist);
            },
          );
        }
      }
      isRunningSync = false;
    }
    if (desatualiza != null) desatualiza!();
    if (atualiza != null) atualiza!();
  }

  Future<bool> addConfig(String ident, List<String>? values) {
    return assistidoProviderStore.configStore.addConfig(ident, values);
  }

  Future<List<String>?> getConfig(String ident) {
    return assistidoProviderStore.configStore.getConfig(ident);
  }

  Future<void> delConfig(String ident) {
    return assistidoProviderStore.configStore.delConfig(ident);
  }

  Future<bool> getPhoto(StreamAssistido? stAssist) async {
    if (stAssist != null) {
      if (stAssist.photoName.isNotEmpty) {
        if (stAssist.photoUint8List.isNotEmpty) {
          return true;
        }
        while (_countConnection >= 10) {
          //so faz 10 requisições por vez.
          await Future.delayed(const Duration(milliseconds: 500));
        }
        _countConnection++;
        var remoteImage = await assistidoProviderStore.remoteStore
            .getFile('BDados_Images', stAssist.photoName);
        if (remoteImage != null) {
          if (remoteImage.isNotEmpty) {
            final resp = await stAssist.addSetPhoto(base64Decode(remoteImage),
                isUpload: false);
            _countConnection--;
            return resp;
          }
        }
        _countConnection--;
      }
    }
    return false;
  }

  Future<bool> delPhoto(StreamAssistido? stAssist) async {
    if (stAssist != null) {
      //Atualiza os arquivos
      assistidoProviderStore.syncStore
          .addSync('delImage', stAssist.photoName)
          .then((_) => sync());
      await assistidoProviderStore.localStore.delFile(stAssist.photoName);
      //Atualiza o cadastro
      stAssist.photo = ["", Uint8List(0), []];
      stAssist.save();
    }
    return false;
  }

  Future<bool> delete(StreamAssistido stAssist) async {
    final rowId = stAssist.ident.toString();
    assistidoProviderStore.syncStore.addSync('del', rowId).then((_) => sync());
    if (await assistidoProviderStore.localStore.delRow(rowId)) {
      return true;
    }
    return false;
  }
}
