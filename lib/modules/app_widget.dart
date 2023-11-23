import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Posto de Assistência',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        //highlightColor: const Color(0xFFD0996F),
        //backgroundColor: const Color(0xFFFDF5EC),
        canvasColor: const Color(0xFFFDF5EC),
        textTheme: TextTheme(
          headlineSmall: ThemeData.light()
              .textTheme
              .headlineSmall!
              .copyWith(color: const Color(0xFFBC764A)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFBC764A),
          foregroundColor: Colors.white,
          actionsIconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateColor.resolveWith(
                (states) => const Color(0xFFBC764A)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateColor.resolveWith(
              (states) => const Color(0xFFBC764A),
            ),
            side: MaterialStateBorderSide.resolveWith(
                (states) => const BorderSide(color: Color(0xFFBC764A))),
          ),
        ),
      ),
      routeInformationParser: Modular.routeInformationParser,
      routerDelegate: Modular.routerDelegate,
    );
  }
}
