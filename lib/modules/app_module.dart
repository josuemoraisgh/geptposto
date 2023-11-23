import 'package:flutter_modular/flutter_modular.dart';
import '/modules/splash_page.dart';
import 'assistidos/assistidos_module.dart';
import 'colaboradores/colaboradores_module.dart';
import 'config/config_module.dart';
import 'home/home_module.dart';
import 'info/info_module.dart';
import 'login/login_module.dart';
import 'notfound_page.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {}

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
