import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as imglib;
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import 'package:rx_notifier/rx_notifier.dart';
import 'package:geptposto/modules/faces/image_converter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/assistido_list_models.dart';
import '../models/assistido_models.dart';
import '../models/stream_assistido_model.dart';
import '../interfaces/asssistido_remote_storage_interface.dart';
import '../interfaces/assistido_local_storage_interface.dart';
import '../interfaces/sync_local_storage_interface.dart';
import '../services/assistido_ml_service.dart';

class AssistidosStore {
  bool isRunningSync = false;
  static int _countConnection = 0;
  RxNotifier<int> countSync = RxNotifier<int>(0);
  late AssistidoList assistidos = AssistidoList([].cast<Assistido>());
  late final SyncLocalStorageInterface _syncStore;
  late final AssistidoLocalStorageInterface _localStore;
  late final AssistidoRemoteStorageInterface _remoteStorage;
  late final AssistidoMLService _assistidoMmlService;
  void Function()? atualiza;
  void Function()? desatualiza;

  AssistidosStore(
      {SyncLocalStorageInterface? syncStore,
      AssistidoLocalStorageInterface? localStore,
      AssistidoRemoteStorageInterface? remoteStorage,
      AssistidoMLService? assistidoMmlService}) {
    _syncStore = syncStore ?? Modular.get<SyncLocalStorageInterface>();
    _localStore = localStore ?? Modular.get<AssistidoLocalStorageInterface>();
    _remoteStorage =
        remoteStorage ?? Modular.get<AssistidoRemoteStorageInterface>();
    _assistidoMmlService =
        assistidoMmlService ?? Modular.get<AssistidoMLService>();
  }

  Future<void> init() async {
    await _assistidoMmlService.init();
    await _localStore.init();
    await _remoteStorage.init();
    await _syncStore.init();
    sync();
  }

  Future<void> sync() async {
    if (isRunningSync == false) {
      isRunningSync = true;
      countSync.value = await _syncStore.length();
      while ((await _syncStore.length()) > 0) {
        while (_countConnection >= 10) {
          await Future.delayed(const Duration(
              milliseconds: 500)); //so faz 10 requisições por vez.
        }
        _countConnection++;
        dynamic status;
        var sync = await _syncStore.getSync(0);
        await _syncStore.delSync(0);
        if (sync != null) {
          if (sync.synckey == 'add') {
            status =
                await _remoteStorage.addData(sync.syncValue as StreamAssistido);
          }
          if (sync.synckey == 'set') {
            status = await _remoteStorage.setData(
                (sync.syncValue as StreamAssistido).ident,
                (sync.syncValue as StreamAssistido));
          }
          if (sync.synckey == 'del') {
            status =
                await _remoteStorage.deleteData((sync.syncValue as String));
          }
          if (sync.synckey == 'addImage') {
            status = await _remoteStorage.addFile(
                'BDados_Images',
                (sync.syncValue[0] as String),
                (sync.syncValue[1] as Uint8List));
          }
          if (sync.synckey == 'setImage') {
            status = await _remoteStorage.setFile(
                'BDados_Images',
                (sync.syncValue[0] as String),
                (sync.syncValue[1] as Uint8List));
          }
          if (sync.synckey == 'delImage') {
            status = await _remoteStorage.deleteFile(
                'BDados_Images', sync.syncValue);
          }
          if (status != null) {
            countSync.value = await _syncStore.length();
            _countConnection--;
          } else {
            await _syncStore.addSync(sync.synckey, sync.syncValue);
            break;
          }
        }
      }
      var remoteDataChanges = await _remoteStorage.getChanges();
      if (remoteDataChanges != null) {
        for (var e in remoteDataChanges) {
          addJustLocal(StreamAssistido(e));
        }
      }
      isRunningSync = false;
    }
    if (desatualiza != null) desatualiza!();
    if (atualiza != null) atualiza!();
  }

  Future<List<StreamAssistido>?> search(
      String termosDeBusca, String condicao) async {
    Map<String, String> map = {
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
    final listAssist = await getAll();
    if (listAssist != null) {
      var list = listAssist
          .where((assistido) =>
              // ignore: prefer_interpolation_to_compose_strings
              assistido.condicao.contains(RegExp(r"^(" + condicao + ")")))
          .where((assistido) => assistido.nomeM1
              .toLowerCase()
              .replaceAllMapped(RegExp(r'[\W\[\] ]'),
                  (Match a) => map.containsKey(a[0]) ? map[a[0]]! : a[0]!)
              .contains(termosDeBusca.toLowerCase()))
          .toList();
      return (list);
    } else {
      return null;
    }
  }

  Future<List<StreamAssistido>?> getAll() async {
    var resp = (await _localStore.getAll())
        .map((element) => StreamAssistido(element))
        .toList();
    return resp;
  }

  Future<StreamAssistido?> getRow(int rowId) async {
    var resp = await _localStore.getRow(rowId);
    return resp != null ? StreamAssistido(resp) : null;
  }

  Future<String?> add(StreamAssistido? stAssist) async {
    if (stAssist != null) {
      final result = (await _localStore.setRow(stAssist));
      stAssist.saveRemoteFunc = addJustRemote;
      stAssist.delRemoteFunc = delete;
      _syncStore.addSync('set', stAssist).then((_) => sync());
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  Future<String?> addJustLocal(StreamAssistido? stAssist) async {
    if (stAssist != null) {
      final resp = _localStore.setRow(stAssist);
      stAssist.saveRemoteFunc = addJustRemote;
      stAssist.delRemoteFunc = delete;
      resp.then(
        (value) => getPhoto(stAssist),
      );
      return resp;
    }
    return null;
  }

  Future<bool> addJustRemote(StreamAssistido? stAssist) async {
    if (stAssist != null) {
      _syncStore.addSync('add', stAssist).then((_) => sync());
    }
    return true;
  }

  Future<bool> deleteAll() async {
    if (await _localStore.delAll()) {
      return true;
    }
    return false;
  }

  Future<bool> delete(StreamAssistido stAssist) async {
    final rowId = stAssist.ident.toString();
    _syncStore.addSync('del', rowId).then((_) => sync());
    if (await _localStore.delRow(rowId)) {
      return true;
    }
    return false;
  }

  Future<bool> addSetPhoto(
      StreamAssistido? stAssist, final Uint8List uint8ListImage,
      {bool isUpload = true}) async {
    String photoFileName;
    if (stAssist != null && uint8ListImage.isNotEmpty) {
      //Nomeando a arquivo
      final now = DateTime.now();
      final DateFormat formatter = DateFormat('yyyy-MM-dd_H-m-s');
      photoFileName = (stAssist.photoName == "")
          ? '${stAssist.nomeM1.replaceAll(RegExp(r"\s+"), "").toLowerCase()}_${formatter.format(now)}.jpg'
          : stAssist.photoName;

      //Criando o arquivo - Armazenamento Local
      final file =
          await _localStore.addSetFile(photoFileName, uint8ListImage);
      //Processando a imagem para o reconhecimento futuro
      imglib.Image? image = imglib.decodeJpg(uint8ListImage);
      if (image != null) {
        final inputImage = InputImage.fromFile(file);
        final faceDetected =
            await _assistidoMmlService.faceDetector.processImage(inputImage);
        if (faceDetected.isNotEmpty) {
          if (isUpload) {
            final imageAux = cropFace(image, faceDetected[0], step: 80);
            if (imageAux != null) {
              image = imageAux;
              await _localStore.addSetFile(
                  photoFileName, imglib.encodeJpg(image));
            }
          }
          _assistidoMmlService
              .renderizarImage(inputImage, image)
              .then((fotoPoints) {
            stAssist.photo = [
              photoFileName,
              imglib.encodeJpg(image!),
              fotoPoints.cast<num>()
            ];
            stAssist.saveJustLocal();
          });
        }
        if (isUpload) {
          _syncStore.addSync('setImage', [
            photoFileName,
            imglib.encodeJpg(image)
          ]).then((_) => stAssist.saveJustRemote());
        }
        return true;
      }
    }
    return false;
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
            await _remoteStorage.getFile('BDados_Images', stAssist.photoName);
        if (remoteImage != null) {
          if (remoteImage.isNotEmpty) {
            final resp = await addSetPhoto(stAssist, base64.decode(remoteImage),
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
      _syncStore.addSync('delImage', stAssist.photoName).then((_) => sync());
      await _localStore.delFile(stAssist.photoName);
      //Atualiza o cadastro
      stAssist.photo = ["", Uint8List(0), [].cast<num>()];
      _syncStore.addSync('set', stAssist).then((_) => sync());
      await _localStore.setRow(stAssist);
    }
    return false;
  }
}
