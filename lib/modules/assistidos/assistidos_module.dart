import 'package:flutter_modular/flutter_modular.dart';
import '../assistidos/services/sync_hive_local_storage_service.dart';
import '../faces/face_detector_view.dart';
import 'assistidos_controller.dart';
import 'assistidos_page.dart';
import 'interfaces/assistido_local_storage_interface.dart';
import 'interfaces/asssistido_remote_storage_interface.dart';
import 'interfaces/config_local_storage_interface.dart';
import 'interfaces/provider_interface.dart';
import 'interfaces/sync_local_storage_interface.dart';
import 'repositories/assistido_gsheet_repository.dart';
import 'services/assistido_hive_local_storage_service.dart';
import 'services/config_hive_local_storage_service.dart';
import 'stores/assistidos_store.dart';

class AssistidosModule extends Module {
  @override
  List<Bind<Object>> get binds => [
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
      child: (_, args) => FaceDetectorView(
        dadosTela: args.data,
      ),
      customTransition: myCustomTransition,
    ),
  ];

  static get myCustomTransition => null;
}
