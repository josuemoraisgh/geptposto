import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive/hive.dart';
import '../interfaces/assistido_storage_interface.dart';
import '../interfaces/remote_storage_interface.dart';
import '../interfaces/config_storage_interface.dart';
import '../interfaces/sync_storage_interface.dart';
import '../models/assistido_models.dart';
import '../services/face_detection_service.dart';

class AssistidosProviderStore {
  late final AssistidoStorageInterface localStore;
  late final RemoteStorageInterface remoteStore;
  late final ConfigStorageInterface configStore;
  late final SyncStorageInterface syncStore;
  late final FaceDetectionService faceDetectionService;
  late final ValueListenable<Box<Assistido>> localStoreListenable;

  AssistidosProviderStore(
      {SyncStorageInterface? syncStore,
      AssistidoStorageInterface? localStore,
      ConfigStorageInterface? configStore,
      RemoteStorageInterface? remoteStore,
      FaceDetectionService? faceDetectionService}) {
    this.syncStore = syncStore ?? Modular.get<SyncStorageInterface>();
    this.localStore = localStore ?? Modular.get<AssistidoStorageInterface>();
    this.configStore = configStore ?? Modular.get<ConfigStorageInterface>();
    this.remoteStore = remoteStore ?? Modular.get<RemoteStorageInterface>();
    this.faceDetectionService =
        faceDetectionService ?? Modular.get<FaceDetectionService>();
  }

  Future<void> init() async {
    await localStore.init();
    await configStore.init();
    await remoteStore.init();
    await syncStore.init();
    await faceDetectionService.init();
  }

  Future<Assistido?> getRow(int rowId) async {
    var resp = await localStore.getRow(rowId);
    return resp;
  }

  Future<bool> deleteAll() async {
    if (await localStore.delAll()) {
      return true;
    }
    return false;
  }

  Future<bool> delete(Assistido stAssist) async {
    final rowId = stAssist.ident.toString();
    syncStore.addSync('del', rowId);
    if (await localStore.delRow(rowId)) {
      return true;
    }
    return false;
  }

  Future<bool> setConfig(String ident, List<String>? values) async {
    if (values != null) {
      syncStore.addSync('setConfig', [ident, values.join(";")]);
      return configStore.addConfig(ident, values);
    }
    return false;
  }

  Future<List<String>?> getConfig(String ident) {
    return configStore.getConfig(ident);
  }
}
