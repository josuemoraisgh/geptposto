import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'modules/app_module.dart';
import 'modules/app_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Modular.to.addListener(() {
    debugPrint("main - ${Modular.to.path}");
  });
  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}
