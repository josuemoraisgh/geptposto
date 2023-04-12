import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:rx_notifier/rx_notifier.dart';
import '../interfaces/asssistido_remote_storage_interface.dart';
import '../interfaces/assistido_local_storage_interface.dart';
import '../interfaces/sync_local_storage_interface.dart';
import '../models/assistido_models.dart';
import 'package:image/image.dart' as imglib;

class AssistidosStore {
  bool isRunningSync = false;
  RxNotifier<int> countSync = RxNotifier<int>(0);
  static int _countConnection = 0;
  late final SyncLocalStorageInterface _syncStore;
  late final AssistidoLocalStorageInterface _localStore;
  late final AssistidoRemoteStorageInterface _remoteStorage;
  void Function()? atualiza;
  void Function()? desatualiza;

  AssistidosStore(
      {SyncLocalStorageInterface? syncStore,
      AssistidoLocalStorageInterface? localStore,
      AssistidoRemoteStorageInterface? remoteStorage}) {
    _syncStore = syncStore ?? Modular.get<SyncLocalStorageInterface>();
    _localStore = localStore ?? Modular.get<AssistidoLocalStorageInterface>();
    _remoteStorage =
        remoteStorage ?? Modular.get<AssistidoRemoteStorageInterface>();
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
            status = await _remoteStorage.addData(sync.syncValue as Assistido);
          }
          if (sync.synckey == 'set') {
            status = await _remoteStorage.setData(
                (sync.syncValue as Assistido).ident,
                (sync.syncValue as Assistido));
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

  Future<List<Assistido>?> search(String termosDeBusca, String condicao) async {
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

  Future<File?> getImg(Assistido assistido) async {
    final fileName = assistido.photoName;
    File result = await _localStore.getFile(fileName);
    if ((await result.exists()) == true) {
      return result;
    }
    while (_countConnection >= 10) {
      //so faz 10 requisições por vez.
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _countConnection++;
    var remoteImage = await _remoteStorage.getFile('BDados_Images', fileName);
    if (remoteImage != null) {
      if (remoteImage.isNotEmpty) {
        imglib.Image? image = imglib.decodeImage(base64.decode(remoteImage));
        if (image != null) {
          result = await _localStore.addSetFile(assistido, image);
          _countConnection--;
          return result;
        }
      }
    }
    _countConnection--;
    return null;
  }

  Future<List<Assistido>?> getAll() async {
    var resp = _localStore.getAll();
    return resp;
  }

  Future<Assistido?> getRow(int rowId) async {
    var resp = _localStore.getRow(rowId);
    return resp;
  }

  Future<String?> setRow(Assistido pessoa) async {
    pessoa.updatedApps = "";
    _syncStore.addSync('set', pessoa);
    final result = (await _localStore.setRow(pessoa));
    sync();
    if (result != null) {
      return result;
    }
    return null;
  }

  Future<bool> add(Assistido? pessoa) async {
    if (pessoa != null) {
      _syncStore.addSync('add', pessoa);
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

  Future<bool> addImage(Assistido pessoa, imglib.Image imageLib) async {
    final Uint8List data = imageLib.toUint8List();
    _syncStore
        .addSync('addImage', [pessoa.photoName, data]); //base64.encode(data)]);
    await _localStore.addSetFile(pessoa, imageLib);
    _syncStore.addSync('set', pessoa);
    sync();
    await _localStore.setRow(pessoa);
    return false;
  }

  Future<bool> setImage(Assistido pessoa, imglib.Image imageLib,
      final InputImage inputImage) async {
    final Uint8List data = imageLib.toUint8List();
    _syncStore.addSync(
        'setImage', [pessoa.photoName, data]); // base64.encode(data)]);
    sync();
    await _localStore.addSetFile(pessoa, imageLib, inputImage);
    return false;
  }

  Future<bool> deleteImage(Assistido pessoa) async {
    final photoName = pessoa.photoName;
    final Assistido assist = pessoa.changeItens("Foto", "");
    _syncStore.addSync('set', assist);
    sync();
    _syncStore.addSync('delImage', photoName);
    sync();
    await _localStore.delFile(photoName);
    await _localStore.setRow(assist);
    return false;
  }
}
