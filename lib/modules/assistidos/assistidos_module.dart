import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../app_module.dart';
import 'provider/assistido_provider_store.dart';
import 'services/sync_storage_service.dart';
import 'pages/assistido_face_detector_page.dart';
import 'assistidos_page.dart';
import 'pages/assistidos_edit_insert_page.dart';
import 'services/remote_storage_service.dart';
import 'services/assistido_storage_service.dart';
import 'services/config_storage_service.dart';
import 'services/face_detection_service.dart';
import 'assistidos_controller.dart';

class AssistidosModule extends Module {
  @override
  List<Module> get imports => [
        AppModule(),
      ];

  @override
  void binds(Injector i) {
    i.addSingleton<AssistidosController>(
      () => AssistidosController(
        assistidosProviderStore: AssistidosProviderStore(
          syncStore: SyncStorageService(),
          localStore: AssistidoStorageService(),
          configStore: ConfigStorageService(),
          remoteStore: AssistidoRemoteStorageService(provider: Dio()),
          faceDetectionService: FaceDetectionService(),
        ),
      ),
    );
    /*i.addInstance<AssistidosController>(
      AssistidosController(
        assistidosStoreList: AssistidosStoreList(
          syncStore: SyncStorageService(),
          localStore: AssistidoStorageService(),
          configStore: ConfigStorageService(),
          remoteStore: AssistidoRemoteStorageService(provider: Dio()),
          faceDetectionService: FaceDetectionService(),
        ),
      ),
    );*/
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
