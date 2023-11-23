import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:geptposto/modules/assistidos/services/assistido_ml_service.dart';
import 'package:geptposto/modules/faces/camera_controle_service.dart';
import '../assistidos/services/sync_hive_local_storage_service.dart';
import 'pages/assistido_face_detector_page.dart';
import 'assistidos_controller.dart';
import 'assistidos_page.dart';
import 'interfaces/assistido_local_storage_interface.dart';
import 'interfaces/asssistido_remote_storage_interface.dart';
import 'interfaces/assistido_config_local_storage_interface.dart';
import 'interfaces/sync_local_storage_interface.dart';
import 'pages/assistidos_edit_insert_page.dart';
import 'repositories/assistido_gsheet_repository.dart';
import 'services/assistido_hive_local_storage_service.dart';
import 'services/assistido_config_hive_local_storage_service.dart';
import 'stores/assistidos_store.dart';

class AssistidosModule extends Module {
  @override
void binds(Injector i) {
        i.addInstance<CameraService>(CameraService());
        i.addInstance<AssistidoMLService>(AssistidoMLService());
        i.addInstance<Dio>(Dio());
        i.addInstance<AssistidoConfigLocalStorageInterface>(
            AssistidoConfigLocalStorageService());
        i.addInstance<AssistidoLocalStorageInterface>(
            AssistidoLocalStorageService());
        i.addInstance<AssistidoRemoteStorageInterface>(
            AssistidoRemoteStorageRepository(provider: i<Dio>()));
        i.addInstance<SyncLocalStorageInterface>(
            SyncLocalStorageService());
        i.addInstance<AssistidosStoreList>(AssistidosStoreList(
            syncStore: i<SyncLocalStorageInterface>(),
            localStore: i<AssistidoLocalStorageInterface>(),
            configStore: i<AssistidoConfigLocalStorageService>(),
            remoteStore: i<AssistidoRemoteStorageInterface>()));
        i.addInstance<AssistidosController>(AssistidosController(
            assistidosStoreList: i<AssistidosStoreList>()));
}

  @override
  void routes(r) {
    r.child(
      '/',
      child: (_) => AssistidosPage(
        dadosTela: r.args.data,
      ),
      transition: TransitionType.custom,
      customTransition: CustomTransition(
        transitionBuilder: (context, anim1, anim2, child) {
          return FadeTransition(
            opacity: anim1,
            child: child,
          );
        },
      ),
    );
    r.child(
      '/faces',
      child: (_) => AssistidoFaceDetectorPage(
        assistido: r.args.data["assistido"],
        assistidos: r.args.data["assistidos"],
        chamadaFunc: r.args.data["chamadaFunc"],
        title: "Camera Ativa",
      ),
      transition: TransitionType.custom,
      customTransition: CustomTransition(
        transitionBuilder: (context, anim1, anim2, child) {
          return FadeTransition(
            opacity: anim1,
            child: child,
          );
        },
      ),
    );
    r.child(
      '/insert',
      child: (_) => AssistidoEditInsertPage(
        assistido: r.args.data["assistido"],
      ),
      transition: TransitionType.custom,
      customTransition: CustomTransition(
        transitionBuilder: (context, anim1, anim2, child) {
          return FadeTransition(
            opacity: anim1,
            child: child,
          );
        },
      ),
    );
  }
}

class CustomTransitionBuilder extends PageTransitionsBuilder {
  const CustomTransitionBuilder();
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    final tween =
        Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.ease));
    return ScaleTransition(
        scale: animation.drive(tween),
        child: FadeTransition(opacity: animation, child: child));
  }
}
