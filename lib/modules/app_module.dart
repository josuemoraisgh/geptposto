import 'package:flutter_modular/flutter_modular.dart';
import 'assistidos/assistidos_module.dart';
import 'colaboradores/colaboradores_module.dart';
import 'config/config_module.dart';
import 'faces/camera_controle_service.dart';
import 'home/home_module.dart';
import 'info/info_module.dart';
import 'login/login_module.dart';
import 'notfound_page.dart';
import 'splash_page.dart';

class AppModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.addInstance<CameraService>(CameraService());
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const SplashPage());
    r.module('/home', module: HomeModule());
    r.module('/assistidos', module: AssistidosModule());
    r.module('/colaboradores', module: ColaboradoresModule());
    r.module('/login', module: LoginModule());
    r.module('/config', module: ConfigModule());
    r.module('/info', module: InfoModule());
    r.wildcard(child: (context) => const NotFoundPage());
  }
}
