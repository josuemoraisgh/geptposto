import 'dart:async';
import 'package:flutter_modular/flutter_modular.dart';
import '../interfaces/assistido_storage_interface.dart';
import '../interfaces/remote_storage_interface.dart';
import '../interfaces/config_storage_interface.dart';
import '../interfaces/sync_local_storage_interface.dart';
import '../models/assistido_models.dart';
import '../services/face_detection_service.dart';

class AssistidosProviderStore {
  late final AssistidoStorageInterface localStore;
  late final RemoteStorageInterface remoteStore;
  late final ConfigStorageInterface configStore;
  late final SyncStorageInterface syncStore;
  late final FaceDetectionService assistidoMmlService;
  AssistidosProviderStore(
      {SyncStorageInterface? syncStoreAux,
      AssistidoStorageInterface? localStoreAux,
      ConfigStorageInterface? configStoreAux,
      RemoteStorageInterface? remoteStoreAux,
      FaceDetectionService? assistidoMmlServiceAux}) {
    syncStore = syncStoreAux ?? Modular.get<SyncStorageInterface>();
    localStore = localStoreAux ?? Modular.get<AssistidoStorageInterface>();
    configStore =
        configStoreAux ?? Modular.get<ConfigStorageInterface>();
    remoteStore =
        remoteStoreAux ?? Modular.get<RemoteStorageInterface>();
    assistidoMmlService =
        assistidoMmlServiceAux ?? Modular.get<FaceDetectionService>();
  }

  Future<void> init() async {
    await localStore.init();
    await configStore.init();
    await remoteStore.init();
    await syncStore.init();
    await assistidoMmlService.init();
  }

  Future<Assistido?> getRow(int rowId) async {
    var resp = await localStore.getRow(rowId);
    return resp;
  }

  Future<String?> add(Assistido stAssist) async {
    addSaveJustRemote(stAssist, isAdd: true);
    return addSaveJustLocal(stAssist, isAdd: true);
  }

  Future<String?> save(Assistido stAssist) async {
    addSaveJustRemote(stAssist, isAdd: false);
    return addSaveJustLocal(stAssist, isAdd: false);
  }

  Future<bool> addSaveJustRemote(Assistido stAssist,
      {bool isAdd = false}) async {
    syncStore.addSync(isAdd ? 'add' : 'set', stAssist);
    return true;
  }

  Future<String?> addSaveJustLocal(Assistido stAssist,
      {bool isAdd = false}) async {
    return isAdd ? localStore.setRow(stAssist) : localStore.setRow(stAssist);
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
}
