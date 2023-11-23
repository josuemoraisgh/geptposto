import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class BuildNavegatorPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueNotifier<bool> state;
  const BuildNavegatorPage({super.key, required this.data, required this.state});

  @override
  Widget build(BuildContext context) {
    final double blur = data['active'] == 1 ? 30 : 0;
    final double offset = data['active'] == 1 ? 20 : 0;
    final double top = state.value ? 0 : (data['active'] == 1 ? 70 : 170);
    final double bottom = state.value ? 0 : 10;
    final double right = state.value ? 0 : 10;

    return ValueListenableBuilder(
        valueListenable: state,
        builder: (BuildContext context, bool value, Widget? child) {
          return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutQuint,
              margin: EdgeInsets.only(
                left: 0.0,
                top: top,
                bottom: bottom,
                right: right,
              ),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage(data['img']),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black87,
                        blurRadius: blur,
                        offset: Offset(offset, offset))
                  ]),
              child: TextButton(
                child: Text(
                  data['title'],
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
                onPressed: () {
                  Modular.to.pushNamed("/assistidos/", arguments: data);
                },
              ));
        });
  }
}
