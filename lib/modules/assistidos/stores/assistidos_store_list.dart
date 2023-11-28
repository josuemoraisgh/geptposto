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

import '../models/assistido_models.dart';
import '../models/stream_assistido_model.dart';
import '../services/assistido_ml_service.dart';
import 'assistidos_store.dart';

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
  late final AssistidosStore assistidosStore;
  AssistidosStoreList(
      {AssistidosStore? assistidosStoreAux,
      AssistidoMLService? assistidoMmlServiceAux}) {
    assistidosStore = assistidosStoreAux ?? Modular.get<AssistidosStore>();
    assistidoMmlService =
        assistidoMmlServiceAux ?? Modular.get<AssistidoMLService>();
  }

  void Function()? atualiza;
  void Function()? desatualiza;
  final countSync = RxNotifier<int>(0);
  bool isRunningSync = false;

  static int _countConnection = 0;

  final _assistidoList = [].cast<StreamAssistido>();
  late final ValueListenable<Box<Assistido>> _assistidoListStream;
  late final Stream<BoxEvent> dateSelectedController;
  late final Stream<BoxEvent> itensListController;

  Future<void> init() async {
    await assistidoMmlService.init();
    await assistidosStore.localStore.init();
    await assistidosStore.configStore.init();
    dateSelectedController = assistidosStore.configStore
        .watch("dateSelected")
        .asBroadcastStream() as Stream<BoxEvent>;
    itensListController = assistidosStore.configStore
        .watch("itensList")
        .asBroadcastStream() as Stream<BoxEvent>;
    await assistidosStore.remoteStore.init();
    await assistidosStore.syncStore.init();
    _assistidoList.addAll(
      (await assistidosStore.localStore.getAll())
          .map((element) => StreamAssistido(element, assistidosStore)),
    );
    sync();
    _assistidoListStream = assistidosStore.localStore.listenable();
  }

  Future<void> sync() async {
    if (isRunningSync == false) {
      isRunningSync = true;
      countSync.value = await assistidosStore.syncStore.length();
      while ((await assistidosStore.syncStore.length()) > 0) {
        while (_countConnection >= 10) {
          await Future.delayed(const Duration(
              milliseconds: 500)); //so faz 10 requisições por vez.
        }
        _countConnection++;
        dynamic status;
        var sync = await assistidosStore.syncStore.getSync(0);
        await assistidosStore.syncStore.delSync(0);
        if (sync != null) {
          if (sync.synckey == 'add') {
            status = await assistidosStore.remoteStore
                .addData((sync.syncValue as StreamAssistido).toList());
          }
          if (sync.synckey == 'set') {
            status = await assistidosStore.remoteStore.setData(
                (sync.syncValue as StreamAssistido).ident.toString(),
                (sync.syncValue as StreamAssistido).toList());
          }
          if (sync.synckey == 'del') {
            status = await assistidosStore.remoteStore
                .deleteData((sync.syncValue as String));
          }
          if (sync.synckey == 'addImage') {
            status = await assistidosStore.remoteStore.addFile(
                'BDados_Images',
                (sync.syncValue[0] as String),
                (sync.syncValue[1] as Uint8List));
          }
          if (sync.synckey == 'setImage') {
            status = await assistidosStore.remoteStore.setFile(
                'BDados_Images',
                (sync.syncValue[0] as String),
                (sync.syncValue[1] as Uint8List));
          }
          if (sync.synckey == 'delImage') {
            status = await assistidosStore.remoteStore
                .deleteFile('BDados_Images', sync.syncValue);
          }
          if (status != null) {
            countSync.value = await assistidosStore.syncStore.length();
            _countConnection--;
          } else {
            await assistidosStore.syncStore
                .addSync(sync.synckey, sync.syncValue);
            break;
          }
        }
      }
      var remoteConfigChanges =
          await assistidosStore.remoteStore.getChanges(table: "Config");
      if (remoteConfigChanges != null && remoteConfigChanges.isNotEmpty) {
        for (List e in remoteConfigChanges) {
          e.removeWhere((element) => element == "");
          await assistidosStore.configStore
              .addConfig(e[0], e.sublist(1).cast<String>());
        }
      }
      var remoteDataChanges = await assistidosStore.remoteStore.getChanges();
      if (remoteDataChanges != null) {
        final keys = await assistidosStore.localStore.getKeys();
        for (var e in remoteDataChanges) {
          addSaveJustLocal(
              StreamAssistido(Assistido.fromList(e), assistidosStore),
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
    var assistido = await assistidosStore.getRow(rowId);
    return assistido != null
        ? StreamAssistido(assistido, assistidosStore)
        : null;
  }

  Future<String?> add(StreamAssistido stAssist) async {
    addSaveJustRemote(stAssist, isAdd: true);
    return addSaveJustLocal(stAssist, isAdd: true);
  }

  Future<bool> addSaveJustRemote(StreamAssistido stAssist,
      {bool isAdd = false}) async {
    assistidosStore
        .addSaveJustRemote(stAssist.assistido, isAdd: isAdd)
        .then((_) => sync());
    return true;
  }

  Future<String?> addSaveJustLocal(StreamAssistido stAssist,
      {bool isAdd = false}) async {
    return assistidosStore.localStore.setRow(stAssist)
      ..then(
        (value) async {
          if (isAdd) {
            _assistidoList.add(stAssist);
          }
          getPhoto(stAssist);
        },
      );
  }

  Future<bool> deleteAll() async {
    if (await assistidosStore.localStore.delAll()) {
      return true;
    }
    return false;
  }

  Future<bool> delete(StreamAssistido stAssist) async {
    final rowId = stAssist.ident.toString();
    assistidosStore.syncStore.addSync('del', rowId).then((_) => sync());
    if (await assistidosStore.localStore.delRow(rowId)) {
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
      final file = await assistidosStore.localStore
          .addSetFile('aux.jpg', uint8ListImage);
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
          assistidosStore.syncStore.addSync(
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
    return assistidosStore.configStore.addConfig(ident, values);
  }

  Future<List<String>?> getConfig(String ident) {
    return assistidosStore.configStore.getConfig(ident);
  }

  Future<void> delConfig(String ident) {
    return assistidosStore.configStore.delConfig(ident);
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
        var remoteImage = await assistidosStore.remoteStore
            .getFile('BDados_Images', stAssist.photoName);
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
      assistidosStore.syncStore
          .addSync('delImage', stAssist.photoName)
          .then((_) => sync());
      await assistidosStore.localStore.delFile(stAssist.photoName);
      //Atualiza o cadastro
      stAssist.photo = ["", Uint8List(0), []];
      stAssist.save();
    }
    return false;
  }
}
