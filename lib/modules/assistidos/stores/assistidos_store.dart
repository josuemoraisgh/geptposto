import 'dart:async';
import 'package:flutter_modular/flutter_modular.dart';
import '../interfaces/assistido_local_storage_interface.dart';
import '../interfaces/asssistido_remote_storage_interface.dart';
import '../interfaces/assistido_config_local_storage_interface.dart';
import '../interfaces/sync_local_storage_interface.dart';
import '../models/assistido_models.dart';
import '../services/assistido_ml_service.dart';

class AssistidosStore {
  late final AssistidoLocalStorageInterface localStore;
  late final AssistidoRemoteStorageInterface remoteStore;
  late final AssistidoConfigLocalStorageInterface configStore;
  late final SyncLocalStorageInterface syncStore;
  late final AssistidoMLService assistidoMmlService;
  AssistidosStore(
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
    addSaveJustRemote(stAssist, isAdd: true);
    return addSaveJustLocal(stAssist, isAdd: true);
  }

  Future<bool> addSaveJustRemote(Assistido stAssist,
      {bool isAdd = false}) async {
    syncStore.addSync(isAdd ? 'add' : 'set', stAssist);
    return true;
  }

  Future<String?> addSaveJustLocal(Assistido stAssist,
      {bool isAdd = false}) async {
    return localStore.setRow(stAssist);
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
