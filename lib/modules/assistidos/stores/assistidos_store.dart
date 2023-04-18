import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as imglib;
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rx_notifier/rx_notifier.dart';
import 'package:geptposto/modules/faces/image_converter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/stream_assistido_model.dart';
import '../interfaces/asssistido_remote_storage_interface.dart';
import '../interfaces/assistido_local_storage_interface.dart';
import '../interfaces/sync_local_storage_interface.dart';
import '../services/assistido_ml_service.dart';

class AssistidosStore {
  bool isRunningSync = false;
  static int _countConnection = 0;
  RxNotifier<int> countSync = RxNotifier<int>(0);
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
        await _localStore.add(remoteDataChanges);
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

  Future<String?> setRow(StreamAssistido stAssist) async {
    stAssist.updatedApps = "";
    _syncStore.addSync('set', stAssist);
    final result = (await _localStore.setRow(stAssist.assistido));
    sync();
    if (result != null) {
      return result;
    }
    return null;
  }

  Future<bool> add(StreamAssistido? stAssist) async {
    if (stAssist != null) {
      _syncStore.addSync('add', stAssist.assistido);
    }
    sync();
    return true;
  }

  Future<bool> deleteAll() async {
    if (await _localStore.delAll()) {
      sync();
      return true;
    }
    return false;
  }

  Future<bool> delete(String rowId) async {
    _syncStore.addSync('del', rowId);
    if (await _localStore.delRow(rowId)) {
      sync();
      return true;
    }
    return false;
  }

  Future<bool> addSetPhoto(
      StreamAssistido? stAssist, final Uint8List uint8ListImage) async {
    if (stAssist != null && uint8ListImage.isNotEmpty) {
      //Estabelecendo os pontos
      stAssist.photoUint8List = uint8ListImage;
      //Nomeando a arquivo
      final now = DateTime.now();
      final DateFormat formatter = DateFormat('yyyy-MM-dd_H-m-s');
      if (stAssist.photoName == "") {
        stAssist.photoName =
            '${stAssist.nomeM1.replaceAll(RegExp(r"\s+"), "")}_${formatter.format(now)}.jpg';
      }
      //Criando o arquivo - Armazenamento Local
      final directory = await getApplicationDocumentsDirectory();
      var buffer = uint8ListImage.buffer;
      ByteData byteData = ByteData.view(buffer);
      if (await File('${directory.path}/${stAssist.photoName}').exists()) {
        await File('${directory.path}/${stAssist.photoName}')
            .delete(recursive: true);
      }
      final file = await File('${directory.path}/${stAssist.photoName}')
          .writeAsBytes(buffer.asUint8List(
              byteData.offsetInBytes, byteData.lengthInBytes));
      //Processando a imagem para o reconhecimento futuro
      final imglib.Image? image = imglib.decodeJpg(uint8ListImage);
      if (image != null) {
        final inputImage = InputImage.fromFile(file);
        final faceDetected =
            await _assistidoMmlService.faceDetector.processImage(inputImage);
        if (faceDetected.isEmpty) {
          _syncStore.addSync(
              'setImage', [stAssist.photoName, imglib.encodeJpg(image)]);
          sync();
          setRow(stAssist);
        } else {
          final image2 = cropFace(image, faceDetected[0], step: 80);
          if (image2 != null) {
            _syncStore.addSync(
                'setImage', [stAssist.photoName, imglib.encodeJpg(image2)]);
            sync();
            _assistidoMmlService
                .renderizarImage(inputImage, image2)
                .then((fotoPoints) {
              stAssist.fotoPoints = fotoPoints.cast<num>();
              setRow(stAssist);
            });
          }
        }
      }
      return true;
    }
    return false;
  }

  Future<bool> addImage(
      String? fileName, final Uint8List uint8ListImage) async {
    if (fileName != null) {
      _syncStore.addSync(
          'addImage', [fileName, uint8ListImage]); //base64.encode(data)]);
      await _localStore.addSetFile(fileName, uint8ListImage);
      sync();
    }
    return false;
  }

  Future<bool> setImage(
      String? fileName, final Uint8List uint8ListImage) async {
    if (fileName != null) {
      _syncStore.addSync(
          'setImage', [fileName, uint8ListImage]); // base64.encode(data)]);
      sync();
      await _localStore.addSetFile(fileName, uint8ListImage);
    }
    return false;
  }

  Future<Uint8List?> getImg(StreamAssistido? stAssist) async {
    if (stAssist != null) {
      if (stAssist.photoName.isNotEmpty && stAssist.photoUint8List != null) {
        if (stAssist.photoUint8List!.isNotEmpty) {
          return stAssist.photoUint8List!;
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
            await addSetPhoto(stAssist, base64.decode(remoteImage));
            _countConnection--;
            return base64.decode(remoteImage);
          }
        }
        _countConnection--;
      }
    }
    return null;
  }

  Future<bool> deleteImage(String? fileName) async {
    if (fileName != null) {
      _syncStore.addSync('delImage', fileName);
      sync();
      await _localStore.delFile(fileName);
    }
    return false;
  }
}
