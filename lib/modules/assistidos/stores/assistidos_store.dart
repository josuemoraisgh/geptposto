import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as imglib;
import 'package:intl/intl.dart';
import 'package:rx_notifier/rx_notifier.dart';

import 'package:geptposto/modules/faces/image_converter.dart';

import '../interfaces/assistido_local_storage_interface.dart';
import '../interfaces/asssistido_remote_storage_interface.dart';
import '../interfaces/assistido_config_local_storage_interface.dart';
import '../interfaces/sync_local_storage_interface.dart';
import '../models/assistido_models.dart';
import '../models/stream_assistido_model.dart';
import '../services/assistido_ml_service.dart';

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

class AssistidosStoreList {
  late final AssistidoMLService assistidoMmlService;
  late final AssistidoLocalStorageInterface localStore;
  late final AssistidoRemoteStorageInterface remoteStore;
  late final AssistidoConfigLocalStorageInterface configStore;
  late final SyncLocalStorageInterface syncStore;
  AssistidosStoreList(
      {SyncLocalStorageInterface? syncStoreAux,
      AssistidoLocalStorageInterface? localStoreAux,
      AssistidoConfigLocalStorageInterface? configStoreAux,
      AssistidoRemoteStorageInterface? remoteStoreAux,
      AssistidoMLService? assistidoMmlServiceAux}) {
    syncStore = syncStoreAux ?? Modular.get<SyncLocalStorageInterface>();
    localStore = localStoreAux ?? Modular.get<AssistidoLocalStorageInterface>();
    configStore =
        configStoreAux ?? Modular.get<AssistidoConfigLocalStorageInterface>();
    remoteStore =
        remoteStoreAux ?? Modular.get<AssistidoRemoteStorageInterface>();
    assistidoMmlService =
        assistidoMmlServiceAux ?? Modular.get<AssistidoMLService>();
  }

  void Function()? atualiza;
  void Function()? desatualiza;
  final countSync = RxNotifier<int>(0);
  bool isRunningSync = false;

  static int _countConnection = 0;

  final _assistidoList = [].cast<StreamAssistido>();
  final StreamController<List<StreamAssistido>> _assistidoListStream =
      StreamController<List<StreamAssistido>>.broadcast();
  Stream<List<StreamAssistido>> get stream => _assistidoListStream.stream;

  late final Stream<BoxEvent> dateSelectedController;
  late final Stream<BoxEvent> itensListController;

  Future<void> init() async {
    await assistidoMmlService.init();
    await localStore.init();
    await configStore.init();
    dateSelectedController = configStore
        .watch("dateSelected")
        .asBroadcastStream() as Stream<BoxEvent>;
    itensListController =
        configStore.watch("itensList").asBroadcastStream() as Stream<BoxEvent>;
    await remoteStore.init();
    await syncStore.init();
    _assistidoList.addAll(
      (await localStore.getAll()).map(
        (element) => StreamAssistido(element)
          ..saveJustLocalExt = addSaveJustLocal
          ..saveJustRemoteExt = addSaveJustRemote
          ..deleteExt = delete,
      ),
    );
    sync();
    _assistidoListStream.sink.add(_assistidoList);
  }

  Future<void> sync() async {
    if (isRunningSync == false) {
      isRunningSync = true;
      countSync.value = await syncStore.length();
      while ((await syncStore.length()) > 0) {
        while (_countConnection >= 10) {
          await Future.delayed(const Duration(
              milliseconds: 500)); //so faz 10 requisições por vez.
        }
        _countConnection++;
        dynamic status;
        var sync = await syncStore.getSync(0);
        await syncStore.delSync(0);
        if (sync != null) {
          if (sync.synckey == 'add') {
            status = await remoteStore
                .addData((sync.syncValue as StreamAssistido).toList());
          }
          if (sync.synckey == 'set') {
            status = await remoteStore.setData(
                (sync.syncValue as StreamAssistido).ident.toString(),
                (sync.syncValue as StreamAssistido).toList());
          }
          if (sync.synckey == 'del') {
            status = await remoteStore.deleteData((sync.syncValue as String));
          }
          if (sync.synckey == 'addImage') {
            status = await remoteStore.addFile(
                'BDados_Images',
                (sync.syncValue[0] as String),
                (sync.syncValue[1] as Uint8List));
          }
          if (sync.synckey == 'setImage') {
            status = await remoteStore.setFile(
                'BDados_Images',
                (sync.syncValue[0] as String),
                (sync.syncValue[1] as Uint8List));
          }
          if (sync.synckey == 'delImage') {
            status =
                await remoteStore.deleteFile('BDados_Images', sync.syncValue);
          }
          if (status != null) {
            countSync.value = await syncStore.length();
            _countConnection--;
          } else {
            await syncStore.addSync(sync.synckey, sync.syncValue);
            break;
          }
        }
      }
      var remoteConfigChanges = await remoteStore.getChanges(table: "Config");
      if (remoteConfigChanges != null && remoteConfigChanges.isNotEmpty) {
        for (List e in remoteConfigChanges) {
          e.removeWhere((element) => element == "");
          await configStore.addConfig(e[0], e.sublist(1).cast<String>());
        }
      }
      var remoteDataChanges = await remoteStore.getChanges();
      if (remoteDataChanges != null) {
        final keys = await localStore.getKeys();
        for (var e in remoteDataChanges) {
          addSaveJustLocal(StreamAssistido(Assistido.fromList(e)),
              isAdd: (keys.contains(e[0])) ? false : true);
        }
      }
      isRunningSync = false;
    }
    if (desatualiza != null) desatualiza!();
    if (atualiza != null) atualiza!();
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

  Future<StreamAssistido?> getRow(int rowId) async {
    var resp = await localStore.getRow(rowId);
    return resp != null ? StreamAssistido(resp) : null;
  }

  Future<String?> add(StreamAssistido stAssist) async {
    addSaveJustRemote(stAssist, isAdd: true);
    return addSaveJustLocal(stAssist, isAdd: true);
  }

  Future<bool> addSaveJustRemote(StreamAssistido stAssist,
      {bool isAdd = false}) async {
    syncStore.addSync(isAdd ? 'add' : 'set', stAssist).then((_) => sync());
    return true;
  }

  Future<String?> addSaveJustLocal(StreamAssistido stAssist,
      {bool isAdd = false}) async {
    if (isAdd) {
      stAssist
        ..saveJustLocalExt = addSaveJustLocal
        ..saveJustRemoteExt = addSaveJustRemote
        ..deleteExt = delete;
    }
    return localStore.setRow(stAssist)
      ..then(
        (value) async {
          if (isAdd) {
            _assistidoListStream.sink.add(_assistidoList..add(stAssist));
          }
          getPhoto(stAssist);
        },
      );
  }

  Future<bool> deleteAll() async {
    if (await localStore.delAll()) {
      return true;
    }
    return false;
  }

  Future<bool> delete(StreamAssistido stAssist) async {
    final rowId = stAssist.ident.toString();
    syncStore.addSync('del', rowId).then((_) => sync());
    if (await localStore.delRow(rowId)) {
      return true;
    }
    return false;
  }

  Future<bool> addSetPhoto(
      StreamAssistido? stAssist, final Uint8List uint8ListImage,
      {bool isUpload = true}) async {
    String photoFileName;
    List<double> fotoPoints = [];
    if (stAssist != null && uint8ListImage.isNotEmpty) {
      //Nomeando o arquivo
      final now = DateTime.now();
      final DateFormat formatter = DateFormat('yyyy-MM-dd_H-m-s');
      photoFileName = (stAssist.photoName == "")
          ? '${stAssist.nomeM1.replaceAll(RegExp(r"\s+"), "").toLowerCase()}_${formatter.format(now)}.jpg'
          : stAssist.photoName;
      //Criando o arquivo - Armazenamento Local
      final file = await localStore.addSetFile('aux.jpg', uint8ListImage);
      //Processando a imagem para o reconhecimento futuro
      imglib.Image? image = imglib.decodeJpg(uint8ListImage);
      if (image != null) {
        final inputImage = InputImage.fromFile(file);
        final faceDetected =
            await assistidoMmlService.faceDetector.processImage(inputImage);
        if (faceDetected.isNotEmpty) {
          image = isUpload
              ? cropFace(image, faceDetected[0], step: 80) ?? image
              : image;
          fotoPoints = (await assistidoMmlService.classificatorImage(image));
        }
        stAssist.photo = [
          photoFileName,
          imglib.encodeJpg(image),
          fotoPoints,
        ];
        stAssist.saveJustLocal();
        if (isUpload) {
          syncStore.addSync(
            'setImage',
            [photoFileName, imglib.encodeJpg(image)],
          ).then((_) => stAssist.saveJustRemote());
        }
        return true;
      }
    }
    return false;
  }

  Future<bool> addConfig(String ident, List<String>? values) {
    return configStore.addConfig(ident, values);
  }

  Future<List<String>?> getConfig(String ident) {
    return configStore.getConfig(ident);
  }

  Future<void> delConfig(String ident) {
    return configStore.delConfig(ident);
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
        var remoteImage =
            await remoteStore.getFile('BDados_Images', stAssist.photoName);
        if (remoteImage != null) {
          if (remoteImage.isNotEmpty) {
            final resp = await addSetPhoto(stAssist, base64Decode(remoteImage),
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
      syncStore.addSync('delImage', stAssist.photoName).then((_) => sync());
      await localStore.delFile(stAssist.photoName);
      //Atualiza o cadastro
      stAssist.photo = ["", Uint8List(0), []];
      stAssist.save();
    }
    return false;
  }
}
