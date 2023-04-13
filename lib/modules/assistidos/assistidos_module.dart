import 'package:camera/camera.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:geptposto/modules/assistidos/services/assistido_ml_service.dart';
import '../assistidos/services/sync_hive_local_storage_service.dart';
import 'pages/assistido_face_detector_page.dart';
import 'assistidos_controller.dart';
import 'assistidos_page.dart';
import 'interfaces/assistido_local_storage_interface.dart';
import 'interfaces/asssistido_remote_storage_interface.dart';
import 'interfaces/config_local_storage_interface.dart';
import 'interfaces/provider_interface.dart';
import 'interfaces/sync_local_storage_interface.dart';
import 'pages/assistidos_edit_insert_page.dart';
import 'repositories/assistido_gsheet_repository.dart';
import 'services/assistido_hive_local_storage_service.dart';
import 'services/config_hive_local_storage_service.dart';
import 'stores/assistidos_store.dart';

class AssistidosModule extends Module {
  @override
  List<Bind<Object>> get binds => [
        Bind.lazySingleton<AssistidoMLService>(
            (i) => AssistidoMLService()),
        Bind.lazySingleton<Future<List<CameraDescription>>>(
            (i) => availableCameras()),
        Bind.lazySingleton<ProviderInterface>((i) => ProviderInterface()),
        Bind.lazySingleton<ConfigLocalStorageInterface>(
            (i) => ConfigLocalStorageService()),
        Bind.lazySingleton<AssistidoLocalStorageInterface>(
            (i) => AssistidoLocalStorageService()),
        Bind.lazySingleton<AssistidoRemoteStorageInterface>((i) =>
            AssistidoRemoteStorageRepository(provider: i<ProviderInterface>())),
        Bind.lazySingleton<SyncLocalStorageInterface>(
            (i) => SyncLocalStorageService()),
        Bind.lazySingleton<AssistidosStore>((i) => AssistidosStore(
            syncStore: i<SyncLocalStorageInterface>(),
            localStore: i<AssistidoLocalStorageInterface>(),
            remoteStorage: i<AssistidoRemoteStorageInterface>())),
        Bind.singleton<AssistidosController>((i) => AssistidosController(
              store: i<AssistidosStore>(),
              configStore: i<ConfigLocalStorageService>(),
            )),
      ];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(
      '/',
      child: (_, args) => AssistidosPage(
        dadosTela: args.data,
      ),
      customTransition: myCustomTransition,
    ),
    ChildRoute(
      '/faces',
      child: (_, args) => AssistidoFaceDetectorPage(
        assistidos: args.data["assistidos"],
        chamadaFunc: args.data["chamadaFunc"],
        title: args.data["Title"],
      ),
      customTransition: myCustomTransition,
    ),
    ChildRoute(
      '/insert',
      child: (_, args) => AssistidoEditInsertPage(
        assistido: args.data["assistido"],
      ),
      customTransition: myCustomTransition,
    ),    
  ];

  static get myCustomTransition => null;
}
