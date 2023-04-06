import 'package:flutter/material.dart';

class DynamicAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Map<int, Widget> dynamicWidgets;
  final ValueNotifier<int> selectController;
  final String title;

  const DynamicAppBar(
      {Key? key,
      required this.title,
      required this.selectController,
      required this.dynamicWidgets})
      : super(key: key);

  @override
  State<DynamicAppBar> createState() => _DynamicAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DynamicAppBarState extends State<DynamicAppBar> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.selectController,
        child: Container(
          color: Theme.of(context).primaryColor,
        ),
        builder: (context, whatWidget, child) {
          if (widget.dynamicWidgets[whatWidget] != null) {
            return widget.dynamicWidgets[whatWidget]!;
          }
          return Text(widget.title);
        });
  }
}
