import 'package:flutter_modular/flutter_modular.dart';
import '../styles/my_custom_transition.dart';
import 'home_controller.dart';
import 'home_page.dart';

class HomeModule extends Module {
  @override
  void binds(Injector i) {
        i.add<HomeController>(HomeController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(
      Modular.initialRoute,
      child: (_) => const HomePage(),
      customTransition: myCustomTransition,
    );
}
}
