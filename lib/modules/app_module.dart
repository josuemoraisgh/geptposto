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
  final List<Module> imports = [];

  @override
  List<Bind<Object>> get binds => [];

  @override
  final List<ModularRoute> routes = [
    ChildRoute('/', child: (context, args) => const SplashPage()),
    ModuleRoute('/home', module: HomeModule()),
    ModuleRoute('/assistidos', module: AssistidosModule()),
    ModuleRoute('/colaboradores', module: ColaboradoresModule()),
    ModuleRoute('/login', module: LoginModule()),
    ModuleRoute('/config', module: ConfigModule()),
    ModuleRoute('/info', module: InfoModule()),
    WildcardRoute(child: (context, args) => const NotFoundPage()),
  ];
}
