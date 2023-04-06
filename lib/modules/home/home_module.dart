import 'package:flutter_modular/flutter_modular.dart';
import '../styles/my_custom_transition.dart';
import 'home_controller.dart';
import 'home_page.dart';

class HomeModule extends Module {
  @override
  final List<Module> imports = [];

  @override
  List<Bind<Object>> get binds => [
        Bind.singleton<HomeController>((i) => HomeController()),
      ];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(
      Modular.initialRoute,
      child: (_, args) => const HomePage(),
      customTransition: myCustomTransition,
    )
  ];
}
