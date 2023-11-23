import 'package:flutter/material.dart';

import '../models/home_models.dart';

class BuildTagButton extends StatelessWidget {
  final ValueNotifier<List<Map<String, dynamic>>> listaTelas;
  final ValueNotifier<String> activeTagButtom;
  final String tag;
  final Icon icon;
  const BuildTagButton(
      {super.key,
      required this.activeTagButtom,
      required this.tag,
      required this.icon,
      required this.listaTelas});

  @override
  Widget build(BuildContext context) {
    final Color color =
        tag == activeTagButtom.value ? Colors.purple : Colors.black26;
    return SizedBox(
        width: 200,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: color,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icon,
              Text('    $tag'),
            ],
          ),
          onPressed: () {
            activeTagButtom.value = tag;
            listaTelas.value = mapTelas[tag]!;
          },
        ));
  }
}
